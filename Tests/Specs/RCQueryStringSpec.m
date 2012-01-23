//
//  RCQueryStringSpec.m
//  RESTClient
//
//  Created by John Clayton on 1/5/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCQueryStringSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCQueryStringSpec

@synthesize service;

+ (NSString *)description {
    return @"Query String Handling";
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

- (void) shouldAppendQueryStringValuesAndKeys {
	RCResource *resource = [self.service resource:@"test/query"];
	RCResponse *response = [resource getWithQuery:@"bar",@"foo",nil];
	STAssertTrue(response.success, @"Response should succeed");
	NSDictionary *params = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	STAssertEqualObjects(params, response.result, @"Result should equal sent params:%@",response.result);
}

- (void) shouldAppendArrayAsCollectionToQueryString {
	RCResource *resource = [self.service resource:@"test/query"];
	NSArray *arrayParam = [NSArray arrayWithObjects:@"1", @"2", nil];
	RCResponse *response = [resource getWithQuery:arrayParam,@"foo",nil];
	STAssertTrue(response.success, @"Response should succeed");
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:arrayParam, @"foo", nil];
	STAssertEqualObjects(params, response.result, @"Result should equal sent params:%@",response.result);
}

- (void) shouldAppendDictionaryAsQueryString {
	RCResource *resource = [self.service resource:@"test/query"];
	NSDictionary *params = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	RCResponse *response = [resource getWithQuery:params];
	STAssertTrue(response.success, @"Response should succeed");
	STAssertEqualObjects(params, response.result, @"Result should equal sent params:%@",response.result);
}


- (void) shouldGetWithQueryString {
	STAssertTrue(NO, @"Unimplemented");
}

- (void) shouldHeadWithQueryString {
	STAssertTrue(NO, @"Unimplemented");
}

- (void) shouldDeleteWithQueryString {
	STAssertTrue(NO, @"Unimplemented");
}

- (void) shouldPostWithQueryString {
	STAssertTrue(NO, @"Unimplemented");
}

- (void) shouldPutWithQueryString {
	STAssertTrue(NO, @"Unimplemented");
}


@end
