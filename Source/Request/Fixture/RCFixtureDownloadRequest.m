//
//  RCFixtureDownloadRequest.m
//  RESTClient
//
//  Created by John Clayton on 5/4/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCFixtureDownloadRequest.h"
#import "RCRequest+Protected.h"

#import "RESTClient.h"
#import "RCFixtureHTTPResponse.h"

@interface RCFixtureDownloadRequest ()
@property (nonatomic, readonly) NSURL *downloadedFileTempURL;
@end

@implementation RCFixtureDownloadRequest

@synthesize expectedContentType=expectedContentType_;
@synthesize downloadedFileTempURL=downloadedFileTempURL_;


- (NSURL *) downloadedFileTempURL {
	if (downloadedFileTempURL_ == nil) {
		CFUUIDRef UUID = CFUUIDCreate(NULL);
		NSString *tempFilename = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, UUID);
		CFRelease(UUID);
		
		NSString *filePath = [[RESTClient cachesDir] stringByAppendingPathComponent:tempFilename];
		
		downloadedFileTempURL_ = [NSURL fileURLWithPath:filePath];
	}
	return downloadedFileTempURL_;
}


- (void) start {
	NSAssert(NO == self.started, @"Attempting to start a request that has already been started, canceled or finished");
	if (NO == self.canStart) {
		return;
	}
	
    self.started = YES;
	
	RCLog(@"%@", self);
	
	[self handleConnectionDidSendData];
	[self handleConnectionDidReceiveData];
	
	
	if (self.timeout > 0) {
		NSTimer *timeoutTimer = [NSTimer timerWithTimeInterval:self.timeout target:self selector:@selector(timeoutFired:) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:timeoutTimer forMode:NSDefaultRunLoopMode];		
		self.timeoutTimer = timeoutTimer;
	}	
	
//	[self.data appendData:self.fixtureData];
	
	
	id fakeResponse = [[RCFixtureHTTPResponse alloc] initWithURL:[self.URLRequest URL] MIMEType:expectedContentType_ expectedContentLength:(NSInteger)[self.data length] textEncodingName:@"NSUTF8StringEncoding"];
	[fakeResponse setStatusCode:200];
	if (expectedContentType_) {
		[fakeResponse setAllHeaderFields:[NSDictionary dictionaryWithObject:expectedContentType_ forKey:kRESTClientHTTPHeaderContentType]];
	}
	self.URLResponse = fakeResponse;
	
	self.expectedContentLength = [self.data length];
	self.receivedContentLength = [self.data length];
	
	NSError *writeError= nil;
	NSFileManager *fm = [[NSFileManager alloc] init];
	if (NO == [fm fileExistsAtPath:[self.downloadedFileTempURL path]]) {
		if (NO == [self.fixtureData writeToURL:self.downloadedFileTempURL options:NSDataWritingAtomic error:&writeError]) {
			RCLog(@"Could not write to downloaded file URL: %@ (%@)", [writeError localizedDescription],[writeError userInfo]);
			self.error = writeError;
			[self handleConnectionFinished];
		}
	}

	RCProgressInfo *progressInfo = [RCProgressInfo new];
	progressInfo.progress = [NSNumber numberWithFloat:1.f];
	progressInfo.tempFileURL = self.downloadedFileTempURL;
	progressInfo.URL = [self.URLRequest URL];
	progressInfo.filename = [self.downloadedFileTempURL lastPathComponent];
	
	self.result = progressInfo;

	
	[self handleConnectionFinished];
}

@end
