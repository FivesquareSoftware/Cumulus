//
//  RCBasicAuthProvider.m
//  RESTClient
//
//  Created by John Clayton on 8/27/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
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
 * 3. Neither the name of Fivesquare Software nor the names of its contributors may
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

#import "RCBasicAuthProvider.h"

#import "RESTClient.h"
#import "NSData+Base64.h"

@interface RCBasicAuthProvider()
- (void) addAuthHeader:(NSMutableURLRequest *)urlRequest;
- (NSString *) encodedCredentials;
@end

@implementation RCBasicAuthProvider

// ========================================================================== //

#pragma mark - Properties



@synthesize username=_username;
@synthesize password=_password;


// ========================================================================== //

#pragma mark - Object

- (BOOL) isEqual:(id)object {
	if (NO == [object isKindOfClass:[self class]]) {
		return NO;
	}
	RCBasicAuthProvider *other = (RCBasicAuthProvider *)object;
	return [self.username isEqualToString:other.username] && [self.password isEqualToString:other.password];
}

+ (id) withUsername:(NSString *)username password:(NSString *)password {
    RCBasicAuthProvider *provider = [self new];
    provider.username = username;
    provider.password = password;
    return provider;
}


// ========================================================================== //

#pragma mark - RCAuthProvider

- (NSString *) providedAuthenticationMethod {
	return NSURLAuthenticationMethodHTTPBasic;
}

- (void) authorizeRequest:(NSMutableURLRequest *)urlRequest {
	[self addAuthHeader:urlRequest];
}

- (NSURLCredential *) credentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	return [NSURLCredential credentialWithUser:self.username password:self.password persistence:NSURLCredentialPersistenceNone];
}


// ========================================================================== //

#pragma mark - Helpers



- (void) addAuthHeader:(NSMutableURLRequest *)urlRequest {
	NSString *encodedCredentials = [self encodedCredentials];
	if(encodedCredentials) {
		[urlRequest setValue:encodedCredentials forHTTPHeaderField:kRESTClientHTTPHeaderAuthorization];
	}
}

- (NSString *) encodedCredentials {
	NSString *encoded = nil;
	if(self.username && [self.username length] > 0
	   && self.password && [self.password length] > 0) {
		NSString *string = [NSString stringWithFormat:@"%@:%@",self.username,self.password];
		NSData *stringData = [string dataUsingEncoding:NSUTF8StringEncoding];
		NSString *base64String = [stringData base64EncodedStringWithLineBreaks:NO];
		encoded = [NSString stringWithFormat:@"Basic %@",base64String];
	}
	return encoded;
}

@end
