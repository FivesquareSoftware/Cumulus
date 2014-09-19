//
//	CMFixtureDownloadRequest.m
//	Cumulus
//
//	Created by John Clayton on 5/4/12.
//	Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMFixtureDownloadRequest.h"
#import "CMRequest+Protected.h"

#import "Cumulus.h"
#import "CMFixtureHTTPResponse.h"

// Allow access to the private timeout method in the CMRequest base class
@interface CMRequest ()
- (void) timeoutFired:(NSTimer *)timer;
@end


@interface CMFixtureDownloadRequest ()
@property (nonatomic, readonly) NSURL *downloadedFileTempURL;
@end

@implementation CMFixtureDownloadRequest

// Public

@synthesize cachesDir=_cachesDir;
@synthesize shouldResume = _shouldResume;

// Private

@synthesize expectedContentType=_expectedContentType;


@synthesize downloadedFileTempURL=_downloadedFileTempURL;
- (NSURL *) downloadedFileTempURL {
	if (_downloadedFileTempURL == nil) {
		CFUUIDRef UUID = CFUUIDCreate(NULL);
		NSString *tempFilename = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, UUID);
		CFRelease(UUID);
		
		NSString *filePath = [self.cachesDir stringByAppendingPathComponent:tempFilename];
		
		_downloadedFileTempURL = [NSURL fileURLWithPath:filePath];
	}
	return _downloadedFileTempURL;
}



// ========================================================================== //

#pragma mark - CMRequest

- (void) handleConnectionWillStart {
	NSAssert(self.cachesDir && self.cachesDir.length, @"Attempted a download with setting cachesDir!");
	NSFileManager *fm = [NSFileManager new];
	if (NO == [fm fileExistsAtPath:self.cachesDir]) {
		NSError *error = nil;
		if (NO == [fm createDirectoryAtPath:self.cachesDir withIntermediateDirectories:YES attributes:nil error:&error]) {
			CMLog(@"Could not create cachesDir: %@ %@ (%@)", self.cachesDir, [error localizedDescription], [error userInfo]);
		}
	}
	[CMRequest incrementRequestCountFor:self];
}

- (BOOL) start {
	NSAssert(NO == self.started, @"Attempting to start a request that has already been started, canceled or finished");
	if (NO == self.canStart) {
		return NO;
	}
	
	[self handleConnectionWillStart];
	
	self.started = YES;
	
	CMLog(@"%@", self);
	
	[self handleConnectionDidSendData];
	[self handleConnectionDidReceiveData];
	
	
	if (self.timeout > 0) {
		NSTimer *timeoutTimer = [NSTimer timerWithTimeInterval:self.timeout target:self selector:@selector(timeoutFired:) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:timeoutTimer forMode:NSDefaultRunLoopMode];
		self.timeoutTimer = timeoutTimer;
	}
	
	id fakeResponse = [[CMFixtureHTTPResponse alloc] initWithURL:[self.URLRequest URL] MIMEType:_expectedContentType expectedContentLength:(NSInteger)[self.data length] textEncodingName:@"NSUTF8StringEncoding"];
	[fakeResponse setStatusCode:200];
	if (_expectedContentType) {
		[fakeResponse setAllHeaderFields:[NSDictionary dictionaryWithObject:_expectedContentType forKey:kCumulusHTTPHeaderContentType]];
	}
	self.URLResponse = fakeResponse;
	
	
	
	NSError *writeError= nil;
	NSFileManager *fm = [[NSFileManager alloc] init];
	
	// If  fixture is a URL we're just going to copy the file over, not load it into memory, to more closely mimic how a real download request works
	
	if ([self.fixture isKindOfClass:[NSURL class]] && [self.fixture isFileURL]) {
		// set expected length from file
		// set type from file
		//copy file over from URL
		NSURL *fixtureURL = self.fixture;
		NSString *fixturePath = [fixtureURL path];
		
		// Get attributes, if we can't assume we need to bail
		NSDictionary *fixtureAttributes = [fm attributesOfItemAtPath:fixturePath error:&writeError];
		if (writeError) {
			CMLog(@"Could not read attributes of fixture at URL: %@ %@ (%@)", fixtureURL, [writeError localizedDescription],[writeError userInfo]);
			self.error = writeError;
			[self handleConnectionFinished];
			return YES;
		}
		
		NSString *MIMEType = [self mimeTypeForFileAtPath:fixturePath];
		_expectedContentType = MIMEType;
		
		self.expectedContentLength = [fixtureAttributes fileSize];
		
		if (NO == [fm copyItemAtURL:fixtureURL toURL:self.downloadedFileTempURL error:&writeError]) {
			CMLog(@"Could not write to downloaded file URL: %@ (%@)", [writeError localizedDescription],[writeError userInfo]);
			self.error = writeError;
			[self handleConnectionFinished];
			return YES;
		}
	}
	else {
		self.expectedContentLength = [self.fixtureData length];
		
		if (NO == [fm fileExistsAtPath:[self.downloadedFileTempURL path]]) {
			if (NO == [self.fixtureData writeToURL:self.downloadedFileTempURL options:NSDataWritingAtomic error:&writeError]) {
				CMLog(@"Could not write to downloaded file URL: %@ (%@)", [writeError localizedDescription],[writeError userInfo]);
				self.error = writeError;
				[self handleConnectionFinished];
				return YES;
			}
		}
	}
	
	// Send fake progress updates
	for (int i = 1; i < 49; i ++) {
		[NSThread sleepForTimeInterval:.1];
		self.receivedContentLength = (self.expectedContentLength * ((float)i/50.f));
		[self handleConnectionDidReceiveData];
	}
	
	
	
	self.receivedContentLength = self.expectedContentLength;
	[self handleConnectionDidReceiveData];
	
	CMProgressInfo *progressInfo = [CMProgressInfo new];
	progressInfo.progress = [NSNumber numberWithFloat:1.f];
	progressInfo.tempFileURL = self.downloadedFileTempURL;
	progressInfo.URL = [self.URLRequest URL];
	progressInfo.filename = [self.downloadedFileTempURL lastPathComponent];
	
	self.result = progressInfo;
	
	
	[self handleConnectionFinished];
	
	// Remove the file on the main Q so we know the completion block has had a chance to run
	dispatch_async(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		if (NO == [fm removeItemAtURL:self.downloadedFileTempURL error:&error]) {
			CMLog(@"Could not remove temp file: %@ %@ (%@)", self.downloadedFileTempURL, [error localizedDescription], [error userInfo]);
		}
	});
	
	return YES;
	
}

@end
