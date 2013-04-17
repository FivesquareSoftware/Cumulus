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

+ (CMDownloadInfo *) downloadInfoForURL:(NSURL *)URL {
	CMDownloadInfo *info = [self downloadInfo][URL];
	if (nil == info) {
		info = [CMDownloadInfo new];
		[self downloadInfo][URL] = info;
	}
	return info;
}

+ (BOOL) resetDownloadInfoForURL:(NSURL *)URL {
	NSMutableDictionary *info = [self downloadInfo];
	[info removeObjectForKey:URL];
	return [self saveDownloadInfo];
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
	_expectedContentLength = [[coder decodeObjectForKey:@"_expectedContentLength"] longLongValue];
	_ETag = [coder decodeObjectForKey:@"_ETag"];
	_lastModifiedDate = [coder decodeObjectForKey:@"_lastModifiedDate"];
    
	return self;
}

- (void) encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:_downloadedFileTempURL forKey:@"_downloadedFileTempURL"];
	[aCoder encodeObject:@(_expectedContentLength) forKey:@"_expectedContentLength"];
	[aCoder encodeObject:_ETag forKey:@"_ETag"];
	[aCoder encodeObject:_lastModifiedDate forKey:@"_lastModifiedDate"];
}

@end
