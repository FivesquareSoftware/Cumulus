//
//  RCClientCertificateAuthProvider.m
//  RESTClient
//
//  Created by John Clayton on 12/19/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCClientCertificateAuthProvider.h"

@implementation RCClientCertificateAuthProvider


// ========================================================================== //

#pragma mark - RCAuthProvider

- (NSString *) providedAuthenticationMethod {
	return NSURLAuthenticationMethodClientCertificate;
}

- (void) authorizeRequest:(NSMutableURLRequest *)URLRequest {
	// TODO
}

- (NSURLCredential *) credentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	//TODO
	return nil;
}

@end
