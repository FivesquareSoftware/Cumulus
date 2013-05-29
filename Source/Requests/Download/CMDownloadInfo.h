//
//  CMDownloadInfo.h
//  Cumulus
//
//  Created by John Clayton on 4/16/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMDownloadInfo : NSObject <NSCoding>

+ (NSMutableDictionary *) downloadInfo;
+ (CMDownloadInfo *) downloadInfoForCacheIdentifier:(id)identifier;
+ (BOOL) resetDownloadInfoForCacheIdentifier:(id)identifier;
+ (BOOL) saveDownloadInfo;


/// Where the file is located while it's being downloaded
@property (nonatomic, strong) NSURL *downloadedFileTempURL;
/// The total lenth of the selected content notwithstanding of any range being requested
@property (nonatomic) long long totalContentLength;
/// The ETag of the file
@property (nonatomic, strong) NSString *ETag;
/// The last modified date of the remote file
@property (nonatomic, strong) NSString *lastModifiedDate;

@end
