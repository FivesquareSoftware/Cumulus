//
//  SpecHelper.h
//  JSONClient
//
//  Created by John Clayton on 9/10/2009.
//  Copyright 2009 Fivesquare Software, LLC. All rights reserved.
//


#import <Foundation/Foundation.h>


#import "RESTClient.h"

extern NSString *kTestServerHost;

@interface SpecHelper : NSObject 

@property (readonly, strong) NSDictionary *item;
@property (readonly, strong) NSArray *list;
@property (readonly, strong) NSArray *largeList;
@property (readonly, strong) NSArray *complicatedList;

- (void) cleanCaches;

@end
