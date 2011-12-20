//
//  RCAuthSpec.h
//  RESTClient
//
//  Created by John Clayton on 9/9/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "OCExampleGroup.h"

@class RCResource;

@interface RCAuthSpec : OCExampleGroup {

}

// add properties as needed
@property (nonatomic, strong) RCResource *service;
@property (nonatomic, strong) RCResource *SSLService;
@property (nonatomic, strong) RCResource *protectedResource;
@property (nonatomic, strong) RCResource *SSLProtectedResource;

@end
