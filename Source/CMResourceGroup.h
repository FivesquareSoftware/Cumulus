//
//  CMResourceGroup.h
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMResource;

@interface CMResourceGroup : NSObject

@property (nonatomic, strong) NSString *name;


+ (id) withName:(NSString *)name;

/** Submits a block of work to the receiver's private serial queue. The array of all response objects from requests launched during the block is collected and passed to the completion block, along with a summary of group success/failure. 
 */
- (void) performWork:(void(^)(CMResourceGroup *group))groupWork withCompletionBlock:(void(^)(BOOL success, NSArray *responses))completionBlock;

@end
