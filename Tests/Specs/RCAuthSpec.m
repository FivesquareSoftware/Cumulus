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


@implementation RCAuthSpec

@synthesize service;
@synthesize protectedResource;

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
    self.protectedResource = [self.service resource:@"test/protected"];
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
    STAssertTrue([response isUnauthorized], @"Response should be unauthorized: %@",response); 
}

- (void) shouldFailAuthorizationWithBadCredentials {
    RCBasicAuthProvider *authProvider = [RCBasicAuthProvider withUsername:@"foo" password:@"bar"];
    [self.service setAuthProvider:authProvider];
	RCResponse *response = [self.protectedResource get];
	STAssertTrue([response isUnauthorized], @"Response should be unauthorized: %@",response); 
}

- (void) shouldBeAuthorized {
    RCBasicAuthProvider *authProvider = [RCBasicAuthProvider withUsername:@"test" password:@"test"];
    [self.service setAuthProvider:authProvider];
	RCResponse *response = [self.protectedResource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}



@end
