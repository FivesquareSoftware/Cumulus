//
//  CMChunkedDownloadRequest.h
//  Cumulus
//
//  Created by John Clayton on 5/29/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CMRequest.h"

@interface CMChunkedDownloadRequest : CMRequest

@property (nonatomic, strong) NSString *cachesDir;
@property NSUInteger maxConcurrentChunks;
@property (nonatomic) long long chunkSize;

@end
