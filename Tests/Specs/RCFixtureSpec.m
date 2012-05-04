//
//  RCFixtureSpec.m
//  RESTClient
//
//  Created by John Clayton on 5/3/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCFixtureSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCFixtureSpec

@synthesize service;


+ (NSString *)description {
    return @"Fixtures";
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


- (void) shouldGetAStringFixture {
	RCResource *resource = [self.service resource:@"test/get/item"];
	resource.contentType = RESTClientContentTypeText;
	resource.fixture = @"FOO";
    RCResponse *response = [resource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, @"FOO", @"Result did not equal item");
}

- (void) shouldGetAnItemFixture {
	RCResource *resource = [self.service resource:@"test/get/item"];
	resource.contentType = RESTClientContentTypeJSON;
	resource.fixture = self.specHelper.item;
    RCResponse *response = [resource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void) shouldGetAListFixture {
	RCResource *resource = [self.service resource:@"test/get/list"];
	resource.contentType = RESTClientContentTypeJSON;
	resource.fixture = self.specHelper.list;
    RCResponse *response = [resource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");	
}



@end
