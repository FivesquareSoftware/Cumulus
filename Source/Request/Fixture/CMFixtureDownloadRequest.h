//
//  CMFixtureDownloadRequest.h
//  Cumulus
//
//  Created by John Clayton on 5/4/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMDownloadRequest.h"

#import "CMFixtureRequest.h"

@interface CMFixtureDownloadRequest : CMFixtureRequest

@property (nonatomic, strong) NSString *cachesDir; ///< The path to a subdirectory of NSCachesDirectory where direct to disk file downloads will be temporarily located.

@end
