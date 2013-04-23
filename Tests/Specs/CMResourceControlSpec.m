//
//  CMResourceControlSpec.m
//  Cumulus
//
//  Created by John Clayton on 12/3/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceControlSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMResourceControlSpec

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
	self.service = [CMResource withURL:kTestServerHost];
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs


- (void) shouldReturnARequestIdentifierWhenLaunchingARequestAsynchronously {
	CMResource *index = [self.service resource:@"index"];
	
	id identifier = [index getWithCompletionBlock:^(CMResponse *response) {}];
	STAssertNotNil(identifier, @"Launching a request asynchronously should return an identifier");
}

- (void) shouldCancelARequestForIdentifier {
	CMResource *index = [self.service resource:@"index"];
	index.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;	
	id identifier = [index getWithCompletionBlock:nil];
	CMRequest *request = [index requestForIdentifier:identifier];
	[index cancelRequestForIdentifier:identifier];
	STAssertTrue(request.wasCanceled, @"wasCanceled should be YES");
	STAssertNil(request.URLResponse, @"URLResponse should be nil");
}

- (void)shouldCancelAllRequests {
	CMResource *smallResource = [self.service resource:@"slow"];
	smallResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		[smallResource getWithCompletionBlock:nil];
	});
	
	NSMutableSet *requests = smallResource.requests; // the ones that are still running at the moment
	
	dispatch_semaphore_t cancel_sema = dispatch_semaphore_create(0);
	[smallResource cancelRequestsWithBlock:^{
		dispatch_semaphore_signal(cancel_sema);
	}];
	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(cancel_sema);
	
	for (CMRequest *request in requests) {
		STAssertTrue(request.wasCanceled, @"wasCanceled should be YES");
		STAssertNil(request.URLResponse, @"URLResponse should be nil");
	}
}

- (void) shouldNotRemoveRequestsOnCancelation {
	CMResource *smallResource = [self.service resource:@"slow"];
	smallResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		[smallResource getWithCompletionBlock:nil];
	});
		
	dispatch_semaphore_t cancel_sema = dispatch_semaphore_create(0);
	
	__block NSUInteger afterCancelRequestsCount = 0;
	[smallResource cancelRequestsWithBlock:^{
		afterCancelRequestsCount = smallResource.requests.count;
		dispatch_semaphore_signal(cancel_sema);
	}];
	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(cancel_sema);
	
	STAssertTrue(afterCancelRequestsCount > 0, @"Canceled requests should be allowed to remove themselves from their completion block");
}

- (void) shouldNotIncludeAbortedRequests {
	CMResource *smallResource = [self.service resource:@"slow"];
	smallResource.preflightBlock = ^(CMRequest *request) {
		return NO;
	};
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		[smallResource getWithCompletionBlock:nil];
	});
	
	NSUInteger *requestsCount = smallResource.requests.count;
	STAssertTrue(requestsCount == 0, @"Aborted requests should not be tracked as part of the resources in flight requests");
}

- (void) shouldRunAsynchronouslyFromTheMainQueue {
	CMResource *index = [self.service resource:@"index"];
	
	__block CMResponse *localResponse = nil;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);

	dispatch_async(dispatch_get_main_queue(), ^{
		[index getWithCompletionBlock:^(CMResponse *response) {
			localResponse = response;
			dispatch_semaphore_signal(request_sema);
		}];
	});
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	STAssertTrue(localResponse.success, @"Response should be successful: %@", localResponse);
}

- (void) shouldRunAsynchronouslyFromConcurrentQueue {
	CMResource *index = [self.service resource:@"index"];
	
	__block CMResponse *localResponse = nil;
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	dispatch_async(queue, ^{
		[index getWithCompletionBlock:^(CMResponse *response) {
			localResponse = response;
			dispatch_semaphore_signal(request_sema);
		}];
	});
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	STAssertTrue(localResponse.success, @"Response should be successful: %@", localResponse);
}

- (void) shouldRunABlockingRequestFromTheMainThread {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}
	
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];

	STAssertTrue(response.success,@"Response should be successful");
}



//- (void) shouldBeAbleToRunARequestFromAPreflightBlock {	
//	CMResource *index = [self.service resource:@"index"];
//
//	index.preflightBlock = ^(CMRequest *request) {
//		__block BOOL success = NO;
////		// You need to dispatch off the main queue because this is being called on the main thread and will deadlock if you dispatch to the main queue again 
//		dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
//		dispatch_sync(queue, ^{
//			CMResource *preflightResource = [self.service resource:@"index"];
//			CMResponse *response = [preflightResource head];
//			success = response.success;
//		});
//		return success;
//	};
//	
//	__block CMResponse *localResponse = nil;
//	
//	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
//	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
//	
//	[index getWithCompletionBlock:^(CMResponse *response) {
//		localResponse = response;
//		dispatch_semaphore_signal(request_sema);
//	}];
//	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
//	dispatch_semaphore_signal(request_sema);
//	dispatch_release(request_sema);
//	STAssertTrue(localResponse.success, @"Response should be successful: %@", localResponse);
//}



@end
