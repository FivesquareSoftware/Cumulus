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


@interface BlockingAuthProvider : CMBasicAuthProvider
@end
@implementation BlockingAuthProvider
- (void) authorizeRequest:(NSMutableURLRequest *)urlRequest {
	[super authorizeRequest:urlRequest];
	CMResponse *response = [[[CMResource withURL:kTestServerHost] resource:@"index"] get];
	NSLog(@"blocking auth response: %@",response);
}
@end


@implementation CMResourceControlSpec


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
	STAssertTrue(request.wasCanceled, @"wasCanceled should be YES (%@)", request);
	STAssertNil(request.URLResponse, @"URLResponse should be nil");
}

- (void)shouldCancelAllRequests {
	CMResource *smallResource = [self.service resource:@"slow"];
	smallResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
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
		[NSThread sleepForTimeInterval:.05]; // let connections die before we start next spec
	}
}

- (void) shouldNotRemoveRequestsOnCancelation {
	CMResource *smallResource = [self.service resource:@"slow"];
	smallResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		[smallResource getWithCompletionBlock:nil];
	});
		
//	dispatch_semaphore_t cancel_sema = dispatch_semaphore_create(0);
	
	__block NSUInteger afterCancelRequestsCount = 0;
//	[smallResource cancelRequestsWithBlock:^{
//		afterCancelRequestsCount = smallResource.requests.count;
//		dispatch_semaphore_signal(cancel_sema);
//	}];
//	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
//	dispatch_release(cancel_sema);
	[smallResource cancelRequests];
	afterCancelRequestsCount = smallResource.requests.count;
	
	STAssertTrue(afterCancelRequestsCount > 0, @"Canceled requests should be allowed to remove themselves from their completion block (afterCancelRequestsCount: %@)",@(afterCancelRequestsCount));
	
	for (CMRequest *request in smallResource.requests) {
		[NSThread sleepForTimeInterval:.05]; // let connections die before we start next spec
	}
}

- (void) shouldNotIncludeAbortedRequests {
	CMResource *smallResource = [self.service resource:@"index"];
	smallResource.preflightBlock = ^(CMRequest *request) {
		return NO;
	};
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		[smallResource getWithCompletionBlock:nil];
	});
	
	NSUInteger requestsCount = smallResource.requests.count;
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
	STAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
}

- (void) shouldRunAsynchronouslyFromTheMainQueueWithPreflightBlock {
	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL preflightBlockRan = NO;
	index.preflightBlock = ^(CMRequest *request) {
		preflightBlockRan = YES;
		return YES;
	};
	
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
	STAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
	STAssertTrue(preflightBlockRan, @"Response should be successful: %@", localResponse);
}

- (void) shouldRunFromTheMainThreadWithPreflightBlock {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}

	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL preflightBlockRan = NO;
	index.preflightBlock = ^(CMRequest *request) {
		preflightBlockRan = YES;
		return YES;
	};
	
	__block CMResponse *localResponse = nil;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	[index getWithCompletionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	[self.specRunner deferResult:self.currentResult untilDone:^{
		dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
		dispatch_release(request_sema);
		STAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
		STAssertTrue(preflightBlockRan, @"Response should be successful: %@", localResponse);
	}];
}

- (void) shouldLaunchAndReturnRequestIDFromTheMainThread {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}
	
	CMResource *index = [self.service resource:@"index"];
	
	id identifier = [index getWithCompletionBlock:^(CMResponse *response) {}];
	STAssertNotNil(identifier, @"Launching a request asynchronously from the main thread should return an identifier");
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
	STAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
}

- (void) shouldRunABlockingRequestFromTheMainThread {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}
	
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];

	STAssertTrue(response.wasSuccessful,@"Response should be successful");
}

- (void) shouldBeAbleToLaunchARequestFromACompletionBlock {
	[self assertLaunchARequestFromCompletionBlock];
}

- (void) shouldBeAbleToLaunchARequestFromACompletionBlockWhenStartedOnMainThread {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}
	
	[self assertLaunchARequestFromCompletionBlock];
}

- (void) shouldBeAbleToRunABlockingRequestFromAnAuthProvider {
	[self assertRunRequestWithBlockingProvider];
}

- (void) shouldBeAbleToRunABlockingRequestFromAnAuthProviderWhenStartedOnMainThread {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}

	[self assertRunRequestWithBlockingProvider];
}

