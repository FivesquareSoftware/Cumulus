//
//  CMPostSpec.m
//  Cumulus
//
//  Created by John Clayton on 9/16/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMPostSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMPostSpec

@synthesize service;

+ (NSString *)description {
    return @"POST Requests";
}

// ========================================================================== //

#pragma mark -  Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
	
	self.service = [CMResource withURL:kTestServerHost];
	self.service.contentType = CMContentTypeJSON;
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

- (void) shouldPostItem {
	CMResource *resource = [self.service resource:@"test/post/item"];
    CMResponse *response = [resource post:self.specHelper.item];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void) shouldPostList {
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.specHelper.list forKey:@"list"];  // our service likes hashes not arrays as the payload
	CMResource *resource = [self.service resource:@"test/post/list"];
    CMResponse *response = [resource post:payload];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");	
}

- (void) shouldPostLargeResource {
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.specHelper.largeList forKey:@"list"];  // our service likes hashes not arrays as the payload
	CMResource *resource = [self.service resource:@"test/post/large-list"];
    CMResponse *response = [resource post:payload];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.largeList, @"Result did not equal large resource");	
}

- (void) shouldPostComplicatedResource {
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.specHelper.complicatedList forKey:@"list"];  // our service likes hashes not arrays as the payload
	CMResource *resource = [self.service resource:@"test/post/complicated-list"];
    CMResponse *response = [resource post:payload];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.complicatedList, @"Result did not equal complicated resource");	
}


@end
