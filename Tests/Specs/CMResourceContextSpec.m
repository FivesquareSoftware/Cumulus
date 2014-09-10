//
//  CMResourceContextSpec.m
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceContextSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>
#import <objc/runtime.h>

@interface CMResourceContext (CMResourceContextSpec)
@property (nonatomic, copy) void(^shutdownHook)();
@end
@implementation CMResourceContext (CMResourceContextSpec)
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"
- (void)dealloc {
	if (self.shutdownHook) {
		self.shutdownHook();
	}
}
#pragma clang diagnostic pop
static const NSString *kNSObject_CMResourceContext_shutdownHook;
@dynamic shutdownHook;
- (void(^)()) shutdownHook {
	id shutdownHookObject = objc_getAssociatedObject(self, &kNSObject_CMResourceContext_shutdownHook);
	return (void(^)())shutdownHookObject;
}
- (void) setShutdownHook:(void (^)())shutdownHook {
	id shutdownHookObject = (id)shutdownHook;
	objc_setAssociatedObject(self, &kNSObject_CMResourceContext_shutdownHook, shutdownHookObject, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
@end


@interface MyScopeObject : NSObject
@property (nonatomic, copy) void(^shutdownHook)();
@end
@implementation MyScopeObject
- (void)dealloc {
	if (_shutdownHook) {
		_shutdownHook();
	}
}
@end

@implementation CMResourceContextSpec

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
	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	CMResourceContext *context = [CMResourceContext withName:@"Test Group"];
	
	//	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	__block BOOL localSuccess = NO;
	__block NSSet *localResponses = nil;
	__block BOOL completionBlockRan = NO;
	
	[context performRequestsAndWait:^() {
		CMResource *index = [self.service resource:@"index"];
		[index get];
		
		CMResource *item = [self.service resource:@"test/get/item"];
		[item getWithCompletionBlock:^(CMResponse *response) {
			completionBlockRan = YES;
		}];
		
	} withCompletionBlock:^(BOOL success, NSSet *responses) {
		localSuccess = success;
		localResponses = responses;
		dispatch_semaphore_signal(group_semaphore);
	}];
	
	dispatch_semaphore_wait(group_semaphore, DISPATCH_TIME_FOREVER);
		
	STAssertTrue(localSuccess, @"Group should have succeeded");
	STAssertTrue(localResponses.count == 2, @"Group should have passed along contained responses: %@",localResponses);
	STAssertTrue(completionBlockRan, @"Completion block of asynchronous get should have run");
}

- (void) shouldRunMultipleWorkBlocksConcurrentlyWithoutMixingThemUp {
	
	dispatch_group_t group = dispatch_group_create();

	__block BOOL localSuccess = YES;
	__block BOOL localResponseCountCorrect = YES;
	
	for (int i = 0; i < 10; i++) {
		dispatch_group_enter(group);
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			CMResourceContext *context = [CMResourceContext withName:@"Test Group"];
			
			//	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
			[context performRequestsAndWait:^() {
				CMResource *index = [self.service resource:@"index"];
				[index get];
				
				CMResource *item = [self.service resource:@"test/get/item"];
				[item getWithCompletionBlock:nil];
				
			} withCompletionBlock:^(BOOL success, NSSet *responses) {
				if (localSuccess) {
					localSuccess = success;
				}
				if (localResponseCountCorrect) {
					localResponseCountCorrect = (responses.count == 2);
				}

				dispatch_group_leave(group);
			}];
		});
	}
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	
	STAssertTrue(localSuccess, @"Groups should have succeeded");
	STAssertTrue(localResponseCountCorrect, @"Groups should have passed along contained responses");
}

