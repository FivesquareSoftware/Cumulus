//
//  CMDeleteSpec.m
//  Cumulus
//
//  Created by John Clayton on 11/28/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMDeleteSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMDeleteSpec

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




@end
