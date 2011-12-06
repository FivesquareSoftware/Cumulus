//
//  RCDeleteSpec.m
//  RESTClient
//
//  Created by John Clayton on 11/28/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCDeleteSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCDeleteSpec

@synthesize service;

+ (NSString *)description {
    return @"Delete Requests";
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

- (void)shouldDeleteItem {
	RCResource *resource = [self.service resource:@"test/delete/item"];
    RCResponse *response = [resource delete];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void)shouldDeleteList {
	RCResource *resource = [self.service resource:@"test/delete/list"];
    RCResponse *response = [resource delete];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");	
}




@end
