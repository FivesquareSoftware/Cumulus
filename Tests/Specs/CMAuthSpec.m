//
//	CMAuthSpec.m
//	Cumulus
//
//	Created by John Clayton on 9/9/11.
//	Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMAuthSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


@import Nimble;
#import "OCMock.h"

#import <Security/Security.h>

@implementation CMAuthSpec


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
	self.service = [CMResource withURL:kTestServerHost];
	self.service.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	self.protectedResource = [self.service resource:@"test/protected"];
	
	
	self.SSLService = [CMResource withURL:kTestServerHostSSL];
	self.SSLService.cachePolicy = NSURLRequestReloadIgnoringCacheData;
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
	CMResponse *response = [self.protectedResource get];
	expect([response HTTPUnauthorized]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should be unauthorized: %@",response]);
}

- (void) shouldFailAuthorizationWithBadCredentials {
	CMBasicAuthProvider *authProvider = [CMBasicAuthProvider withUsername:@"foo" password:@"bar"];
	[self.service addAuthProvider:authProvider];
	CMResponse *response = [self.protectedResource get];
	expect([response HTTPUnauthorized]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should be unauthorized: %@",response]);
}

- (void) shouldBeAuthorized {
	CMBasicAuthProvider *authProvider = [CMBasicAuthProvider withUsername:@"test" password:@"test"];
	[self.service addAuthProvider:authProvider];
	CMResponse *response = [self.protectedResource get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",response]);
}

- (void) shouldBeAuthorizedWithAReallyLongUsernameAndPassword {
	CMBasicAuthProvider *authProvider = [CMBasicAuthProvider withUsername:@"bb43c2d91e0fdaa616d2a8c29b86732c09e518b08be80ecafd54b1c351e9688cb78e1f39c8d3936050cbe9e0184c7b745d372fc6f1e7b8e09c6581e0146ca2c1" password:@"bb43c2d91e0fdaa616d2a8c29b86732c09e518b08be80ecafd54b1c351e9688cb78e1f39c8d3936050cbe9e0184c7b745d372fc6f1e7b8e09c6581e0146ca2c1"];
	[self.service addAuthProvider:authProvider];
	CMResponse *response = [self.protectedResource get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",response]);
}

- (void) shouldContinueWhenProviderReturnsNilCredential {
	OCMockObject<CMAuthProvider> *mockAuthProvider = [OCMockObject mockForProtocol:@protocol(CMAuthProvider)];
	[[mockAuthProvider stub] authorizeRequest:[OCMArg any]];
	[[[mockAuthProvider stub] andReturn:NSURLAuthenticationMethodHTTPBasic]	 providedAuthenticationMethod];
	[[[mockAuthProvider expect] andReturn:nil] credentialForAuthenticationChallenge:[OCMArg any]];
	
	[self.protectedResource addAuthProvider:mockAuthProvider];
	CMResponse *response = [self.protectedResource get];
	expect([response HTTPUnauthorized]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should be unauthorized: %@",response]);
	
	[mockAuthProvider verify];
}

- (void) shouldRetryAuthMaxAuthRetryTimes {
	CMBasicAuthProvider *authProvider = [CMBasicAuthProvider withUsername:@"foo" password:@"bar"];
	
	OCMockObject<CMAuthProvider> *mockAuthProvider = [OCMockObject mockForProtocol:@protocol(CMAuthProvider)];
	
	[[mockAuthProvider stub] authorizeRequest:[OCMArg any]];
	[[[mockAuthProvider stub] andReturn:NSURLAuthenticationMethodHTTPBasic]	 providedAuthenticationMethod];
	[[[mockAuthProvider expect] andReturn:[authProvider credentialForAuthenticationChallenge:[OCMArg any]]] credentialForAuthenticationChallenge:[OCMArg any]];
	[[[mockAuthProvider expect] andReturn:[authProvider credentialForAuthenticationChallenge:[OCMArg any]]] credentialForAuthenticationChallenge:[OCMArg any]];
	
	[self.service addAuthProvider:mockAuthProvider];
	CMResponse *response = [self.protectedResource get];
	expect([response HTTPUnauthorized]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should be unauthorized: %@",response]);
	
	[mockAuthProvider verify];
}

- (void) shouldRejectSelfSignedCertWhenSecure {
	CMServerTrustAuthProvider *authProvider = [CMServerTrustAuthProvider new];
	[self.SSLService addAuthProvider:authProvider];
	CMResource *untrustedServer = [self.SSLService resource:@"index"];
	CMResponse *response = [untrustedServer get];
	expect([response ErrorUserCancelledAuthentication]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should be untrusted certificate: %@",response]);
}

- (void) shouldAcceptSelfSignedCertWhenInsecure {
	CMServerTrustAuthProvider *authProvider = [CMServerTrustAuthProvider new];
	authProvider.insecure = YES;
	[self.SSLService addAuthProvider:authProvider];
	CMResource *untrustedServer = [self.SSLService resource:@"index"];
	CMResponse *response = [untrustedServer get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",response]);
}

@end
