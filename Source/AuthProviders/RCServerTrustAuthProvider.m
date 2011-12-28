//
//  RCServerTrustAuthProvider.m
//  RESTClient
//
//  Created by John Clayton on 12/13/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCServerTrustAuthProvider.h"

#import "RESTClient.h"
#import <Security/Security.h>


@implementation RCServerTrustAuthProvider


// ========================================================================== //

#pragma mark - Properties


@synthesize insecure=insecure_;
@synthesize certificates=certificates_;


// ========================================================================== //

#pragma mark - Object


- (id)init {
    self = [super init];
    if (self) {
        certificates_ = [NSMutableArray new];
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
