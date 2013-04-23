//
//  CMResponseSpec.h
//  Cumulus
//
//  Created by John Clayton on 10/15/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCExampleGroup.h"

@class CMResource;

@interface CMResponseSpec : OCExampleGroup {
 // add any ivars you need to store state for specs
}

// add properties as needed
@property (nonatomic, strong) CMResource *service;
@property (nonatomic, strong) CMResource *endpoint;
@property (nonatomic) long long heroBytes;


@end
