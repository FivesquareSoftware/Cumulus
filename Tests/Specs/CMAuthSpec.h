//
//  CMAuthSpec.h
//  Cumulus
//
//  Created by John Clayton on 9/9/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCExampleGroup.h"

@class CMResource;

@interface CMAuthSpec : OCExampleGroup {

}

// add properties as needed
@property (nonatomic, strong) CMResource *service;
@property (nonatomic, strong) CMResource *SSLService;
@property (nonatomic, strong) CMResource *protectedResource;
@property (nonatomic, strong) CMResource *SSLProtectedResource;

@end
