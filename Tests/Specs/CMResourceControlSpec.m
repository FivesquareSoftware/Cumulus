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
#import "CMRequestQueue.h"

#import <XCTest/XCTest.h>

@interface CMResource (CMResourceControlSpec)
@property (nonatomic, readonly) CMRequestQueue *requestQueue;
@end
@implementation CMResource (CMResourceControlSpec)
@dynamic requestQueue;
@end

@interface CMRequestQueue (CMResourceControlSpec)
@property (nonatomic, readonly) NSUInteger actualMaxConcurrentRequests;
@end
@implementation CMRequestQueue (CMResourceControlSpec)
@dynamic actualMaxConcurrentRequests;
@end



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
	XCTAssertNotNil(identifier, @"Launching a request asynchronously should return an identifier");
}

- (void) shouldCancelARequestForIdentifier {
	CMResource *index = [self.service resource:@"index"];
	index.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;	
	id identifier = [index getWithCompletionBlock:nil];
	CMRequest *request = [index requestForIdentifier:identifier];
	[index cancelRequestForIdentifier:identifier];
	XCTAssertTrue(request.wasCanceled, @"wasCanceled should be YES (%@)", request);
	XCTAssertNil(request.URLResponse, @"URLResponse should be nil");
}

- (void)shouldCancelAllRequestsWithBlock {
	CMResource *smallResource = [self.service resource:@"slow"];
	smallResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(10, queue, ^(size_t i) {
		[smallResource getWithCompletionBlock:nil];
	});
	
	NSMutableSet *requests = smallResource.requests; // the ones that are still running at the moment
	
	dispatch_semaphore_t cancel_sema = dispatch_semaphore_create(0);
	[smallResource cancelRequestsWithBlock:^{
		dispatch_semaphore_signal(cancel_sema);
	}];
	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
		
	XCTAssertTrue([requests count] > 0, @"There must be some requests to run this this");
	for (CMRequest *request in requests) {
		[NSThread sleepForTimeInterval:.05]; // let connection die
		XCTAssertTrue(request.wasCanceled, @"wasCanceled should be YES");
		XCTAssertNil(request.URLResponse, @"URLResponse should be nil");
	}
}

- (void)shouldCancelAllRequests {
	CMResource *smallResource = [self.service resource:@"slow"];
	smallResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(10, queue, ^(size_t i) {
		[smallResource getWithCompletionBlock:nil];
	});
	
	NSMutableSet *requests = smallResource.requests; // the ones that are still running at the moment
	[smallResource cancelRequests];
	
	XCTAssertTrue([requests count] > 0, @"There must be some requests to run this this");
	
	BOOL anyRequestWasCanceled = NO;
	for (CMRequest *request in requests) {
		[NSThread sleepForTimeInterval:.05]; // let  connection die
//		NSLog(@"request: %@",request);
		if (NO == anyRequestWasCanceled) {
			anyRequestWasCanceled = request.wasCanceled;
		}
		XCTAssertTrue(request.wasCanceled || request.finished, @"wasCanceled or finished should be YES");
		if (request.wasCanceled) {
			XCTAssertNil(request.URLResponse, @"URLResponse should be nil");
		}
	}
	XCTAssertTrue(anyRequestWasCanceled, @"At least one request should have been canceled");
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
//		[smallResource cancelRequests];
	afterCancelRequestsCount = smallResource.requests.count;
	
	XCTAssertTrue(afterCancelRequestsCount > 0, @"Canceled requests should be allowed to remove themselves from their completion block (afterCancelRequestsCount: %@)",@(afterCancelRequestsCount));
	
//	for (CMRequest *request in smallResource.requests) {
		[NSThread sleepForTimeInterval:.05]; // let connections die before we start next spec
//	}
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
	XCTAssertTrue(requestsCount == 0, @"Aborted requests should not be tracked as part of the resources in flight requests");
}

#if TARGET_OS_IPHONE
- (void) shouldProperlyControlNetworkActivitySpinner {
	CMResource *resource = [self.service resource:@"index"];
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(10, queue, ^(size_t i) {
		[resource getWithCompletionBlock:nil];
	});
	[resource cancelRequests];
	
	dispatch_group_t group = dispatch_group_create();
	dispatch_apply(10, queue, ^(size_t i) {
		dispatch_group_enter(group);
		[resource getWithCompletionBlock:^(CMResponse *response) {
			dispatch_group_leave(group);
		}];
	});
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	
	XCTAssertFalse([[UIApplication sharedApplication] isNetworkActivityIndicatorVisible], @"Activity spinner should not be running");
}
#endif


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
		XCTAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
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
		XCTAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
	XCTAssertTrue(preflightBlockRan, @"Response should be successful: %@", localResponse);
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
				XCTAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
		XCTAssertTrue(preflightBlockRan, @"Response should be successful: %@", localResponse);
	}];
}

