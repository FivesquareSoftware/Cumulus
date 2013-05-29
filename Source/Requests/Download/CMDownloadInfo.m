//
//  CMDownloadInfo.m
//  Cumulus
//
//  Created by John Clayton on 4/16/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMDownloadInfo.h"

#import "Cumulus.h"

@implementation CMDownloadInfo

+ (NSURL *) downloadInfoURL {
	NSURL *downloadInfoURL = [[NSURL fileURLWithPath:[Cumulus cachesDir]] URLByAppendingPathComponent:@"Downloads.plist"];
	return downloadInfoURL;
}

+ (NSMutableDictionary *) downloadInfo {
	static NSMutableDictionary *_downloadInfo = nil;
	if (nil == _downloadInfo) {
		NSURL *stateDataURL = [self downloadInfoURL];
		NSFileManager *fm = [NSFileManager new];
		if ([fm fileExistsAtPath:[stateDataURL path]]) {
			NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
			__block NSError *error = nil;
			[coordinator coordinateReadingItemAtURL:stateDataURL options:NSFileCoordinatorReadingWithoutChanges error:&error byAccessor:^(NSURL *newURL) {
				@try {
					_downloadInfo = [NSKeyedUnarchiver unarchiveObjectWithFile:[stateDataURL path]];
				}
				@catch (NSException *exception) {
					RCLog(@"Exception while unarchiving download data: %@",exception);
				}
			}];
			NSAssert2(_downloadInfo || error == nil, @"Could not load state data from URL %@ (%@)",stateDataURL,error);
		}
		
		if (nil == _downloadInfo) {
			_downloadInfo = [NSMutableDictionary new];
		}
	}
	return _downloadInfo;
}

+ (CMDownloadInfo *) downloadInfoForCacheIdentifier:(id)identifier {
	CMDownloadInfo *info = [self downloadInfo][identifier];
	if (nil == info) {
		info = [CMDownloadInfo new];
		[self downloadInfo][identifier] = info;
	}
	return info;
}

+ (BOOL) resetDownloadInfoForCacheIdentifier:(id)identifier {
	NSMutableDictionary *info = [self downloadInfo];
	if ([info objectForKey:identifier]) {
		[info removeObjectForKey:identifier];
		return [self saveDownloadInfo];
	}
	return YES;
}

+ (BOOL) saveDownloadInfo {
	NSURL *stateDataURL = [self downloadInfoURL];
	
	NSFileCoordinator *coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
	__block NSError *error = nil;
	__block BOOL success = NO;
	[coordinator coordinateWritingItemAtURL:stateDataURL options:NSFileCoordinatorWritingForReplacing error:&error byAccessor:^(NSURL *newURL) {
		@try {
			success = [NSKeyedArchiver archiveRootObject:[self downloadInfo] toFile:[[self downloadInfoURL] path]];
		}
		@catch (NSException *exception) {
			RCLog(@"Exception while archiving download data: %@",exception);
		}

	}];
	
	NSAssert1(success, @"Failed to write download state! %@",error);
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
