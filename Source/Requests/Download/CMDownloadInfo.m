//
//  CMDownloadInfo.m
//  Cumulus
//
//  Created by John Clayton on 4/16/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMDownloadInfo.h"

#import "Cumulus.h"

static dispatch_semaphore_t _downloadInfoSemphore = nil;

/// Private, bitches
static NSMutableDictionary *_downloadInfo = nil;

@implementation CMDownloadInfo

+ (void) initialize {
	@autoreleasepool {
		if (self == [CMDownloadInfo class]) {
			_downloadInfoSemphore = dispatch_semaphore_create(1);

			static dispatch_once_t onceToken;
			dispatch_once(&onceToken, ^{
				if (nil == _downloadInfo) {
					NSURL *stateDataURL = [self downloadInfoURL];
					NSFileManager *fm = [NSFileManager new];
					if ([fm fileExistsAtPath:[stateDataURL path]]) {
						@try {
							_downloadInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:[stateDataURL path]];
						}
						@catch (NSException *exception) {
							RCLog(@"Exception while unarchiving download data: %@",exception);
						}
						NSAssert(_downloadInfo, @"Could not load state data from URL %@",stateDataURL);
					}					
					if (nil == _downloadInfo) {
						_downloadInfo = [NSMutableDictionary new];
					}
				}

			});
		}
	}
}

+ (NSURL *) downloadInfoURL {
	NSURL *downloadInfoURL = [[NSURL fileURLWithPath:[Cumulus cachesDir]] URLByAppendingPathComponent:@"Downloads.plist"];
	return downloadInfoURL;
}

+ (NSMutableDictionary *) downloadInfo {
	return _downloadInfo;
}

+ (CMDownloadInfo *) downloadInfoForCacheIdentifier:(id)identifier {
	dispatch_semaphore_wait(_downloadInfoSemphore, DISPATCH_TIME_FOREVER);
	CMDownloadInfo *info = [self downloadInfo][identifier];
	if (nil == info) {
		info = [CMDownloadInfo new];
		[self downloadInfo][identifier] = info;
	}
	dispatch_semaphore_signal(_downloadInfoSemphore);
	return info;
}

+ (void) resetDownloadInfoForCacheIdentifier:(id)identifier {
	dispatch_semaphore_wait(_downloadInfoSemphore, DISPATCH_TIME_FOREVER);
	NSMutableDictionary *info = [self downloadInfo];
	if ([info objectForKey:identifier]) {
		[info removeObjectForKey:identifier];
	}
	dispatch_semaphore_signal(_downloadInfoSemphore);
}

+ (BOOL) saveDownloadInfo {
	NSURL *stateDataURL = [self downloadInfoURL];
	
	BOOL success = NO;
	@try {
		dispatch_semaphore_wait(_downloadInfoSemphore, DISPATCH_TIME_FOREVER);
		success = [NSKeyedArchiver archiveRootObject:_downloadInfo toFile:[stateDataURL path]];
		dispatch_semaphore_signal(_downloadInfoSemphore);
	}
	@catch (NSException *exception) {
		RCLog(@"Exception while archiving download data: %@",exception);
	}

//	NSAssert(success, @"Failed to write download state!");
	return success;
}

- (id)initWithCoder:(NSCoder *)coder {
	_downloadedFileTempURL = [coder decodeObjectForKey:@"_downloadedFileTempURL"];
	_totalContentLength = [[coder decodeObjectForKey:@"_totalContentLength"] longLongValue];
	_ETag = [coder decodeObjectForKey:@"_ETag"];
	_lastModifiedDate = [coder decodeObjectForKey:@"_lastModifiedDate"];
    
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_downloadedFileTempURL forKey:@"_downloadedFileTempURL"];
	[aCoder encodeObject:@(_totalContentLength) forKey:@"_totalContentLength"];
	[aCoder encodeObject:_ETag forKey:@"_ETag"];
	[aCoder encodeObject:_lastModifiedDate forKey:@"_lastModifiedDate"];
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ { tempURL:%@, totalContentLength: %@, ETag: %@, lastModifiedDate: %@ }",[super description],_downloadedFileTempURL,@(_totalContentLength),_ETag,_lastModifiedDate];
}

@end
