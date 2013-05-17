//
//  CMResourceContextGroup.m
//  Cumulus
//
//  Created by John Clayton on 5/6/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceContextGroup.h"

#import "Cumulus.h"

@interface CMResourceContextGroup () {
	dispatch_group_t _dispatchGroup;
	dispatch_semaphore_t _dispatchSemaphore;
}
@property (nonatomic, strong) NSMutableSet *requestsInternal;
@property (nonatomic, strong) NSMutableSet *responsesInternal;
@end

@implementation CMResourceContextGroup

@dynamic runningRequests;
- (NSSet *) runningRequests {
	dispatch_semaphore_wait(_dispatchSemaphore, DISPATCH_TIME_FOREVER);
	NSSet *runningRequests = [_requestsInternal copy];
	dispatch_semaphore_signal(_dispatchSemaphore);
	return runningRequests;
}

@dynamic responses;
- (NSSet *) responses {
	dispatch_semaphore_wait(_dispatchSemaphore, DISPATCH_TIME_FOREVER);
	NSSet *responses = [_responsesInternal copy];
	dispatch_semaphore_signal(_dispatchSemaphore);
	return responses;
}

- (void)dealloc {
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    dispatch_release(_dispatchGroup);
	dispatch_release(_dispatchSemaphore);
}

- (id)init {
    self = [super init];
    if (self) {
		_identifier = [NSUUID new];
		_dispatchGroup = dispatch_group_create();
//		NSString *queueName = [NSString stringWithFormat:@"com.fivesquaresoftware.Cumulus.CMResourceContextGroup.%@",_identifier];
//		_dispatchQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
		_dispatchSemaphore = dispatch_semaphore_create(1);
		_requestsInternal = [NSMutableSet new];
		_responsesInternal = [NSMutableSet new];
    }
    return self;
}

- (NSString *) debugDescription {
	return [NSString stringWithFormat:@"%@ %@",[super debugDescription],_identifier];
}

- (void) enterWithRequest:(CMRequest *)request {
	RCLog(@"%@.enterWithRequest: ->",self);
	if (request) {
		dispatch_semaphore_wait(_dispatchSemaphore, DISPATCH_TIME_FOREVER);
		[_requestsInternal addObject:request];
		dispatch_semaphore_signal(_dispatchSemaphore);
	}
	if (_wasCanceled) {
		[request cancel];
	}
	dispatch_group_enter(_dispatchGroup);
}

- (void) leaveWithResponse:(CMResponse *)response {
	RCLog(@"%@.leaveWithResponse: <-",self);
	if (response) {
		dispatch_semaphore_wait(_dispatchSemaphore, DISPATCH_TIME_FOREVER);
		[_responsesInternal addObject:response];
		[_requestsInternal removeObject:response.request];
		dispatch_semaphore_signal(_dispatchSemaphore);
	}
	dispatch_group_leave(_dispatchGroup);
}

- (void) wait {
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
}

- (void) cancel {
	_wasCanceled = YES;
	dispatch_semaphore_wait(_dispatchSemaphore, DISPATCH_TIME_FOREVER);
	[_requestsInternal enumerateObjectsUsingBlock:^(CMRequest *request, BOOL *stop) {
		[request cancel];
	}];
	dispatch_semaphore_signal(_dispatchSemaphore);
}

@end
