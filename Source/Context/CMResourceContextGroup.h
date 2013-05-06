//
//  CMResourceContextGroup.h
//  Cumulus
//
//  Created by John Clayton on 5/6/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMResponse;

@interface CMResourceContextGroup : NSObject

@property (nonatomic, copy) id identifier;
@property (nonatomic, readonly) NSSet *responses;

- (void) enter;
- (void) leaveWithResponse:(CMResponse *)response;
- (void) wait;

@end
