//
//  RCDownloadRequest.m
//  RESTClient
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

#import "RCDownloadRequest.h"
#import "RCRequest+Protected.h"

#import "RESTClient.h"

#define BROKEN_DOWNLOAD_DELEGATE 1 // rdar: 10475830

@interface RCDownloadRequest()
@property (copy) NSURL *downloadedFileTempURL;
@property (copy) NSString *downloadedFilename;
@end


@implementation RCDownloadRequest


// Public

@synthesize cachesDir=_cachesDir;

// Private

@synthesize downloadedFileTempURL=_downloadedFileTempURL;
@synthesize downloadedFilename=_downloadedFilename;


// ========================================================================== //

#pragma mark - RCRequest

- (void) handleConnectionWillStart {
	NSAssert(self.cachesDir && self.cachesDir.length, @"Attempted a download with setting cachesDir!");
	NSFileManager *fm = [NSFileManager new];
	if (NO == [fm fileExistsAtPath:self.cachesDir]) {
		NSError *error = nil;
		if (NO == [fm createDirectoryAtPath:self.cachesDir withIntermediateDirectories:YES attributes:nil error:&error]) {
			RCLog(@"Could not create cachesDir: %@ %@ (%@)", self.cachesDir, [error localizedDescription], [error userInfo]);
		}
	}
}




// ========================================================================== //

#pragma mark - NSURLConnectionDataDelegate


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[super connection:connection didReceiveResponse:response];
#ifdef BROKEN_DOWNLOAD_DELEGATE
	// If the delegate calls are broken (do not actually point to a valid file on download) then we need to create a filename ourselves and use that
	NSString *filename = nil;
	NSString *contentDisposition = [[(NSHTTPURLResponse *)response allHeaderFields] objectForKey:@"Content-Disposition"];
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
#endif

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
#ifdef BROKEN_DOWNLOAD_DELEGATE
	// When delegate calls are broken we have to write the data to the file ourselves
	NSError *writeError = nil;

	NSFileManager *fm = [[NSFileManager alloc] init];
	if (NO == [fm fileExistsAtPath:[self.downloadedFileTempURL path]]) {
		if (NO == [data writeToURL:self.downloadedFileTempURL options:NSDataWritingAtomic error:&writeError]) {
			RCLog(@"Could not write to downloaded file URL: %@ (%@)", [writeError localizedDescription],[writeError userInfo]);
			self.error = writeError;
			[self handleConnectionFinished];
		}
	} else {
		NSFileHandle *fh = [NSFileHandle fileHandleForUpdatingURL:self.downloadedFileTempURL error:&writeError];
		if (fh) {
			[fh seekToEndOfFile];
			[fh writeData:data];
			[fh closeFile];
		} else {
			RCLog(@"Could not get filehandle for writing to downloaded file URL: %@ (%@)", [writeError localizedDescription],[writeError userInfo]);
			self.error = writeError;
			[self handleConnectionFinished];
		}
	}
	NSUInteger dataLength = [data length];
	self.receivedContentLength += dataLength;
	[self handleConnectionDidReceiveData];
#endif	
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
#ifdef BROKEN_DOWNLOAD_DELEGATE
	// we need to finish the connection from here when the download delegate is broken
	RCProgressInfo *progressInfo = [RCProgressInfo new];
	progressInfo.progress = [NSNumber numberWithFloat:1.f];
	progressInfo.tempFileURL = self.downloadedFileTempURL;
	progressInfo.URL = [self.URLRequest URL];
	progressInfo.filename = self.downloadedFilename;

	self.result = progressInfo;
	[self handleConnectionFinished];
	
	// Remove the file on the main Q so we know the completion block has had a chance to run
	dispatch_async(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		if (NO == [fm removeItemAtURL:self.downloadedFileTempURL error:&error]) {
			RCLog(@"Could not remove temp file: %@ %@ (%@)", self.downloadedFileTempURL, [error localizedDescription], [error userInfo]);
		}
	});
#endif
	// we complete our connection in connectionDidFinishDownloading:
}


#ifndef BROKEN_DOWNLOAD_DELEGATE

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
	
	RCProgressInfo *progressInfo = [RCProgressInfo new];
	progressInfo.progress = [NSNumber numberWithFloat:1.f];
	progressInfo.tempFileURL = self.downloadedFileTempURL;
	progressInfo.URL = [self.URLRequest URL];
	progressInfo.filename = self.downloadedFilename;

	self.result = progressInfo;
	[self connectionFinished];
	
	// Remove the file on the main Q so we know the completion block has had a chance to run
	dispatch_async(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		if (NO == [fm removeItemAtURL:self.downloadedFileTempURL error:&error]) {
			RCLog(@"Could not remove temp file: %@ %@ (%@)", self.downloadedFileTempURL, [error localizedDescription], [error userInfo]);
		}
	});
}
#endif

@end