- (void) shouldLaunchAndReturnRequestIDFromTheMainThread {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}
	
	CMResource *index = [self.service resource:@"index"];
	
	id identifier = [index getWithCompletionBlock:^(CMResponse *response) {}];
	XCTAssertNotNil(identifier, @"Launching a request asynchronously from the main thread should return an identifier");
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
		XCTAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
}

- (void) shouldRunABlockingRequestFromTheMainThread {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}
	
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];

	XCTAssertTrue(response.wasSuccessful,@"Response should be successful");
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

- (void) shouldRunABlockingRequestUsingTheMainQueueAsDelegateQueue {
	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue mainQueue];
	CMResponse *response = [index get];
	
	XCTAssertTrue(response.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunABlockingRequestUsingAPrivateQueueAsDelegateQueue {
	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue new];
	CMResponse *response = [index get];
	
	XCTAssertTrue(response.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunABlockingRequestFromTheMainThreadUsingTheMainQueueAsDelegateQueue {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}

	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue mainQueue];
	CMResponse *response = [index get];
	
	XCTAssertTrue(response.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunABlockingRequestFromTheMainThreadUsingAPrivateQueueAsDelegateQueue {
	if ([NSThread currentThread] != [NSThread mainThread]) {
		[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:YES];
		return;
	}

	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue new];
	CMResponse *response = [index get];
	
	XCTAssertTrue(response.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunANonBlockingRequestUsingTheMainQueueAsDelegateQueue {
	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue mainQueue];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[index getWithCompletionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
		
	XCTAssertTrue(localResponse.wasSuccessful,@"Response should be successful");
}

- (void) shouldRunANonBlockingRequestUsingAPrivateQueueAsDelegateQueue {
	CMResource *index = [self.service resource:@"index"];
	index.requestDelegateQueue = [NSOperationQueue new];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[index getWithCompletionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
		
	XCTAssertTrue(localResponse.wasSuccessful,@"Response should be successful");
}

- (void) shouldOptimallyThrottleConcurrentRequestsWhenMaxConcurrentRequestsIsSetToDefault {
	CMResource *resource = [self.service resource:@"test/download/hero"];
	
	CMRequestQueue *requestQueue = resource.requestQueue;
	
	__block NSUInteger highwaterRequestCount = 0;
	__block BOOL success = YES;
	
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	__block NSUInteger runningCount = requestQueue.actualMaxConcurrentRequests*3;
	dispatch_apply(runningCount, queue, ^(size_t i) {
		dispatch_group_enter(group);
		[resource downloadWithProgressBlock:^(CMProgressInfo *progressInfo) {
			NSUInteger dispatchedRequestsCount = requestQueue.dispatchedRequestCount;
//			NSLog(@"**** DISPATCHED: %@ ****",@(dispatchedRequestsCount));
			if (dispatchedRequestsCount > highwaterRequestCount) {
				highwaterRequestCount = dispatchedRequestsCount;
//				NSLog(@"**** HIGHWATER: %@ ****",@(highwaterRequestCount));
			}
		} completionBlock:^(CMResponse *response) {
			if (NO == response.wasSuccessful) {
				success = NO;
			}
			dispatch_group_leave(group);
		}];
	});
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		
	XCTAssertTrue(success, @"All requests should have succeeded");
	XCTAssertTrue(highwaterRequestCount <= requestQueue.actualMaxConcurrentRequests, @"Should not have run more than the optimally max allowed requests (%@ > %@)",@(highwaterRequestCount), @(requestQueue.actualMaxConcurrentRequests));
}

- (void) shouldThrottleConcurrentRequestsWhenMaxConcurrentRequestsIsSet {
	CMResource *resource = [self.service resource:@"test/download/hero"];
	resource.maxConcurrentRequests = 2;
	
	CMRequestQueue *requestQueue = resource.requestQueue;

	__block NSUInteger highwaterRequestCount = 0;
	__block BOOL success = YES;

	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	__block NSUInteger runningCount = 10;
	dispatch_apply(runningCount, queue, ^(size_t i) {
		dispatch_group_enter(group);
		[resource downloadWithProgressBlock:^(CMProgressInfo *progressInfo) {
			NSUInteger dispatchedRequestsCount = requestQueue.dispatchedRequestCount;
//			NSLog(@"**** DISPATCHED: %@ ****",@(dispatchedRequestsCount));
			if (dispatchedRequestsCount > highwaterRequestCount) {
				highwaterRequestCount = dispatchedRequestsCount;
//				NSLog(@"**** HIGHWATER: %@ ****",@(highwaterRequestCount));
			}
		} completionBlock:^(CMResponse *response) {
			if (NO == response.wasSuccessful) {
				success = NO;
			}
			dispatch_group_leave(group);
		}];
	});

	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	
	XCTAssertTrue(success, @"All requests should have succeeded");
	XCTAssertTrue(highwaterRequestCount <= resource.maxConcurrentRequests, @"Should not have run more than the max allowed requests (%@ > %@)",@(highwaterRequestCount), @(resource.maxConcurrentRequests));
}

- (void) shouldNotThrottleConcurrentRequestsWhenMaxConcurrentRequestsIsSetToZero {
	CMResource *resource = [self.service resource:@"test/download/hero"];
	resource.maxConcurrentRequests = 0;
	
	CMRequestQueue *requestQueue = resource.requestQueue;
	XCTAssertNil(requestQueue, @"Should not have a request queue when maxConcurrentRequests is zero");
	
	__block NSUInteger highwaterRequestCount = 0;
	__block BOOL success = YES;
	
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	NSUInteger runningCount = 10;

	NSMutableSet *dispatchedRequests = [NSMutableSet new];
	dispatch_apply(runningCount, queue, ^(size_t i) {
		dispatch_group_enter(group);
		[resource downloadWithProgressBlock:^(CMProgressInfo *progressInfo) {
			[dispatchedRequests addObject:progressInfo.request];
			NSUInteger dispatchedRequestsCount = [dispatchedRequests count];
//			NSLog(@"**** DISPATCHED: %@ ****",@(dispatchedRequestsCount));
			if (dispatchedRequestsCount > highwaterRequestCount) {
				highwaterRequestCount = dispatchedRequestsCount;
//				NSLog(@"**** HIGHWATER: %@ ****",@(highwaterRequestCount));
			}
		} completionBlock:^(CMResponse *response) {
			[dispatchedRequests removeObject:response.request];
			if (NO == response.wasSuccessful) {
				success = NO;
			}
			dispatch_group_leave(group);
		}];
	});
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		
	XCTAssertTrue(success, @"All requests should have succeeded");
	XCTAssertTrue(highwaterRequestCount == runningCount, @"Should not have throttled requests (%@ == %@)",@(highwaterRequestCount), @(runningCount));
}

- (void) shouldNotThrottleBlockingRequestsWhenMaxConcurrentRequestsIsSet {
	CMResource *resource = [self.service resource:@"index"];
	resource.maxConcurrentRequests = 2;
		
	__block BOOL queueComplete = NO;
	
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	__block NSUInteger runningCount = 10;
	dispatch_apply(runningCount, queue, ^(size_t i) {
//		NSLog(@"dispatch: %@",@(i));
		dispatch_group_enter(group);
		[resource getWithCompletionBlock:^(CMResponse *response) {
			runningCount--;
//			NSLog(@"runningCount: %@",@(runningCount));
			if (runningCount == 0) {
				queueComplete = YES;
//				NSLog(@"queueComplete");
			}
			dispatch_group_leave(group);
		}];
	});
	
	// Just because it's possible for the completeion blocks above to be delayed after we make this call even though they finished first
//	CMResource *slowChild = [resource resource:@"slow"];
	[resource get];
	BOOL finishedBeforeQueue = queueComplete == NO;
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		
	XCTAssertTrue(finishedBeforeQueue, @"Blocking request should have completed before queued requests");

}

- (void) shouldCancelQueuedRequestsCorrectly {
	CMResource *resource = [self.service resource:@"index"];
	resource.maxConcurrentRequests = 2;
	
	__block BOOL anyRequestCanceledBeforeStarting = NO;
	
	dispatch_group_t group = dispatch_group_create();
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	__block NSUInteger runningCount = 25;
	dispatch_apply(runningCount, queue, ^(size_t i) {
		dispatch_group_enter(group);
		[resource getWithCompletionBlock:^(CMResponse *response) {
			if (NO == anyRequestCanceledBeforeStarting) {
				BOOL wasCanceled = response.requestWasCanceled;
				BOOL wasStarted = response.request.started;
				anyRequestCanceledBeforeStarting =  wasCanceled && NO == wasStarted;
			}
			dispatch_group_leave(group);
		}];
	});
	[resource cancelRequests];
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
		
	XCTAssertTrue(anyRequestCanceledBeforeStarting, @"Some queued requests should have been canceled before they got a chance to start");
}



// NO, you can't, these cannot block the main thread, where they are always called

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
//	//	XCTAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
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
				XCTAssertTrue(firstResponse.wasSuccessful, @"Response should be successful: %@", firstResponse);
		XCTAssertTrue(secondResponse.wasSuccessful, @"Response should be successful: %@", secondResponse);
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
				
		XCTAssertTrue(localResponse.wasSuccessful, @"Response should be successful: %@", localResponse);
	}];
}



@end
