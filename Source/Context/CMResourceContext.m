
//
//	CMResourceContext.m
//	Cumulus
//
//	Created by John Clayton on 8/28/12.
//	Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceContext.h"

#import "Cumulus.h"
#import "CMResourceContextGroup.h"
#import "CMResourceContextScope.h"


NSString *kCMResourceContextKey = @"kCMResourceContextKey";


@interface CMResourceContext () {
	dispatch_queue_t _dispatchQueue;
}
@property (nonatomic, strong) NSMutableDictionary *groupsByIdentifier;
@end

@implementation CMResourceContext

// ========================================================================== //

#pragma mark - Properties



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
		_groupsByIdentifier = [NSMutableDictionary new];
	}
	return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ name : %@",[super description], _name];
}


// ========================================================================== //

#pragma mark - Public


- (id) performRequestsAndWait:(void(^)())work withCompletionBlock:(void(^)(BOOL success, NSSet *responses))completionBlock {
	CMResourceContextGroup *group = [CMResourceContextGroup new];
	[_groupsByIdentifier setObject:group forKey:group.identifier];
	dispatch_async(_dispatchQueue, ^{
		dispatch_queue_set_specific(_dispatchQueue, &kCMResourceContextKey, (__bridge void *)(group), NULL);
		
		// dispatch the work, resources check their current q for a group before dispatching requests
		work(self);
		
		dispatch_queue_set_specific(_dispatchQueue, &kCMResourceContextKey, NULL, NULL);
		
		// Wait for the group to complete
		[group wait];
		
		// Collect our overall success
		BOOL success = YES;
		NSSet *responses = group.responses;
		for (CMResponse *response in responses) {
			if (success) {
				success = response.wasSuccessful;
			}
		}
		
		// Clean up group
		[_groupsByIdentifier removeObjectForKey:group.identifier];
		
		// Fire off the completion block
		dispatch_async(dispatch_get_main_queue(), ^{
			completionBlock(success,responses);
		});
	});
	return group.identifier;
}

- (void) cancelRequestsForIdentifier:(id)identifier {
	CMResourceContextGroup *group = [_groupsByIdentifier objectForKey:identifier];
	[group cancel];
}

- (void) cancelAllRequests {
	[_groupsByIdentifier enumerateKeysAndObjectsUsingBlock:^(id key, CMResourceContextGroup *group, BOOL *stop) {
		[group cancel];
	}];
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

