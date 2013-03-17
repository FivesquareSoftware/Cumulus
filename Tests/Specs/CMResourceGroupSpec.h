//
//  CMResourceGroupSpec.h
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCExampleGroup.h"

@class CMResource;

@interface CMResourceGroupSpec : OCExampleGroup {
 // add any ivars you need to store state for specs
}

// add properties as needed

@property (nonatomic, strong) CMResource *service;

@end
