//
//  RCResource+Specs.h
//  RESTClient
//
//  Created by John Clayton on 12/17/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCResource.h"

@interface RCResource (Specs)

@property (nonatomic, readonly) NSMutableDictionary *mergedHeaders; 
@property (nonatomic, readonly) NSMutableArray *mergedAuthProviders;

@end
