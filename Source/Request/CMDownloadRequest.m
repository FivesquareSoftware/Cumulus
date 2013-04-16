//
//  CMDownloadRequest.m
//  Cumulus
//
//  Created by John Clayton on 11/20/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

/*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * 3. Neither the name of Fivesquare Software nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CMDownloadRequest.h"
#import "CMRequest+Protected.h"

#import "Cumulus.h"

#define BROKEN_DOWNLOAD_DELEGATE 1 // rdar: 10475830

NSString *kDownloadStateInfoKeyTempFileURL = @"downloadedFileTempURL";
NSString *kDownloadStateInfoKeyExpectedContentLength = @"expectedContentLength";
NSString *kDownloadStateInfoKeyETag = @"ETag";
NSString *kDownloadStateInfoKeyLastModifiedDate = @"lastModifiedDate";

@interface CMDownloadRequest()
@property (copy) NSURL *downloadedFileTempURL;
@property (copy) NSString *downloadedFilename;
@property (nonatomic) NSURL *downloadStateURL;
@property (nonatomic, readonly) NSMutableDictionary *downloadStateInfo;
@end


@implementation CMDownloadRequest


// Public

@synthesize cachesDir=_cachesDir;
@synthesize shouldResume = _shouldResume;

// Private

@synthesize downloadedFileTempURL=_downloadedFileTempURL;
@synthesize downloadedFilename=_downloadedFilename;

@dynamic downloadStateURL;
- (NSURL *) downloadStateURL {
	NSURL *downloadStateURL = [[NSURL fileURLWithPath:[Cumulus cachesDir]] URLByAppendingPathComponent:@"Downloads.state"];
	NSAssert(downloadStateURL, @"Could not get URL to download state data!");
	return downloadStateURL;
}

@synthesize downloadStateInfo = _downloadStateInfo;
- (NSMutableDictionary *) downloadStateInfo {
	if (nil == _downloadStateInfo) {
		NSURL *stateDataURL = [self downloadStateURL];
		if (stateDataURL) {
//			NSInputStream *inputStream = [NSInputStream inputStreamWithURL:stateDataURL];
//			[inputStream open];
//			if ([inputStream hasBytesAvailable]) {
			NSData *stateData = [NSData dataWithContentsOfURL:stateDataURL];
			if ([stateData length] > 0) {
				NSError *error = nil;
//				NSMutableDictionary *state = [NSPropertyListSerialization propertyListWithStream:inputStream options:NSPropertyListMutableContainersAndLeaves format:NULL error:&error];
				NSMutableDictionary *state = [NSPropertyListSerialization propertyListWithData:stateData options:NSPropertyListMutableContainersAndLeaves format:NULL error:&error];
				NSAssert2(state || error == nil, @"Could not load state data from URL %@ (%@)",stateDataURL,error);
				_downloadStateInfo = state;
			}
//			[inputStream close];
			if (nil == _downloadStateInfo) {
				_downloadStateInfo = [NSMutableDictionary new];
			}
		}
	}
	return _downloadStateInfo;
}

- (NSMutableDictionary *) downloadStateForURL:(NSURL *)URL {
	NSMutableDictionary *state = self.downloadStateInfo[[self.URLRequest.URL absoluteString]];
	if (nil == state) {
		state = [NSMutableDictionary new];
		self.downloadStateInfo[[URL absoluteString]] = state;
	}
	return state;
}

- (BOOL) saveDownloadState {
	NSError *error = nil;
	NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:self.downloadStateURL append:NO];
	[outputStream open];
	BOOL success = [NSPropertyListSerialization writePropertyList:self.downloadStateInfo toStream:outputStream format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
	[outputStream close];
	NSAssert1(success, @"Failed to write download state! %@",error);
	return success;
//	return [self.downloadStateInfo writeToURL:self.downloadStateURL atomically:YES];
}

- (BOOL) resetDownloadStateForURL:(NSURL *)URL {
	NSMutableDictionary *state = self.downloadStateInfo;
	[state removeObjectForKey:URL];
	return [self saveDownloadState];
}

- (CMProgressInfo *) progressReceivedInfo {
	CMProgressInfo *progressInfo = [super progressReceivedInfo];
	progressInfo.tempFileURL = self.downloadedFileTempURL;
	return progressInfo;
}


// ========================================================================== //

#pragma mark - CMRequest

- (void) handleConnectionWillStart {
	NSAssert(self.cachesDir && self.cachesDir.length, @"Attempted a download without setting cachesDir!");
	NSFileManager *fm = [NSFileManager new];
	if (NO == [fm fileExistsAtPath:self.cachesDir]) {
		NSError *error = nil;
		if (NO == [fm createDirectoryAtPath:self.cachesDir withIntermediateDirectories:YES attributes:nil error:&error]) {
			RCLog(@"Could not create cachesDir: %@ %@ (%@)", self.cachesDir, [error localizedDescription], [error userInfo]);
		}
	}
	BOOL canResume = NO;
	if (_shouldResume) {
		NSDictionary *stateInfo = [self downloadStateForURL:self.URLRequest.URL];
		long long expectedContentLength = [stateInfo[kDownloadStateInfoKeyExpectedContentLength] longLongValue];
		NSString *ETag = stateInfo[kDownloadStateInfoKeyETag];
		NSString *lastModifiedDate = stateInfo[kDownloadStateInfoKeyLastModifiedDate];
		if (expectedContentLength > 0) {
			NSURL *tempFileURL = [NSURL URLWithString:stateInfo[kDownloadStateInfoKeyTempFileURL]];
			if (tempFileURL) {
				NSFileManager *fm = [NSFileManager new];
				if ([fm fileExistsAtPath:[tempFileURL path]]) {
					NSError *error = nil;
					NSDictionary *attributes = [fm attributesOfItemAtPath:[tempFileURL path] error:&error];
					long long currentOffset = [attributes fileSize];
					if (ETag.length > 0 || lastModifiedDate) {
						[self.URLRequest addValue:[NSString stringWithFormat:@"bytes=%@-",@(currentOffset)] forHTTPHeaderField:kCumulusHTTPHeaderIfRange];
						if (ETag.length) {
							[self.URLRequest addValue:ETag forHTTPHeaderField:kCumulusHTTPHeaderETag];
						}
						else {
							[self.URLRequest addValue:lastModifiedDate forHTTPHeaderField:kCumulusHTTPHeaderLastModified];
						}
					}
					else {
						[self.URLRequest addValue:[NSString stringWithFormat:@"bytes=%@-",@(currentOffset)] forHTTPHeaderField:kCumulusHTTPHeaderRange];
					}
					canResume = YES;
				}
			}
		}
	}
	_shouldResume = canResume;
}

- (void) handleConnectionFinished {
	CMProgressInfo *progressInfo = [CMProgressInfo new];
	progressInfo.progress = [NSNumber numberWithFloat:1.f];
	progressInfo.tempFileURL = self.downloadedFileTempURL;
	progressInfo.URL = [self.URLRequest URL];
	progressInfo.filename = self.downloadedFilename;
	
	self.result = progressInfo;
	[super handleConnectionFinished];

	if (self.didComplete) {
		[self resetDownloadStateForURL:self.URLRequest.URL];
		// Remove the file on the main Q so we know the completion block has had a chance to run
		dispatch_async(dispatch_get_main_queue(), ^{
			NSFileManager *fm = [NSFileManager new];
			NSError *error = nil;
			if (NO == [fm removeItemAtURL:self.downloadedFileTempURL error:&error]) {
				RCLog(@"Could not remove temp file: %@ %@ (%@)", self.downloadedFileTempURL, [error localizedDescription], [error userInfo]);
			}
		});
	}
}

// ========================================================================== //

#pragma mark - NSURLConnectionDataDelegate


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[super connection:connection didReceiveResponse:response];
#if BROKEN_DOWNLOAD_DELEGATE
	// If the delegate calls are broken (do not actually point to a valid file on download) then we need to create a filename ourselves and use that
	NSString *filename = nil;
	NSDictionary *responseHeaders = [self.URLResponse allHeaderFields];
	NSString *contentDisposition = [responseHeaders objectForKey:@"Content-Disposition"];
	if (contentDisposition.length) {
		NSRange filenameRange = [contentDisposition rangeOfString:@"filename="];
		if (filenameRange.location != NSNotFound) {
			filename = [contentDisposition substringFromIndex:filenameRange.location+filenameRange.length];
			filename = [filename stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\""]];
			self.downloadedFilename = filename;
		}		
	}

	CFUUIDRef UUID = CFUUIDCreate(NULL);
	NSString *tempFilename = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, UUID);
	CFRelease(UUID);

	NSString *filePath = [self.cachesDir stringByAppendingPathComponent:tempFilename];
	self.downloadedFileTempURL = [NSURL fileURLWithPath:filePath];

	// Record state for possible future resumes
	NSMutableDictionary *state = [self downloadStateForURL:self.URLRequest.URL];
	state[kDownloadStateInfoKeyExpectedContentLength] = @(self.expectedContentLength);
	state[kDownloadStateInfoKeyTempFileURL] = [_downloadedFileTempURL absoluteString];
	NSString *ETag = [responseHeaders valueForKey:kCumulusHTTPHeaderETag];
	if (ETag) {
		state[kDownloadStateInfoKeyETag] = ETag;
	}
	NSString *lastModified = [responseHeaders valueForKey:kCumulusHTTPHeaderLastModified];
	if (lastModified) {
		state[kDownloadStateInfoKeyLastModifiedDate] = lastModified;
	}
	[self saveDownloadState];
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
#if BROKEN_DOWNLOAD_DELEGATE
	// When delegate calls are broken we have to write the data to the file ourselves
	NSError *writeError = nil;

	NSFileManager *fm = [[NSFileManager alloc] init];
	BOOL isFirstChunk = self.receivedContentLength == 0;
	if (NO == [fm fileExistsAtPath:[self.downloadedFileTempURL path]] || (isFirstChunk && NO == _shouldResume)) {
		if (NO == [data writeToURL:self.downloadedFileTempURL options:NSDataWritingAtomic error:&writeError]) {
			RCLog(@"Could not write to downloaded file URL: %@ (%@)", [writeError localizedDescription],[writeError userInfo]);
			self.error = writeError;
			[self handleConnectionFinished];
			return;
		}
	}
	else {
		NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingURL:self.downloadedFileTempURL error:&writeError];
		if (fh) {
			[fh seekToEndOfFile];
			[fh writeData:data];
			[fh closeFile];
		}
		else {
			RCLog(@"Could not get filehandle for writing to downloaded file URL: %@ (%@)", [writeError localizedDescription],[writeError userInfo]);
			self.error = writeError;
			[self handleConnectionFinished];
		}
	}
	NSUInteger dataLength = [data length];
	self.receivedContentLength += dataLength;
	[super handleConnectionDidReceiveData];
#endif	
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
#if BROKEN_DOWNLOAD_DELEGATE
	// we need to finish the connection from here when the download delegate is broken
	[self handleConnectionFinished];
#else
	// we complete our connection in connectionDidFinishDownloading:
#endif
}


#if !BROKEN_DOWNLOAD_DELEGATE

// ========================================================================== //

#pragma mark - NSURLConnectionDownloadDelegate

- (void)connection:(NSURLConnection *)connection didWriteData:(long long)bytesWritten totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes {
	self.expectedContentLength = expectedTotalBytes;
	self.receivedContentLength = totalBytesWritten;
	[self runDidReceiveDataBlock];
}

- (void)connectionDidResumeDownloading:(NSURLConnection *)connection totalBytesWritten:(long long)totalBytesWritten expectedTotalBytes:(long long) expectedTotalBytes {

}

- (void)connectionDidFinishDownloading:(NSURLConnection *)connection destinationURL:(NSURL *)destinationURL {	
	// Copy the file to a new temp location so that we can run blocks against the file which may run after this method returns (and after the OS may have removed the file)
	NSFileManager *fm = [NSFileManager new];
	NSError *moveError;
	if ([fm moveItemAtURL:destinationURL toURL:self.downloadedFileTempURL error:&moveError]) {
		RCLog(@"Could not move destination to temp file: %@ %@ (%@)", destinationURL, self.downloadedFileTempURL, [error localizedDescription], [error userInfo]);
		self.error = moveError;
	}
	[self handleConnectionFinished];
}
#endif

@end
