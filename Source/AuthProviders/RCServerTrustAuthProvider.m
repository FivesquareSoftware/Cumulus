//
//  RCServerTrustAuthProvider.m
//  RESTClient
//
//  Created by John Clayton on 12/13/11.
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

#import "RCServerTrustAuthProvider.h"

#import "RESTClient.h"
#import <Security/Security.h>


@implementation RCServerTrustAuthProvider


// ========================================================================== //

#pragma mark - Properties


@synthesize insecure=_insecure;
@synthesize certificates=_certificates;


// ========================================================================== //

#pragma mark - Object


- (id)init {
    self = [super init];
    if (self) {
        _certificates = [NSMutableArray new];
    }
    return self;
}

// ========================================================================== //

#pragma mark - Public Interface



- (void) addCertificate:(id)certificate {
	SecCertificateRef certRef = (__bridge SecCertificateRef)certificate;
	NSAssert(CFGetTypeID(certRef) == SecCertificateGetTypeID(), @"Type of certificate was not SecCertificateRef");
	[self.certificates addObject:certificate];
}


// ========================================================================== //

#pragma mark - RCAuthProvider

- (NSString *) providedAuthenticationMethod {
	return NSURLAuthenticationMethodServerTrust;
}

- (void) authorizeRequest:(NSMutableURLRequest *)URLRequest {
	// bupkus
}

- (NSURLCredential *) credentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	NSURLProtectionSpace *protectionSpace = [challenge protectionSpace];
	SecTrustRef serverTrust = protectionSpace.serverTrust;
	
	NSURLCredential *credential = nil;
	if (self.insecure) {
		RCLog(@" *** WARNING **** : Accepting potentially insecure trust!");
		credential = [NSURLCredential credentialForTrust:serverTrust];
	} else {
		if (self.certificates.count > 0) {
			SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)self.certificates);
		}
		SecTrustResultType result;
		OSStatus returnCode = SecTrustEvaluate(serverTrust, &result);
		if (returnCode == errSecSuccess && (result == kSecTrustResultProceed || result == kSecTrustResultConfirm || result == kSecTrustResultUnspecified) ) {
			credential = [NSURLCredential credentialForTrust:serverTrust];
		} else {
			RCLog(@"SecTrustEvaluate failed: %ld",returnCode);
		}
	}
	return credential;
}


@end
