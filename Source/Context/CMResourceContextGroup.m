//
//	CMResourceContextGroup.m
//	Cumulus
//
//	Created by John Clayton on 5/6/13.
//	Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceContextGroup.h"

#import "Cumulus.h"

@interface CMResourceContextGroup ()

@property (nonatomic, strong) NSMutableSet *requestsInternal;
@property (nonatomic, strong) NSMutableSet *responsesInternal;

@property (nonatomic, strong) dispatch_group_t dispatchGroup;
@property (nonatomic, strong) dispatch_queue_t requestsInternalAccessQueue;
@property (nonatomic, strong) dispatch_queue_t responsesInternalAccessQueue;

@end

@implementation CMResourceContextGroup

@dynamic runningRequests;
- (NSSet *) runningRequests {
	__block NSSet *runningRequests = nil;
	dispatch_sync(_requestsInternalAccessQueue, ^{
		runningRequests = [_requestsInternal copy];
	});
	return runningRequests;
}

@dynamic responses;
- (NSSet *) responses {
	__block NSSet *responses = nil;
	dispatch_sync(_responsesInternalAccessQueue, ^{
		responses = [_responsesInternal copy];
	});
	return responses;
}

- (void)dealloc {
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
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
		
		NSString *queueName = [NSString stringWithFormat:@"com.fivesquaresoftware.CMResourceContextGroup.requestsInternalAccessQueue.%p", self];
		_requestsInternalAccessQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);

		queueName = [NSString stringWithFormat:@"com.fivesquaresoftware.CMResourceContextGroup.responsesInternalAccessQueue.%p", self];
		_responsesInternalAccessQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);

		_requestsInternal = [NSMutableSet new];
		_responsesInternal = [NSMutableSet new];
	}
	return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ %@",[super description],_identifier];
}

- (void) enterWithRequest:(CMRequest *)request {
	CMLog(@"%@.enterWithRequest: ->",self);
	if (request) {
		dispatch_barrier_sync(_requestsInternalAccessQueue, ^{
			[_requestsInternal addObject:request];
		});
	}
	if (_wasCanceled) {
		[request cancel];
	}
	dispatch_group_enter(_dispatchGroup);
}

- (void) leaveWithResponse:(CMResponse *)response {
	CMLog(@"%@.leaveWithResponse: <-",self);
	if (response) {
		dispatch_barrier_sync(_responsesInternalAccessQueue, ^{
			[_responsesInternal addObject:response];
		});
		dispatch_barrier_sync(_requestsInternalAccessQueue, ^{
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
	dispatch_sync(_requestsInternalAccessQueue, ^{
		for (CMRequest *request in _requestsInternal) {
			[request cancel];
		}
	});
}

@end
