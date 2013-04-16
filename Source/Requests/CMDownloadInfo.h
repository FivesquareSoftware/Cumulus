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
+ (CMDownloadInfo *) downloadInfoForURL:(NSURL *)URL;
+ (BOOL) resetDownloadInfoForURL:(NSURL *)URL;
+ (BOOL) saveDownloadInfo;


@property (nonatomic, strong) NSURL *downloadedFileTempURL;
@property (nonatomic) long long expectedContentLength;
@property (nonatomic, strong) NSString *ETag;
@property (nonatomic, strong) NSString *lastModifiedDate;

@end
