//
//  RCResourceGroupSpec.m
//  RESTClient
//
//  Created by John Clayton on 8/28/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCResourceGroupSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCResourceGroupSpec

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


- (void) shouldAddResourceBySettingGroup {
	RCResource *index = [self.service resource:@"index"];
	RCResourceGroup *group = [RCResourceGroup withCompletionBlock:nil];
//	[group addResource:index];
	index.resourceGroup = group;
	STAssertEqualObjects([NSSet setWithObject:index], [group resources], @"Setting a resource's group should add it to group");
}

- (void) shouldAddResource {
	RCResource *index = [self.service resource:@"index"];
	RCResourceGroup *group = [RCResourceGroup withCompletionBlock:nil];
	[group addResource:index];
	STAssertEqualObjects([NSSet setWithObject:index], [group resources], @"Adding a resource should add it to group resources");
}

- (void)shouldRunCompletionBlockWhenGroupResourcesComplete {
	
	dispatch_semaphore_t group_sema = dispatch_semaphore_create(1);
	size_t totalBlocks = 25;
	
	__block BOOL touched = NO;
	__block size_t completedBlocksCount = 0;

	RCResource *index = [self.service resource:@"index"];
	RCResourceGroup *group = [RCResourceGroup withCompletionBlock:^{
		if (completedBlocksCount == totalBlocks) {
			touched = YES;
		}
		dispatch_semaphore_signal(group_sema);
	}];
	[group addResource:index];

	dispatch_semaphore_wait(group_sema, DISPATCH_TIME_FOREVER);
	
	dispatch_apply(totalBlocks, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t i) {
		[index getWithCompletionBlock:^(RCResponse *response){
			completedBlocksCount++;
		}];
	});
	
	[group markAfterDelay:.1]; // We get here so fast sometimes the requests haven't even had chance to launch yet

	dispatch_semaphore_wait(group_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(group_sema);
	dispatch_release(group_sema);
	
    STAssertEquals(completedBlocksCount, totalBlocks, @"All blocks should have run before the completion block");
    STAssertTrue(touched, @"Should have run group completion block");
}

- (void) shouldRemoveNotRemoveCompletionBlocksWhenSetToNO {
	dispatch_semaphore_t group_sema = dispatch_semaphore_create(1);
	size_t totalBlocks = 25;
	
	RCResource *index = [self.service resource:@"index"];
	RCResourceGroup *group = [RCResourceGroup withCompletionBlock:^{
		dispatch_semaphore_signal(group_sema);
	}];
	group.clearsBlocksOnCompletion = YES;
	[group addResource:index];
	
	dispatch_semaphore_wait(group_sema, DISPATCH_TIME_FOREVER);
	
	dispatch_apply(totalBlocks, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^(size_t i) {
		[index getWithCompletionBlock:nil];
	});
	
	[group markAfterDelay:.1]; // We get here so fast sometimes the requests haven't even had chance to launch yet
	
	dispatch_semaphore_wait(group_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(group_sema);
	dispatch_release(group_sema);
	
	int count = (int)[group.completionBlocks count];
	STAssertEquals(0, count, @"Completion blocks should have been removed");
}







@end
