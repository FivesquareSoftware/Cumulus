//
//  RCPutSpec.m
//  RESTClient
//
//  Created by John Clayton on 10/8/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCPutSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCPutSpec

@synthesize service;

+ (NSString *)description {
    return @"PUT requests";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 

	self.service = [RCResource withURL:kTestServerHost];
	self.service.contentType = RESTClientContentTypeJSON;
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

- (void) shouldPutItem {
	RCResource *resource = [self.service resource:@"test/put/item"];
    RCResponse *response = [resource put:self.specHelper.item];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void) shouldPutList {
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.specHelper.list forKey:@"list"];  // our service likes hashes not arrays as the payload
	RCResource *resource = [self.service resource:@"test/put/list"];
    RCResponse *response = [resource put:payload];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");	
}



@end
