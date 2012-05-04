//
//  RCFixtureSpec.h
//  RESTClient
//
//  Created by John Clayton on 5/3/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCExampleGroup.h"

@class RCResource;

@interface RCFixtureSpec : OCExampleGroup {
 // add any ivars you need to store state for specs
}

// add properties as needed

@property (nonatomic, strong) RCResource *service;

@end
