//
//	CMResourceContextGroup.m
//	Cumulus
//
//	Created by John Clayton on 5/6/13.
//	Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceContextGroup.h"

#import "Cumulus.h"

@interface CMResourceContextGroup () {
	dispatch_group_t _dispatchGroup;
	dispatch_queue_t _requestsInternalQueue;
	dispatch_queue_t _responsesInternalQueue;
}
@property (nonatomic, strong) NSMutableSet *requestsInternal;
@property (nonatomic, strong) NSMutableSet *responsesInternal;
@end

@implementation CMResourceContextGroup

@dynamic runningRequests;
- (NSSet *) runningRequests {
	__block NSSet *runningRequests = nil;
	dispatch_sync(_requestsInternalQueue, ^{
		runningRequests = [_requestsInternal copy];
	});
	return runningRequests;
}

@dynamic responses;
- (NSSet *) responses {
	__block NSSet *responses = nil;
	dispatch_sync(_responsesInternalQueue, ^{
		responses = [_responsesInternal copy];
	});
	return responses;
}

- (void)dealloc {
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
	dispatch_release(_dispatchGroup);
	dispatch_release(_requestsInternalQueue);
	dispatch_release(_responsesInternalQueue);
}

- (id)init {
	self = [super init];
	if (self) {
		Class UUIDClass = NSClassFromString(@"NSUUID");
		if (UUIDClass) {
			_identifier = [NSUUID new];
		}
		else {
			CFUUIDRef UUID = CFUUIDCreate(NULL);
			_identifier = CFBridgingRelease(CFUUIDCreateString(NULL, UUID));
			CFRelease(UUID);
		}
		_dispatchGroup = dispatch_group_create();
		
		NSString *queueName = [NSString stringWithFormat:@"com.fivesquaresoftware.CMResourceContextGroup.requestsInternalQueue.%p", self];
		_requestsInternalQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);

		queueName = [NSString stringWithFormat:@"com.fivesquaresoftware.CMResourceContextGroup.responsesInternalQueue.%p", self];
		_responsesInternalQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);

		_requestsInternal = [NSMutableSet new];
		_responsesInternal = [NSMutableSet new];
	}
	return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ %@",[super description],_identifier];
}

- (void) enterWithRequest:(CMRequest *)request {
	RCLog(@"%@.enterWithRequest: ->",self);
	if (request) {
		dispatch_barrier_sync(_requestsInternalQueue, ^{
			[_requestsInternal addObject:request];
		});
	}
	if (_wasCanceled) {
		[request cancel];
	}
	dispatch_group_enter(_dispatchGroup);
}

- (void) leaveWithResponse:(CMResponse *)response {
	RCLog(@"%@.leaveWithResponse: <-",self);
	if (response) {
		dispatch_barrier_sync(_responsesInternalQueue, ^{
			[_responsesInternal addObject:response];
		});
		dispatch_barrier_sync(_requestsInternalQueue, ^{
			[_requestsInternal removeObject:response.request];
		});
	}
	dispatch_group_leave(_dispatchGroup);
}

- (void) wait {
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
}

- (void) cancel {
	_wasCanceled = YES;
	dispatch_sync(_requestsInternalQueue, ^{
		for (CMRequest *request in _requestsInternal) {
			[request cancel];
		}
	});
}

@end
