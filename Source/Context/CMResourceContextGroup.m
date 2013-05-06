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
@property (nonatomic, strong) NSMutableSet *responsesInternal;
@end

@implementation CMResourceContextGroup

@dynamic responses;
- (NSSet *) responses {
	return [NSSet setWithSet:_responsesInternal];
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
		_responsesInternal = [NSMutableSet new];
    }
    return self;
}

- (NSString *) debugDescription {
	return [NSString stringWithFormat:@"%@ %@",[super debugDescription],_identifier];
}

- (void) enter {
	RCLog(@"%@.enter ->",self);
	dispatch_group_enter(_dispatchGroup);
}

- (void) leaveWithResponse:(CMResponse *)response {
	RCLog(@"%@.leaveWithResponse: <-",self);
	if (response) {
		[_responsesInternal addObject:response];
	}
	dispatch_group_leave(_dispatchGroup);
}

- (void) wait {
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
}


@end
