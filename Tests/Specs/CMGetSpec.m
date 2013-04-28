//
//  CMGetSpec.m
//  Cumulus
//
//  Created by John Clayton on 9/14/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMGetSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>

@implementation CMGetSpec

@synthesize service;


+ (NSString *)description {
    return @"Get Requests";
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
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

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





@end
