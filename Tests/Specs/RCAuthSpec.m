//
//  RCAuthSpec.m
//  RESTClient
//
//  Created by John Clayton on 9/9/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCAuthSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>
#import "OCMock.h"

#import <Security/Security.h>

@implementation RCAuthSpec

@synthesize service;
@synthesize SSLService;
@synthesize protectedResource;
@synthesize SSLProtectedResource;

+ (NSString *)description {
    return @"BASIC Auth Handling";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
    self.service = [RCResource withURL:kTestServerHost];
    self.service.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	self.protectedResource = [self.service resource:@"test/protected"];

	
    self.SSLService = [RCResource withURL:kTestServerHostSSL];
	self.SSLService.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    self.SSLProtectedResource = [self.SSLService resource:@"test/protected"];
	
	
	NSURLCredentialStorage *storage = [NSURLCredentialStorage sharedCredentialStorage];
	NSDictionary *credentials = [[storage allCredentials] copy];
	for (NSURLProtectionSpace *protectionSpace in credentials) {
		NSDictionary *credentialsForSpace = [storage credentialsForProtectionSpace:protectionSpace];
		for (NSString *username in credentialsForSpace) {
			NSURLCredential *credential = [credentialsForSpace objectForKey:username];
			[storage removeCredential:credential forProtectionSpace:protectionSpace];
		}
	}	
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

- (void) shouldBeUnauthorized {
	RCResponse *response = [self.protectedResource get];
    STAssertTrue([response HTTPUnauthorized], @"Response should be unauthorized: %@",response); 
}

- (void) shouldFailAuthorizationWithBadCredentials {
    RCBasicAuthProvider *authProvider = [RCBasicAuthProvider withUsername:@"foo" password:@"bar"];
    [self.service addAuthProvider:authProvider];
	RCResponse *response = [self.protectedResource get];
	STAssertTrue([response HTTPUnauthorized], @"Response should be unauthorized: %@",response); 
}

- (void) shouldBeAuthorized {
    RCBasicAuthProvider *authProvider = [RCBasicAuthProvider withUsername:@"test" password:@"test"];
    [self.service addAuthProvider:authProvider];
	RCResponse *response = [self.protectedResource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void) shouldBeAuthorizedWithAReallyLongUsernameAndPassword {
    RCBasicAuthProvider *authProvider = [RCBasicAuthProvider withUsername:@"bb43c2d91e0fdaa616d2a8c29b86732c09e518b08be80ecafd54b1c351e9688cb78e1f39c8d3936050cbe9e0184c7b745d372fc6f1e7b8e09c6581e0146ca2c1" password:@"bb43c2d91e0fdaa616d2a8c29b86732c09e518b08be80ecafd54b1c351e9688cb78e1f39c8d3936050cbe9e0184c7b745d372fc6f1e7b8e09c6581e0146ca2c1"];
    [self.service addAuthProvider:authProvider];
	RCResponse *response = [self.protectedResource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void) shouldContinueWhenProviderReturnsNilCredential {
	OCMockObject<RCAuthProvider> *mockAuthProvider = [OCMockObject mockForProtocol:@protocol(RCAuthProvider)];
	[[mockAuthProvider stub] authorizeRequest:[OCMArg any]];
	[[[mockAuthProvider stub] andReturn:NSURLAuthenticationMethodHTTPBasic]  providedAuthenticationMethod];
	[[[mockAuthProvider expect] andReturn:nil] credentialForAuthenticationChallenge:[OCMArg any]];
	
	[self.protectedResource addAuthProvider:mockAuthProvider];
	RCResponse *response = [self.protectedResource get];
	STAssertTrue([response HTTPUnauthorized], @"Response should be unauthorized: %@",response); 
	
	[mockAuthProvider verify];
}

- (void) shouldRetryAuthMaxAuthRetryTimes {
    RCBasicAuthProvider *authProvider = [RCBasicAuthProvider withUsername:@"foo" password:@"bar"];

	OCMockObject<RCAuthProvider> *mockAuthProvider = [OCMockObject mockForProtocol:@protocol(RCAuthProvider)];
	
	[[mockAuthProvider stub] authorizeRequest:[OCMArg any]];
	[[[mockAuthProvider stub] andReturn:NSURLAuthenticationMethodHTTPBasic]  providedAuthenticationMethod];
	[[[mockAuthProvider expect] andReturn:[authProvider credentialForAuthenticationChallenge:[OCMArg any]]] credentialForAuthenticationChallenge:[OCMArg any]];
	[[[mockAuthProvider expect] andReturn:[authProvider credentialForAuthenticationChallenge:[OCMArg any]]] credentialForAuthenticationChallenge:[OCMArg any]];
	
    [self.service addAuthProvider:mockAuthProvider];
	RCResponse *response = [self.protectedResource get];
	STAssertTrue([response HTTPUnauthorized], @"Response should be unauthorized: %@",response); 
	
	[mockAuthProvider verify];
}


- (void) shouldRejectSelfSignedCertWhenSecure {
	RCServerTrustAuthProvider *authProvider = [RCServerTrustAuthProvider new];
	[self.SSLService addAuthProvider:authProvider];
	RCResource *untrustedServer = [self.SSLService resource:@"index"];
	RCResponse *response = [untrustedServer get];
	STAssertTrue([response ErrorUserCancelledAuthentication], @"Response should be untrusted certificate: %@",response); 
}

- (void) shouldAcceptSelfSignedCertWhenInsecure {
	RCServerTrustAuthProvider *authProvider = [RCServerTrustAuthProvider new];
	authProvider.insecure = YES;
	[self.SSLService addAuthProvider:authProvider];
	RCResource *untrustedServer = [self.SSLService resource:@"index"];
	RCResponse *response = [untrustedServer get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

@end
