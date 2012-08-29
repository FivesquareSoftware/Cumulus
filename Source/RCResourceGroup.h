//
//  RCResourceGroup.h
//  RESTClient
//
//  Created by John Clayton on 8/28/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RCResource;

@interface RCResourceGroup : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, readonly) NSSet *resources;
@property (nonatomic, readonly) NSSet *completionBlocks;
@property (nonatomic) BOOL clearsBlocksOnCompletion; ///< When YES, after a mark is hit, all current completion blocks are removed after being invoked

+ (id) withCompletionBlock:(void(^)())completionBlock;

- (void) addResource:(RCResource *)resource; ///< The resource's requests will now be tracked by the receiver
- (void) addCompletionBlock:(void(^)())completionBlock;


/** Begins waiting for completion of currently scheduled requests. Safe to call repeatedly, but the blocks will be invoked once for every mar unless #clearsBlocksOnCompletion = YES. */
- (void) mark;
- (void) markAfterDelay:(NSTimeInterval)delay; ///< calls #mark after a delay, useful if you are firing a lot of requests rapidly and need to give them a chance to launch before marking

@end
