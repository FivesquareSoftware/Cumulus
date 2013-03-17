//
//  CMResource+Specs.h
//  Cumulus
//
//  Created by John Clayton on 12/17/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResource.h"

@interface CMResource (Specs)

@property (nonatomic, readonly) NSMutableDictionary *mergedHeaders; 
@property (nonatomic, readonly) NSMutableArray *mergedAuthProviders;

@end