- (void) shouldNotExistLongerThanGroupWorkWhenNotRetained {
	dispatch_semaphore_t context_semaphore = dispatch_semaphore_create(0);

	CMResourceContext *context = [CMResourceContext withName:@"Test Group"];
	context.shutdownHook = ^{
		dispatch_semaphore_signal(context_semaphore);
	};
	
	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	
	[context performRequestsAndWait:^() {
		CMResource *index = [self.service resource:@"index"];
		[index get];
		
		CMResource *item = [self.service resource:@"test/get/item"];
		[item getWithCompletionBlock:nil];
		
	} withCompletionBlock:^(BOOL success, NSSet *responses) {
		dispatch_semaphore_signal(group_semaphore);
	}];
	
	dispatch_semaphore_wait(group_semaphore, DISPATCH_TIME_FOREVER);
		
	context = nil;
	
	[self.specRunner deferResult:self.currentResult untilDone:^{
		dispatch_semaphore_wait(context_semaphore, DISPATCH_TIME_FOREVER);
				STAssertNil(context, @"Context should no longer exist!");
	}];
}

- (void) shouldCancelGroupWorkForIdentifier {
	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	CMResourceContext *context = [CMResourceContext withName:@"Test Group"];
	
	//	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	__block BOOL anyRequestWasCanceled = NO;
	__block NSSet *localResponses = nil;
	
	dispatch_semaphore_t launch_semaphore = dispatch_semaphore_create(0);

	id groupIdentifier = [context performRequestsAndWait:^() {
		CMResource *item = [self.service resource:@"index"];
		for (int i = 0; i < 10; i++) {
			[item getWithCompletionBlock:nil];
		}
		dispatch_semaphore_signal(launch_semaphore);
	} withCompletionBlock:^(BOOL success, NSSet *responses) {
		localResponses = responses;
		dispatch_semaphore_signal(group_semaphore);
	}];
	
	dispatch_semaphore_wait(launch_semaphore, DISPATCH_TIME_FOREVER);
		[context cancelRequestsForIdentifier:groupIdentifier];
	
	dispatch_semaphore_wait(group_semaphore, DISPATCH_TIME_FOREVER);
		
	[localResponses enumerateObjectsUsingBlock:^(CMResponse *response, BOOL *stop) {
		anyRequestWasCanceled = response.request.wasCanceled;
		if (anyRequestWasCanceled) {
			*stop = YES;
			return;
		}
	}];
	
	STAssertTrue(anyRequestWasCanceled, @"At least one request should have been canceled: %@",localResponses);
}


- (void) shouldCancelAllGroupWork {
	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	CMResourceContext *context = [CMResourceContext withName:@"Test Group"];
	
	//	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	__block BOOL anyRequestWasCanceled = NO;
	__block NSSet *localResponses = nil;
	
	dispatch_semaphore_t launch_semaphore = dispatch_semaphore_create(0);

	[context performRequestsAndWait:^() {
		CMResource *item = [self.service resource:@"index"];
		for (int i = 0; i < 10; i++) {
			[item getWithCompletionBlock:nil];
		}
		dispatch_semaphore_signal(launch_semaphore);
	} withCompletionBlock:^(BOOL success, NSSet *responses) {
		localResponses = responses;
		dispatch_semaphore_signal(group_semaphore);
	}];
	
	dispatch_semaphore_wait(launch_semaphore, DISPATCH_TIME_FOREVER);
		[context cancelAllRequests];
	
	dispatch_semaphore_wait(group_semaphore, DISPATCH_TIME_FOREVER);
		
	[localResponses enumerateObjectsUsingBlock:^(CMResponse *response, BOOL *stop) {
		anyRequestWasCanceled = response.request.wasCanceled;
		if (anyRequestWasCanceled) {
			*stop = YES;
			return;
		}
	}];
	
	STAssertTrue(anyRequestWasCanceled, @"At least one request should have been canceled: %@",localResponses);
}

