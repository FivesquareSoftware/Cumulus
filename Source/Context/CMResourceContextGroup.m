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
}
@property (nonatomic, strong) NSMutableSet *requestsInternal;
@property (nonatomic, strong) NSMutableSet *responsesInternal;
@end

@implementation CMResourceContextGroup

@dynamic runningRequests;
- (NSSet *) runningRequests {
	NSSet *runningRequests = [_requestsInternal copy];
	return runningRequests;
}

@dynamic responses;
- (NSSet *) responses {
	NSSet *responses = [_responsesInternal copy];
	return responses;
}

- (void)dealloc {
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    dispatch_release(_dispatchGroup);
}

- (id)init {
    self = [super init];
    if (self) {
		_identifier = [NSUUID new];
		_dispatchGroup = dispatch_group_create();
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
		[_requestsInternal addObject:request];
	}
	if (_wasCanceled) {
		[request cancel];
	}
	dispatch_group_enter(_dispatchGroup);
}

- (void) leaveWithResponse:(CMResponse *)response {
	RCLog(@"%@.leaveWithResponse: <-",self);
	if (response) {
		[_responsesInternal addObject:response];
		[_requestsInternal removeObject:response.request];
	}
	dispatch_group_leave(_dispatchGroup);
}

- (void) wait {
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
}

- (void) cancel {
	_wasCanceled = YES;
	[_requestsInternal enumerateObjectsUsingBlock:^(CMRequest *request, BOOL *stop) {
		[request cancel];
	}];
}

@end
