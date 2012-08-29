
//
//  RCResourceGroup.m
//  RESTClient
//
//  Created by John Clayton on 8/28/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCResourceGroup.h"
#import "RCResourceGroup+Protected.h"

#import "RESTClient.h"

@interface RCResourceGroup ()
@property (nonatomic, assign) dispatch_queue_t dispatchQueue;
@property (nonatomic, assign) dispatch_group_t dispatchGroup;
@property (nonatomic, strong) NSMutableSet *resourcesInternal;
@property (nonatomic, strong) NSMutableSet *completionBlocksInternal;
@end

@implementation RCResourceGroup 

// ========================================================================== //

#pragma mark - Properties

@synthesize name = _name;
@synthesize clearsBlocksOnCompletion = _clearsBlocksOnCompletion;

@dynamic resources;
- (NSSet *) resources {
	return [_resourcesInternal copy];
}

@dynamic completionBlocks;
- (NSSet *) completionBlocks {
	return [_completionBlocksInternal copy];
}

@synthesize dispatchQueue = _dispatchQueue;
@synthesize dispatchGroup = _dispatchGroup;
@synthesize completionBlocksInternal = _completionBlocksInternal;
@synthesize resourcesInternal = _resourcesInternal;


// ========================================================================== //

#pragma mark - Object

- (void)dealloc {
	dispatch_release(_dispatchQueue);
	dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
    dispatch_release(_dispatchGroup);
}

+ (id) withCompletionBlock:(void(^)())completionBlock {
	RCResourceGroup *group = [self new];
	if (completionBlock) {
		[group addCompletionBlock:completionBlock];
	}
	return group;
}

- (id)init {
    self = [super init];
    if (self) {
		_dispatchQueue = dispatch_queue_create("com.fivesquaresoftware.RESTClient.RCResourceGroup", DISPATCH_QUEUE_SERIAL);
		_dispatchGroup = dispatch_group_create();
		_completionBlocksInternal = [NSMutableSet new];
		_resourcesInternal = [NSMutableSet new];
		_clearsBlocksOnCompletion = YES;
    }
    return self;
}

//- (NSString *) description {
//	return [NSString stringWithFormat:@"%@ : { name : %@, resourceCount: %u, blockCount: %u }",[super description], _name,[_resourcesInternal count], [_completionBlocksInternal count]];
//}


// ========================================================================== //

#pragma mark - Public



- (void) addResource:(RCResource *)resource {
	resource.resourceGroup = self;
	[_resourcesInternal addObject:resource];
}

- (void) addCompletionBlock:(void(^)())completionBlock {
	[_completionBlocksInternal addObject:[completionBlock copy]];
}

- (void) enter {
	RCLog(@"enter ->");
	dispatch_group_enter(_dispatchGroup);
}

- (void) leave {
	RCLog(@"leave ->");
	dispatch_group_leave(_dispatchGroup);
}

- (void) mark {
	dispatch_async(_dispatchQueue, ^{
		dispatch_group_wait(_dispatchGroup, DISPATCH_TIME_FOREVER);
		RCLog(@"** run completion blocks **");
		NSSet *blocks = [_completionBlocksInternal copy];
		if (_clearsBlocksOnCompletion) {
			[_completionBlocksInternal removeAllObjects];
		}
		for (id block in blocks) {
			dispatch_async(dispatch_get_main_queue(),block);
		}
	});
}

- (void) markAfterDelay:(NSTimeInterval)delay {
	double delayInSeconds = delay;
	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
	dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
		[self mark];
	});
}

@end
