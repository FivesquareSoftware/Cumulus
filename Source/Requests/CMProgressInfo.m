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
@synthesize progress=_progress;
@synthesize fileOffset = _fileOffset;


- (NSString *) description {
	return [NSString stringWithFormat:@"%@ { URL: %@, progress: %@, chunk: %@, fileOffset: %@ }",[super description],_URL,_progress,_chunkSize,_fileOffset];
}

@end