- (void) shouldRunABlockingRequestOnTheMainQueue {
	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue mainQueue];
	CMResponse *response = [index get];
	
	STAssertTrue(response.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunABlockingRequestOnAPrivateQueue {
	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue new];
	CMResponse *response = [index get];
	
	STAssertTrue(response.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunABlockingRequestFromTheMainThreadOnTheMainQueue {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}

	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue mainQueue];
	CMResponse *response = [index get];
	
	STAssertTrue(response.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunABlockingRequestFromTheMainThreadOnAPrivateQueue {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}

	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue new];
	CMResponse *response = [index get];
	
	STAssertTrue(response.wasSuccessful,@"Response should be successful");
}


//- (void) shouldThrottleRequestsRunOnAPrivateQueueWithMaxConcurrentOperationsSet {
//	
//	NSOperationQueue *throttledQueue = [NSOperationQueue new];
//	NSUInteger maxAllowedRequests = 1;
//	throttledQueue.maxConcurrentOperationCount = maxAllowedRequests;
//	
//	
//	CMResource *smallResource = [self.service resource:@"test/download/hero"];
//	smallResource.requestQueue = throttledQueue;
//
//	__block NSUInteger runningRequests = 0;
//	__block NSUInteger highwaterRequestCount = 0;
//	__block BOOL success = YES;
//	
//	dispatch_group_t group = dispatch_group_create();
//	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
//	__block NSUInteger runningCount = 50;
//	dispatch_apply(runningCount, queue, ^(size_t i) {
//		dispatch_group_enter(group);
//		__block BOOL hasIncrementedRunningRequests = NO;
//		[smallResource downloadWithProgressBlock:^(CMProgressInfo *progressInfo) {
//			float progress = [progressInfo.progress floatValue];
//			if (progress > 0 && NO == hasIncrementedRunningRequests) {
//				hasIncrementedRunningRequests = YES;
//				runningRequests++;
//				if (runningRequests > highwaterRequestCount) {
//					highwaterRequestCount = runningRequests;
//				}
//			}
//			else if (progress == 1.) {
//				runningRequests--;
//			}
//		} completionBlock:^(CMResponse *response) {
//			runningRequests--;
//			if (NO == response.wasSuccessful) {
//				success = NO;
//			}
//			dispatch_group_leave(group);
//		}];
//	});
//	
//	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
//	dispatch_release(group);
//	
//	STAssertTrue(success, @"All requests should have succeeded");
//	STAssertTrue(highwaterRequestCount <= maxAllowedRequests, @"Should not have run more than the max allowed requests (%@ > %@)",@(highwaterRequestCount), @(maxAllowedRequests));
//}

- (void) shouldRunANonBlockingRequestOnTheMainQueue {
	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue mainQueue];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[index getWithCompletionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunANonBlockingRequestOnAPrivateQueue {
	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue new];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[index getWithCompletionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.wasSuccessful,@"Response should be successful");
}


//- (void) shouldBeAbleToRunARequestFromAPreflightBlock {	
//	CMResource *index = [self.service resource:@"index"];
//
//	index.preflightBlock = ^(CMRequest *request) {
//		CMResource *preflightResource = [self.service resource:@"index"];
//		CMResponse *response = [preflightResource head];
//		return response.wasSuccessful;
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
//	STAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
//}

// ========================================================================== //

#pragma mark - Helpers


- (void) assertLaunchARequestFromCompletionBlock {
	CMResource *index = [self.service resource:@"index"];
	
	__block CMResponse *firstResponse = nil;
	__block CMResponse *secondResponse = nil;
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	[index getWithCompletionBlock:^(CMResponse *response) {
		firstResponse = response;
		CMResource *echo = [self.service resource:@"echo"];
		echo.contentType = CMContentTypeJSON;
		[echo put:@{ @"message" : @"hello" } withCompletionBlock:^(CMResponse *subResponse) {
			secondResponse = subResponse;
			dispatch_semaphore_signal(request_sema);
		}];
	}];
	
	[self.specRunner deferResult:self.currentResult untilDone:^{
		dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
		dispatch_release(request_sema);
		STAssertTrue(firstResponse.wasSuccessful, @"Response should be successful: %@", firstResponse);
		STAssertTrue(secondResponse.wasSuccessful, @"Response should be successful: %@", secondResponse);
	}];
}

- (void) assertRunRequestWithBlockingProvider {
	BlockingAuthProvider *blockingProvider = [BlockingAuthProvider withUsername:@"test" password:@"test"];
	CMResource *protectedResource = [self.service resource:@"test/protected"];
	[protectedResource addAuthProvider:blockingProvider];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	[protectedResource getWithCompletionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];	
	
	[self.specRunner deferResult:self.currentResult untilDone:^{
		dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
		dispatch_release(request_sema);
		
		STAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
	}];
}



@end
