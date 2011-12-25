//
//  RCResourceControlSpec.m
//  RESTClient
//
//  Created by John Clayton on 12/3/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCResourceControlSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCResourceControlSpec

@synthesize service;

+ (NSString *)description {
    return @"Resource Control";
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

//- (void)shouldCancelAllRequests {
//	RCResource *smallResource = [self.service resource:@"slow"];
//	smallResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
//	
//	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//	dispatch_apply(1000, queue, ^(size_t i) {
//		[smallResource getWithCompletionBlock:nil];
//	});
//	
//	NSMutableSet *requests = smallResource.requests; // the ones that are still running at the moment
//	
//	dispatch_semaphore_t cancel_sema = dispatch_semaphore_create(1);
//	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
//	[smallResource cancelRequestsWithBlock:^{
//		dispatch_semaphore_signal(cancel_sema);
//	}];
//	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
//	dispatch_semaphore_signal(cancel_sema);
//	dispatch_release(cancel_sema);
//	
//	for (RCRequest *request in requests) {
//		STAssertTrue(request.wasCanceled, @"wasCanceled should be YES");
//		STAssertNil(request.URLResponse, @"URLResponse should be nil");
//	}
//}

//- (void) shouldProperlyRunFromTheMainQueue {
//	RCResource *index = [self.service resource:@"index"];
//	
//	__block RCResponse *localResponse = nil;
//	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
//	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
//
//	dispatch_async(dispatch_get_main_queue(), ^{
//		[index getWithCompletionBlock:^(RCResponse *response) {
//			localResponse = response;
//			dispatch_semaphore_signal(request_sema);
//		}];
//	});
//	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
//	dispatch_semaphore_signal(request_sema);
//	dispatch_release(request_sema);
//	STAssertTrue(localResponse.success, @"Response should be successful: %@", localResponse);
//}
//
//- (void) shouldProperlyRunFromConcurrentQueue {
//	RCResource *index = [self.service resource:@"index"];
//	
//	__block RCResponse *localResponse = nil;
//	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//
//	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
//	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
//	
//	dispatch_async(queue, ^{
//		[index getWithCompletionBlock:^(RCResponse *response) {
//			localResponse = response;
//			dispatch_semaphore_signal(request_sema);
//		}];
//	});
//	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
//	dispatch_semaphore_signal(request_sema);
//	dispatch_release(request_sema);
//	STAssertTrue(localResponse.success, @"Response should be successful: %@", localResponse);
//}

- (void) shouldBeAbleToRunARequestFromAPreflightBlock {
	RCResource *index = [self.service resource:@"index"];

	__block RCResponse *initialResponse = nil;

	index.preflightBlock = ^(RCRequest *request) {
		RCResource *preflightResource = [self.service resource:@"index"];
		initialResponse = [preflightResource head];
		return initialResponse.success;
	};
	
	__block RCResponse *localResponse = nil;
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	dispatch_async(queue, ^{
		[index getWithCompletionBlock:^(RCResponse *response) {
			localResponse = response;
			dispatch_semaphore_signal(request_sema);
		}];
	});
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	STAssertTrue(localResponse.success, @"Response should be successful: %@", localResponse);
}

@end
