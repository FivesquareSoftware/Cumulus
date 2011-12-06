//
//  RCBenchmarksSpec.h
//  RESTClient
//
//  Created by John Clayton on 11/27/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCExampleGroup.h"

@class RCResource;

@interface RCBenchmarksSpec : OCExampleGroup {
 // add any ivars you need to store state for specs
}

// add properties as needed

@property (nonatomic, strong) RCResource *service;
@property (nonatomic, strong) RCResource *benchmarks;

@property (strong) NSArray *largeList;
@property (strong) NSArray *complicatedList;

@end
