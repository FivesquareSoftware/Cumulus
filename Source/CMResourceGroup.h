//
//  CMResourceGroup.h
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMResource;

/** A resource group is used to coordinate a series of requests together, dispatching a completion block with the overal status of those requests when they are finished. */
@interface CMResourceGroup : NSObject

/// Used to identify the receiver
@property (nonatomic, strong) NSString *name;


+ (id) withName:(NSString *)name;

/** Submits a block of work to the receiver's private serial queue. The array of all response objects from requests launched during the block is collected and passed to the completion block, along with a summary of group success/failure. 
 *  @param groupWork A series of requests made with CMResource objects that you wish to coordinate and get notified of on completion.
 */
- (void) performWork:(void(^)(CMResourceGroup *group))groupWork withCompletionBlock:(void(^)(BOOL success, NSArray *responses))completionBlock;

@end
