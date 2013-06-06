//
//  CMProgressInfo.m
//  Cumulus
//
//  Created by John Clayton on 5/2/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMProgressInfo.h"

@implementation CMProgressInfo

@synthesize request = _request;
@synthesize URL=_URL;
@synthesize tempFileURL=_tempFileURL;
@synthesize filename=_filename;
@synthesize elapsedTime = _elapsedTime;
@synthesize progress=_progress;
@synthesize contentLength = _contentLength;
@synthesize fileOffset = _fileOffset;
@synthesize chunkSize = _chunkSize;
@synthesize bytesPerSecond = _bytesPerSecond;


- (NSTimeInterval) timeRemaining {
	NSTimeInterval timeRemaining = 0;
	if (_bytesPerSecond > 0) {
		timeRemaining = ( (double)([_contentLength longLongValue]-[_fileOffset longLongValue]) / [_bytesPerSecond doubleValue] );
	}	
	return timeRemaining;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ { URL: %@, elapsedTime: %@, progress: %@, chunk: %@, fileOffset: %@, bytesPerSecond: %@, timeRemaining: %@ }",[super description],_URL,_elapsedTime,_progress,_chunkSize,_fileOffset,_bytesPerSecond,@(self.timeRemaining)];
}

@end
