//
//  CMResourceContextGroup.h
//  Cumulus
//
//  Created by John Clayton on 5/6/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CMResponse;
@class CMRequest;

@interface CMResourceContextGroup : NSObject

@property (nonatomic, copy) id identifier;
@property (readonly) BOOL wasCanceled;
@property (nonatomic, readonly) NSSet *runningRequests;
@property (nonatomic, readonly) NSSet *responses;

- (void) enterWithRequest:(CMRequest *)request;
- (void) leaveWithResponse:(CMResponse *)response;
- (void) wait;
- (void) cancel;

@end
