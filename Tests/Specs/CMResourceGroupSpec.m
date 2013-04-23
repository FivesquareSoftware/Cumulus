//
//  CMResourceGroupSpec.m
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceGroupSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMResourceGroupSpec

+ (NSString *)description {
    return @"Resource groups";
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



- (void) shouldPerformSomeWorkAndRunCompletionBlock {
	CMResourceGroup *group = [CMResourceGroup withName:@"test Group"];
	
	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	__block BOOL localSuccess = NO;
	__block NSArray *localResponses = nil;
	__block BOOL completionBlockRan = NO;

	[group performWork:^(CMResourceGroup *group) {
		CMResource *index = [self.service resource:@"index"];
		[index get];
		
		CMResource *item = [self.service resource:@"test/get/item"];
		[item getWithCompletionBlock:^(CMResponse *response) {
			completionBlockRan = YES;
		}];
		
	} withCompletionBlock:^(BOOL success, NSArray *responses) {
		localSuccess = success;
		localResponses = responses;
		dispatch_semaphore_signal(group_semaphore);
	}];

	dispatch_semaphore_wait(group_semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(group_semaphore);

	STAssertTrue(localSuccess, @"Group should have succeeded");
	STAssertTrue(localResponses.count == 2, @"Group should have passed along contained responses: %@",localResponses);
	STAssertTrue(completionBlockRan, @"Completion block of asynchronous get should have run");
}





@end
