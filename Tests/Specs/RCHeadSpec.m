//
//  RCHeadSpec.m
//  RESTClient
//
//  Created by John Clayton on 11/28/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCHeadSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCHeadSpec

@synthesize service;

+ (NSString *)description {
    return @"Head Requests";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
	self.service = [RCResource withURL:kTestServerHost];
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

- (void)shouldHeadItem {
	RCResource *resource = [self.service resource:@"test/head/item"];
    RCResponse *response = [resource head];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
	STAssertNil(response.result, @"Head request should have no body");
}

- (void)shouldHeadList {
	RCResource *resource = [self.service resource:@"test/head/list"];
    RCResponse *response = [resource head];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
	STAssertNil(response.result, @"Head request should have no body");
}




@end
