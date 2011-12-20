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

@synthesize insecure=insecure_;


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
