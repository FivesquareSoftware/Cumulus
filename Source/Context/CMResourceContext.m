
//
//  CMResourceContext.m
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceContext.h"

#import "Cumulus.h"
#import "CMResourceContextGroup.h"
#import "CMResourceContextScope.h"


NSString *kCMResourceContextKey = @"kCMResourceContextKey";


@interface CMResourceContext () {
	dispatch_queue_t _dispatchQueue;
}
@end

@implementation CMResourceContext

// ========================================================================== //

#pragma mark - Properties

@synthesize name = _name;


// ========================================================================== //

#pragma mark - Object

- (void)dealloc {
	dispatch_release(_dispatchQueue);
}

+ (id) withName:(NSString *)name {
	return [[self alloc] initWithName:name];
}

- (id)initWithName:(NSString *)name {
    self = [super init];
    if (self) {
		_name = name;
		NSString *queueName = [NSString stringWithFormat:@"com.fivesquaresoftware.Cumulus.CMResourceContext.%@.%p",_name,self];
		_dispatchQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
    }
    return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ name : %@",[super description], _name];
}


// ========================================================================== //

#pragma mark - Public


- (void) performRequestsAndWait:(void(^)())work withCompletionBlock:(void(^)(BOOL success, NSSet *responses))completionBlock {
	dispatch_async(_dispatchQueue, ^{
		CMResourceContextGroup *group = [CMResourceContextGroup new];
		dispatch_queue_set_specific(_dispatchQueue, &kCMResourceContextKey, (__bridge void *)(group), NULL);

		// dispatch the work, resources check their current q for a group before dispatching requests
		work(self);
		
		dispatch_queue_set_specific(_dispatchQueue, &kCMResourceContextKey, NULL, NULL);

		// Wait for the group to complete
		[group wait];
		
		// Collect our success rate
		__block BOOL success = YES;
		[group.responses enumerateObjectsUsingBlock:^(CMResponse *response, BOOL *stop) {
			if (success) {
				success = response.wasSuccessful;
			}
		}];
		
		// Fire off the completion block
		dispatch_async(dispatch_get_main_queue(), ^{
			 completionBlock(success,group.responses);
		});
	});	
}

- (void) performRequests:(void(^)())work inScope:(id)scope {
	__weak id weakScope = scope;
	dispatch_async(_dispatchQueue, ^{
		CMResourceContextScope *contextScope = [CMResourceContextScope withScopeObject:weakScope];
		dispatch_queue_set_specific(_dispatchQueue, &kCMResourceContextKey, (__bridge void *)(contextScope), NULL);

		// dispatch the work, resources check their current q for a scope before dispatching requests
		work(self);
		
		dispatch_queue_set_specific(_dispatchQueue, &kCMResourceContextKey, NULL, NULL);
	});
}


// ========================================================================== //

#pragma mark - Protected





@end