- (void) shouldCancelRequestsWhenTheirScopeDisappears {

	dispatch_semaphore_t scope_semaphore = dispatch_semaphore_create(0);

	CMResourceContext *context = [CMResourceContext withName:@"Testing Scope"];
	
	MyScopeObject *scope = [MyScopeObject new];
	scope.shutdownHook = ^{
		dispatch_semaphore_signal(scope_semaphore);
	};


	NSMutableSet *requests = [NSMutableSet new];
	NSMutableArray *requestIDs = [NSMutableArray new];

	CMResource *resource = [self.service resource:@"slow"];
	resource.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	resource.preflightBlock = ^(CMRequest *request) {
		[requestIDs addObject:request.identifier];
		[requests addObject:request];
		return YES;
	};
	
	dispatch_semaphore_t launch_semaphore = dispatch_semaphore_create(0);
	
	[context performRequests:^{
		for (int i = 0; i < 3; i++) {
			[resource getWithCompletionBlock:nil];
		}
		dispatch_semaphore_signal(launch_semaphore);
	} inScope:scope];
	
	dispatch_semaphore_wait(launch_semaphore, DISPATCH_TIME_FOREVER);
		
	scope = nil;
	
	
	[self.specRunner deferResult:self.currentResult untilDone:^{
		dispatch_semaphore_wait(scope_semaphore,DISPATCH_TIME_FOREVER);
		
//		CMRequest *lastRequest = [[requests objectsPassingTest:^BOOL(CMRequest *obj, BOOL *stop) {
//			return obj.identifier == [requestIDs lastObject];
//		}] anyObject];
//		CMRequest *anyRequest = [requests anyObject];
		
		__block BOOL anyRequestCanceled = NO;
		__block BOOL running = NO;
		do {
			[requests enumerateObjectsUsingBlock:^(CMRequest *obj, BOOL *stop) {
				if (anyRequestCanceled == NO && obj.wasCanceled) {
					anyRequestCanceled = YES;
				}
				if (NO == obj.isFinished) {
					*stop = YES;
					running = YES;
					return;
				}
				else {
					running = NO;
				}
			}];
			if (running) {
				[NSThread sleepForTimeInterval:.01];
			}
			
		} while (running == YES);

		
		//		STAssertTrue(lastRequest.wasCanceled, @"Request should have been canceled: %@",lastRequest);
		STAssertTrue(anyRequestCanceled, @"At least one request should have been canceled: %@",requests);
	}];
}


/* No, does not behave like this
- (void) shouldWaitForRequestsLaunchedFromRequestCompletionBlocks {

	CMResourceContext *group = [CMResourceContext withName:@"Subrequest Group"];
	
	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
	__block BOOL localSuccess = NO;
	__block NSArray *localResponses = nil;
	__block BOOL completionBlockRan = NO;
	__block BOOL subCompletionBlockRan = NO;
	
	[group performWork:^(CMResourceContext *group) {
		CMResource *item = [self.service resource:@"test/get/item"];
		[item getWithCompletionBlock:^(CMResponse *response) {
			completionBlockRan = YES;
			CMResource *index = [self.service resource:@"index"];
			[index getWithCompletionBlock:^(CMResponse *response) {
				subCompletionBlockRan = YES;
			}];
		}];
		
	} withCompletionBlock:^(BOOL success, NSArray *responses) {
		localSuccess = success;
		localResponses = responses;
		dispatch_semaphore_signal(group_semaphore);
	}];
	
	dispatch_semaphore_wait(group_semaphore, DISPATCH_TIME_FOREVER);
		
	STAssertTrue(localSuccess, @"Group should have succeeded");
	STAssertTrue(localResponses.count == 2, @"Group should have passed along contained responses: %@",localResponses);
	STAssertTrue(completionBlockRan, @"Completion block of asynchronous get should have run");
	STAssertTrue(subCompletionBlockRan, @"Completion block of asynchronous sub request should have run");
}

*/

// ========================================================================== //

#pragma mark - Helpers


//- (void) runGroupWithCompletionBlock:((void)(^)(BOOL success, NSSet *responses))completionBlock {
//	CMResourceContext *context = [CMResourceContext withName:@"Test Group"];
//	
////	dispatch_semaphore_t group_semaphore = dispatch_semaphore_create(0);
//	[context performRequestsAndWait:^() {
//		CMResource *index = [self.service resource:@"index"];
//		[index get];
//		
//		CMResource *item = [self.service resource:@"test/get/item"];
//		[item getWithCompletionBlock:nil];
//		
//	} withCompletionBlock:completionBlock];
//	
//}
//



@end
