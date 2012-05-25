//
//  RCFixtureDownloadRequest.h
//  RESTClient
//
//  Created by John Clayton on 5/4/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCDownloadRequest.h"

#import "RCFixtureRequest.h"

@interface RCFixtureDownloadRequest : RCFixtureRequest

@property (nonatomic, strong) NSString *cachesDir; ///< The path to a subdirectory of NSCachesDirectory where direct to disk file downloads will be temporarily located.

@end
