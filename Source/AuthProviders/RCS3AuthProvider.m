//
//  RCS3AuthProvider.m
//  RESTClient
//
//  Created by John Clayton on 8/16/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

/*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 *
 * 3. Neither the name of Fivesquare Software, LLC nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */



#import "RCS3AuthProvider.h"

#import "RCAmazonCredentials.h"
#import "RESTClient.h"
#import "NSData+Base64.h"


#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <CommonCrypto/CommonCryptor.h>


@interface NSURLRequest (RSS3AuthProvider)
- (NSString *) canonicalName;
@end

@implementation NSURLRequest (RSS3AuthProvider)
- (NSString *) canonicalName {
	return [[self URL] path];
}
@end

@interface RCS3AuthProvider ()
@property (nonatomic, strong) NSDateFormatter *amazonDateFormatter;
@end

@implementation RCS3AuthProvider


- (NSDateFormatter *) amazonDateFormatter {
	if (nil == _amazonDateFormatter) {
		_amazonDateFormatter = [[NSDateFormatter alloc] init];
		[_amazonDateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"GMT"]];
		[_amazonDateFormatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
		[_amazonDateFormatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US"]];
	}
	return _amazonDateFormatter;
}


// ========================================================================== //

#pragma mark - Object




- (id)initWithCredentials:(id<RCAmazonCredentials>)credentials {
    self = [super init];
    if (self) {
        _credentials = credentials;
    }
    return self;
}

- (id)initWithCredentialsProvider:(RCResource *)credentialsProvider {
    self = [super init];
    if (self) {
        _credentialsProvider = credentialsProvider;
    }
    return self;
}


// ========================================================================== //

#pragma mark - RCAuthProvider

- (NSString *) providedAuthenticationMethod {
	return nil; // I dunno, basic?
}

- (void) authorizeRequest:(NSMutableURLRequest *)URLRequest {
	if (_credentialsProvider && (nil == _credentials || NO == _credentials.valid)) {
		dispatch_semaphore_t credentialsSemaphore = dispatch_semaphore_create(1);
		dispatch_semaphore_wait(credentialsSemaphore, DISPATCH_TIME_FOREVER);
		[_credentialsProvider getWithCompletionBlock:^(RCResponse *response) {
			self.credentials = (id<RCAmazonCredentials>)response.result;//The service provider must have a postProcessing block that makes response#result a credentials object
			[self signRequest:URLRequest];
			dispatch_semaphore_signal(credentialsSemaphore);
		}];

		dispatch_semaphore_wait(credentialsSemaphore, DISPATCH_TIME_FOREVER);
		dispatch_semaphore_signal(credentialsSemaphore);
		dispatch_release(credentialsSemaphore);
	} else {
		[self signRequest:URLRequest];
	}
}

- (NSURLCredential *) credentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	return nil;
	// wondering, could we build a credential that would properly set the Authorization header?
}


// ========================================================================== //

#pragma mark - Auth


- (void) signRequest:(NSMutableURLRequest *)URLRequest {
    NSString *contentType = [URLRequest valueForHTTPHeaderField:@"Content-Type"];
    NSString *amazonDate = [URLRequest valueForHTTPHeaderField:@"Date"];
	
	if (nil == contentType) {
		contentType = @"";
	}
	if (nil == amazonDate) {
		amazonDate = [self.amazonDateFormatter stringFromDate:[NSDate date]];
	}
	
	// add @"x-amz-security-token" header if we have one
    NSString *securityToken = [NSString stringWithFormat:@"x-amz-security-token:%@", self.credentials.securityToken];
	
	// build canonical string
	NSString *stringToSign = [NSString stringWithFormat:@"%@\n\n%@\n%@\n%@\n%@",[URLRequest HTTPMethod], contentType, amazonDate, securityToken, [URLRequest canonicalName]];

	// sign it
	
    NSString *signature = signature = [self HMACSign:[stringToSign dataUsingEncoding:NSUTF8StringEncoding] withKey:_credentials.secretKey usingAlgorithm:kCCHmacAlgSHA1];
	
	// Set it to the Auth header
	if (signature && signature.length) {
		NSString *authHeader = [NSString stringWithFormat:@"AWS %@:%@", self.credentials.accessKey, signature];
        [URLRequest setValue:authHeader forHTTPHeaderField:kRESTClientHTTPHeaderAuthorization];
        [URLRequest setValue:self.credentials.securityToken forHTTPHeaderField:@"x-amz-security-token"];
        [URLRequest setValue:amazonDate forHTTPHeaderField:@"Date"];
	}
	
}

- (NSString *) HMACSign:(NSData *)data withKey:(NSString *)key usingAlgorithm:(CCHmacAlgorithm)algorithm {
    CCHmacContext context;
	NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
	
    CCHmacInit(&context, algorithm, keyData.bytes, keyData.length);
    CCHmacUpdate(&context, [data bytes], [data length]);
	
    // Both SHA1 and SHA256 will fit in here
    unsigned char digestRaw[CC_SHA256_DIGEST_LENGTH];
	
    NSInteger digestLength;
	
    switch (algorithm) {
		case kCCHmacAlgSHA1:
			digestLength = CC_SHA1_DIGEST_LENGTH;
			break;
			
		case kCCHmacAlgSHA256:
			digestLength = CC_SHA256_DIGEST_LENGTH;
			break;
			
		default:
			digestLength = -1;
			break;
    }
	
    if (digestLength < 0) {
		RCLog(@"Invalid hash algorithm: %d",algorithm);
		return nil;
    }
	
    CCHmacFinal(&context, digestRaw);
	
    NSData *digestData = [NSData dataWithBytes:digestRaw length:digestLength];
	NSString *base64String = [digestData base64EncodedStringWithLineBreaks:NO];

    return base64String;
}


@end
