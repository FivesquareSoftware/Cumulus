
//
//  CMResourceGroup.m
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceGroup.h"
#import "CMResourceGroup+Protected.h"
#import "CMResource+Protected.h"

#import "Cumulus.h"

@interface CMResourceGroup ()
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@property (nonatomic, assign) dispatch_group_t dispatchGroup;
@property (nonatomic, strong) NSMutableArray *currentResponses;
@end

@implementation CMResourceGroup 

// ========================================================================== //

#pragma mark - Properties

@synthesize name = _name;
@synthesize dispatchQueue = _dispatchQueue;
@synthesize dispatchGroup = _dispatchGroup;


// ========================================================================== //

#pragma mark - Object

- (void)dealloc {
	dispatch_set_context(_dispatchQueue, NULL);
	dispatch_release(_dispatchQueue);
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    dispatch_release(_dispatchGroup);
}

+ (id) withName:(NSString *)name {
	return [[self alloc] initWithName:name];
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
		_name = name;
		_dispatchQueue = dispatch_queue_create("com.fivesquaresoftware.Cumulus.CMResourceGroup", DISPATCH_QUEUE_SERIAL);
		dispatch_set_context(_dispatchQueue, (__bridge void *)(self));
		_dispatchGroup = dispatch_group_create();
		_currentResponses = [NSMutableArray new];
    }
    return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ name : %@",[super description], _name];
}


// ========================================================================== //

#pragma mark - Public


- (void) performWork:(void(^)(CMResourceGroup *group))groupWork withCompletionBlock:(void(^)(BOOL success, NSArray *responses))completionBlock {
	dispatch_async(_dispatchQueue, ^{
		// Clear the responses and dispatch the current work block
		[_currentResponses removeAllObjects];

		// dispatch the work, resources check their current q for a group before dispatching requests
		groupWork(self);
		
		// Wait for the group to complete
		dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
		
		// Collect our success rate
		__block BOOL success = YES;
		[_currentResponses enumerateObjectsUsingBlock:^(CMResponse *response, NSUInteger idx, BOOL *stop) {
			if (success) {
				success = response.success;
			}
		}];
		
		// Fire off the completion block
		dispatch_async(dispatch_get_main_queue(), ^{
			 completionBlock(success,_currentResponses);
		});

	});
	
}

// ========================================================================== //

#pragma mark - Protected


- (void) enter {
	RCLog(@"enter ->");
	dispatch_group_enter(_dispatchGroup);
}

- (void) leaveWithResponse:(CMResponse *)response {
	RCLog(@"leaveWithResponse: ->");
	if (response) {
		[_currentResponses addObject:response];
	}
	dispatch_group_leave(_dispatchGroup);
}



@end
