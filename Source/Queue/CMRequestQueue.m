//
//  CMRequestQueue.m
//  Cumulus
//
//  Created by John Clayton on 8/3/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMRequestQueue.h"

#import "Cumulus.h"

#import "CMRequest.h"
#import <sys/sysctl.h>


@interface CMRequestQueue ()
@property (nonatomic, readonly) NSUInteger optimalMaxConcurrentRequestsForEnvironment;
@property (nonatomic, readonly) NSUInteger actualMaxConcurrentRequests;
@property (nonatomic, readonly) NSUInteger numberOfCores;

@property (nonatomic, strong) NSMutableOrderedSet *queuedIdentifiers;
@property (nonatomic, strong) NSMutableDictionary *queuedDispatchBlocksByIdentifier;
@property (nonatomic, strong) NSMutableSet *dispatchedIdentifiers;

@property (nonatomic, strong) dispatch_queue_t dispatchAccessQueue;

@end

@implementation CMRequestQueue

+ (id) sharedRequestQueue {
	static CMRequestQueue *__sharedQueue = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		__sharedQueue = [CMRequestQueue new];
	});
	return __sharedQueue;
}


// ========================================================================== //

#pragma mark - Properties

@dynamic dispatchedRequestCount;
- (NSUInteger) dispatchedRequestCount {
	__block NSUInteger dispatchedRequestCount = 0;
	dispatch_sync(_dispatchAccessQueue, ^{
		dispatchedRequestCount = [_dispatchedIdentifiers count];
//		CMLog(@"_dispatchedIdentifiers.count: %@",@(dispatchedRequestCount));
	});
	return dispatchedRequestCount;
}

@dynamic optimalMaxConcurrentRequestsForEnvironment;
- (NSUInteger) optimalMaxConcurrentRequestsForEnvironment {
	// This could be more dynamic and consider factors such as the device capabilities, how many other running requests are happening, whether or not performance is degrading, etc. But for now, we will set some hard average limits based on number of cores and leave it at that.
#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR
	NSUInteger optimalMaxRequests = 2;
#else
	NSUInteger optimalMaxRequests = 10;
#endif

	NSUInteger numberOfCores = self.numberOfCores;
	if (numberOfCores > 0) {
		optimalMaxRequests = numberOfCores*2;
	}
	return optimalMaxRequests;
}

@dynamic actualMaxConcurrentRequests;
- (NSUInteger) actualMaxConcurrentRequests {
	NSUInteger actualMaxConcurrentRequests = _maxConcurrentRequests;
	if (actualMaxConcurrentRequests == kCumulusDefaultMaxConcurrentRequestCount) {
		actualMaxConcurrentRequests = self.optimalMaxConcurrentRequestsForEnvironment;
	}
	return actualMaxConcurrentRequests;
}

@dynamic numberOfCores;
- (NSUInteger) numberOfCores {
	size_t len;
	NSUInteger numberOfCPUs;
	
	len = sizeof(numberOfCPUs);
	sysctlbyname ("hw.ncpu",&numberOfCPUs,&len,NULL,0);
	
	return numberOfCPUs;
}


// ========================================================================== //

#pragma mark - Object



- (id)init {
	self = [super init];
	if (self) {
		_maxConcurrentRequests = kCumulusDefaultMaxConcurrentRequestCount;
		_queuedIdentifiers = [NSMutableOrderedSet new];
		_queuedDispatchBlocksByIdentifier = [NSMutableDictionary new];
		_dispatchedIdentifiers = [NSMutableSet new];
		
		NSString *queueName = [NSString stringWithFormat:@"com.fivesquaresoftware.CMRequestQueue.dispatchAccessQueue.%p", self];
		_dispatchAccessQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_SERIAL);
	}
	return self;
}


// ========================================================================== //

#pragma mark - Public



- (void) queueRequest:(CMRequest *)request withCompletionBlock:(CMCompletionBlock)completionBlock {
//	CMLog(@"queueRequest: %@",request);
	void(^dispatchBlock)() = ^{
		[request startWithCompletionBlock:^(CMResponse *response) {
			if ((completionBlock)) {
				completionBlock(response);
			}
			[self dispatchComplete:request.identifier];
		}];
	};
	[self queueForDispatch:dispatchBlock forIdentifier:request.identifier];
}



// ========================================================================== //

#pragma mark - Private


- (void) queueForDispatch:(void(^)())dispatchBlock forIdentifier:(id)identifier {
	NSParameterAssert(identifier);
	dispatch_sync(_dispatchAccessQueue, ^{
//		CMLog(@"Queueing identifier: %@",identifier);
		[_queuedIdentifiers addObject:identifier];
		_queuedDispatchBlocksByIdentifier[identifier] = [dispatchBlock copy];
	});
	[self dispatchNext];
}

- (void) dispatchNext {
	NSUInteger actualAllowedMax = self.actualMaxConcurrentRequests;
	dispatch_sync(_dispatchAccessQueue, ^{
		NSUInteger dispatchedCount = [_dispatchedIdentifiers count];
//		CMLog(@"dispatchedCount: %@",@(dispatchedCount));
//		CMLog(@"actualAllowedMax: %@",@(actualAllowedMax));
		if (dispatchedCount < actualAllowedMax) {
//			CMLog(@"OK to deque next request..looking");
			__block id nextIdentifier = nil;
			__block void(^dispatchBlock)() = nil;
			if ([_queuedIdentifiers count] > 0) {
				nextIdentifier = [_queuedIdentifiers firstObject];
//				CMLog(@"Found next identifier to dispatch: %@",nextIdentifier);
				[_queuedIdentifiers removeObjectAtIndex:0];
				dispatchBlock = _queuedDispatchBlocksByIdentifier[nextIdentifier];
				if (dispatchBlock) {
//					CMLog(@"Have dispatch block, dispatching for identifier %@",nextIdentifier);
					[_dispatchedIdentifiers addObject:nextIdentifier];
					dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), dispatchBlock);
					[_queuedDispatchBlocksByIdentifier removeObjectForKey:nextIdentifier];
				}
			}
		}
	});
}

- (void) dispatchComplete:(id)identifier {
	dispatch_sync(_dispatchAccessQueue, ^{
//		CMLog(@"Completed identifier: %@",identifier);
		[_dispatchedIdentifiers removeObject:identifier];
	});
	[self dispatchNext];
}


@end
