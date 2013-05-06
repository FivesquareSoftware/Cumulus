//
//  CMResourceHTTPMethodsSpec.m
//  Cumulus
//
//  Created by John Clayton on 9/14/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceHTTPMethodsSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>

@implementation CMResourceHTTPMethodsSpec

@synthesize service;


+ (NSString *)description {
    return @"HTTP Methods";
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



#pragma mark - - GET



- (void) shouldGetAnItem {
	CMResource *resource = [self.service resource:@"test/get/item"];
    CMResponse *response = [resource get];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void) shouldGetAList {
	CMResource *resource = [self.service resource:@"test/get/list"];
    CMResponse *response = [resource get];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");	
}

- (void) shouldGetALargeResource {
	CMResource *resource = [self.service resource:@"test/get/large-list"];
    CMResponse *response = [resource get];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.largeList, @"Result did not equal large resource");	
}

- (void) shouldGetAComplicatedResource {
	CMResource *resource = [self.service resource:@"test/get/complicated-list"];
    CMResponse *response = [resource get];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.complicatedList, @"Result did not equal complicated resource");	
}




#pragma mark - - HEAD


- (void)shouldHeadItem {
	CMResource *resource = [self.service resource:@"test/head/item"];
    CMResponse *response = [resource head];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertNil(response.result, @"Head request should have no body");
}

- (void)shouldHeadList {
	CMResource *resource = [self.service resource:@"test/head/list"];
    CMResponse *response = [resource head];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertNil(response.result, @"Head request should have no body");
}



#pragma mark - - DELETE


- (void)shouldDeleteItem {
	CMResource *resource = [self.service resource:@"test/delete/item"];
    CMResponse *response = [resource delete];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void)shouldDeleteList {
	CMResource *resource = [self.service resource:@"test/delete/list"];
    CMResponse *response = [resource delete];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");
}



#pragma mark - - POST

- (void) shouldPostItem {
	CMResource *resource = [self.service resource:@"test/post/item"];
    CMResponse *response = [resource post:self.specHelper.item];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void) shouldPostList {
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.specHelper.list forKey:@"list"];  // our service likes hashes not arrays as the payload
	CMResource *resource = [self.service resource:@"test/post/list"];
    CMResponse *response = [resource post:payload];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");
}

- (void) shouldPostLargeResource {
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.specHelper.largeList forKey:@"list"];  // our service likes hashes not arrays as the payload
	CMResource *resource = [self.service resource:@"test/post/large-list"];
    CMResponse *response = [resource post:payload];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.largeList, @"Result did not equal large resource");
}

- (void) shouldPostComplicatedResource {
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.specHelper.complicatedList forKey:@"list"];  // our service likes hashes not arrays as the payload
	CMResource *resource = [self.service resource:@"test/post/complicated-list"];
    CMResponse *response = [resource post:payload];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.complicatedList, @"Result did not equal complicated resource");
}



#pragma mark - - PUT

- (void) shouldPutItem {
	CMResource *resource = [self.service resource:@"test/put/item"];
    CMResponse *response = [resource put:self.specHelper.item];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void) shouldPutList {
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.specHelper.list forKey:@"list"];  // our service likes hashes not arrays as the payload
	CMResource *resource = [self.service resource:@"test/put/list"];
    CMResponse *response = [resource put:payload];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");
}


@end
