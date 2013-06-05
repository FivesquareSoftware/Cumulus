//
//  CMResourceFileHandlingSpec.m
//  Cumulus
//
//  Created by John Clayton on 11/23/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceFileHandlingSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>
#import "OCMock.h"


@interface CMRequest (Specs)
@property (nonatomic, readonly) id cacheIdentifier;
@end
@implementation CMRequest (Specs)
@dynamic cacheIdentifier;
@end



@interface CMResourceFileHandlingSpec ()
@end

@implementation CMResourceFileHandlingSpec

@synthesize service;
@synthesize downloadedFileURL;
@synthesize cachesDir;

+ (NSString *)description {
    return @"File Handling";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
	[self.specHelper cleanCaches];
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 

	self.service = [CMResource withURL:kTestServerHost];
	self.service.cachePolicy = NSURLRequestReloadIgnoringCacheData;
}

- (void)afterEach {
    // tear down resources specific to each example here
	
//	NSFileManager *fm = [[NSFileManager alloc] init];
//	__autoreleasing NSError *error = nil;
//	[fm removeItemAtURL:self.downloadedFileURL error:&error];
}

- (void)afterAll {
    // tear down common resources here
//	[self.specHelper cleanCaches];
}

// ========================================================================== //

#pragma mark - Specs

/*
- (void)shouldDownloadAFileToDisk {
	CMResource *heroDownload = [self.service resource:@"test/download/hero"];
	[self assertDownloadResourceToDisk:heroDownload];
}

- (void)shouldDownloadAStreamedFileToDisk {
	// no content-length header
	CMResource *heroDownload = [self.service resource:@"test/stream/hero"];
		
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	__block BOOL fileExistedAtCompletion = NO;
	__block NSNumber *progress = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		self.downloadedFileURL = [localResponse.result valueForKey:kCumulusProgressInfoKeyTempFileURL];
		NSFileManager *fm = [[NSFileManager alloc] init];
		fileExistedAtCompletion = [fm fileExistsAtPath:[self.downloadedFileURL path]];
		progress = [(CMProgressInfo *)response.result progress];
		dispatch_semaphore_signal(request_sema);
	};
	
	[heroDownload downloadWithProgressBlock:nil completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	NSString *filename = [localResponse.result valueForKey:kCumulusProgressInfoKeyFilename];
	NSString *URL =  [localResponse.result valueForKey:kCumulusProgressInfoKeyURL];
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@", localResponse);
	
	STAssertNotNil(filename, @"Filename should not be nil");
	STAssertNotNil(URL, @"URL should not be nil");
	STAssertNotNil(self.downloadedFileURL, @"Temp file URL should not be nil");
	STAssertTrue(fileExistedAtCompletion, @"Downloaded file should exist on disk at completion: %@",self.downloadedFileURL);
	STAssertEquals([progress floatValue], 1.f, @"Final progress should have been 1: %@",progress);

	__block BOOL tempFileWasRemovedAfterCompletion = NO;
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [[NSFileManager alloc] init];
		tempFileWasRemovedAfterCompletion = ![fm fileExistsAtPath:[self.downloadedFileURL path]];
	});
	STAssertTrue(tempFileWasRemovedAfterCompletion, @"Downloaded temp file should be cleaned up after completion: %@",self.downloadedFileURL);
}

- (void)shouldDownloadAFileToCustomCacheLocation {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *directory = [paths lastObject];
	
	self.cachesDir = [directory stringByAppendingPathComponent:@"CumulusSpecs"];
	CMResource *heroDownload = [self.service resource:@"test/download/hero"];

	[self assertDownloadResourceToDisk:heroDownload];
}

- (void) shouldResumeDownloadingAFileToDisk {
	CMResource *massive = [self.service resource:@"test/download/massive"];
	[self assertResumeDownloadingResource:massive];
}

- (void) shouldResumeDownloadingAnUnmodifiedFileByETag {
	CMResource *massive = [self.service resource:@"test/download/massive/etag/notmodified"];
	[self assertResumeDownloadingResource:massive];
}

- (void) shouldResumeDownloadingAnUnmodifiedFileByLastModified {
	CMResource *massive = [self.service resource:@"test/download/massive/date/notmodified"];
	[self assertResumeDownloadingResource:massive];
}

- (void) shouldDownloadEntireFileWhenServerFailsAnIfRangeRequestByETag {
	CMResource *massive = [self.service resource:@"test/download/massive/etag/modified"];
	[self assertResumeDownloadingResource:massive];
}

- (void) shouldDownloadEntireFileWhenServerFailsAnIfRangeRequestByLastModified {
	CMResource *massive = [self.service resource:@"test/download/massive/date/modified"];
	[self assertResumeDownloadingResource:massive];
}

- (void) shouldResetDownloadStateWhenResumeFails {
	CMResource *massiveFailure = [self.service resource:@"test/download/massive/resume/fail"];

	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (progress > 0.f) {
			[progressInfo.request cancel];
		}
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	[massiveFailure downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	NSDictionary *downloadState = [CMDownloadInfo downloadInfo];
	CMDownloadInfo *massiveInfo = [downloadState objectForKey:[massiveFailure URL]];
	NSURL *tempFileURL = massiveInfo.downloadedFileTempURL;
			
	[massiveFailure resumeOrBeginDownloadWithProgressBlock:nil completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
		
	downloadState = [CMDownloadInfo downloadInfo];
	massiveInfo = [downloadState objectForKey:[massiveFailure URL]];
	STAssertNil(massiveInfo, @"Download state should have been cleaned up on a resume failure");

	__block BOOL tempFileWasRemovedAfterCompletion = NO;
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [[NSFileManager alloc] init];
		tempFileWasRemovedAfterCompletion = ![fm fileExistsAtPath:[tempFileURL path]];
	});
	STAssertTrue(tempFileWasRemovedAfterCompletion, @"Temp file should have been cleaned up on a resume failure");
}

- (void) shouldRevertToDownloadingWholeFileWhenAskedToResumeAStreamedFile {
	CMResource *massiveStream = [self.service resource:@"test/stream/massive"];
	
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		self.downloadedFileURL = [progressInfo tempFileURL];
		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		if ([progress floatValue] > 0.f) {
			[massiveStream cancelRequests];
		}
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	[massiveStream downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	
	__block float firstProgress = -1.f;
	__block BOOL hadRangeHeader = NO;
	progressBlock = ^(CMProgressInfo *progressInfo){
		if (NO == hadRangeHeader) {
			hadRangeHeader = ([progressInfo.request.headers objectForKey:@"Range"] != nil || [progressInfo.request.headers objectForKey:@"If-Range"] != nil);
		}
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (firstProgress == -1.f) {
			firstProgress = progress;
		}
	};
	[massiveStream resumeOrBeginDownloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@", localResponse);
	STAssertTrue(NO == hadRangeHeader, @"Request should *NOT* have included a range header");
	STAssertTrue(firstProgress == 0.f, @"Download should have reset to a zero byte offset");
	
}

- (void) shouldDownloadARangeAndBeComplete {
	CMResource *massive = [self.service resource:@"resources/hs-2006-01-c-full_tif.png"];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	__block NSURL *copiedFileURL = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		CMProgressInfo *result = response.result;
		copiedFileURL = [result.tempFileURL URLByAppendingPathExtension:@"png"];
		
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		[fm moveItemAtURL:result.tempFileURL toURL:copiedFileURL error:&error];
		
		dispatch_semaphore_signal(request_sema);
	};

	CMContentRange contentRange = CMContentRangeMake(0, 100000, 0);
	[massive downloadRange:contentRange progressBlock:nil completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);

	NSDictionary *downloadInfo = [CMDownloadInfo downloadInfo];
	CMDownloadInfo *downloadState = [downloadInfo objectForKey:[massive URL]];
	STAssertNil(downloadState, @"Download state for range download should have been reset");
	
	NSFileManager *fm = [NSFileManager new];
	NSError *error = nil;
	NSDictionary *attributes = [fm attributesOfItemAtPath:[copiedFileURL path] error:&error];
	long long fileSize = (long long)[attributes fileSize];
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@", localResponse);
	STAssertEquals(fileSize, contentRange.length, @"Downloaded file size should have equaled request range length");
}


- (void)shouldUploadAFileFromDisk {
	CMResource *hero = [self.service resource:@"test/upload/hero"];
	
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		NSLog(@"progress: %@",progress);
//		[mockProgressObject setValue:progress forKey:@"Progress"];
//		if ([progress floatValue] < 1.f) {
//			[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:someProgressBlock] forKey:@"Progress"];
//		}
	};

	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"t_hero" ofType:@"png"];
	NSURL *fileURL = [NSURL fileURLWithPath:filePath];
	[hero uploadFile:fileURL withProgressBlock:progressBlock completionBlock:completionBlock];

	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}
*/
- (void)shouldDownloadAFileInChunks {
	CMResource *massive = [self.service resource:@"test/download/massive"];
	[self assertDownloadResourceToDisk:massive chunked:YES];

	NSFileManager *fm = [NSFileManager new];
	NSString *resourceImagePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	STAssertTrue([fm contentsEqualAtPath:resourceImagePath andPath:[self.copiedFileURL path]], @"Completed file should be the same as if it were downloaded without using chunks.");

}

- (void) shouldResumeDownloadingAChunkedFileToDisk {
	CMResource *massive = [self.service resource:@"test/download/massive"];

	__block long long currentOffset = 0;
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (progress > 0.f) {
			currentOffset = [progressInfo.fileOffset longLongValue];
			[progressInfo.request cancel];
		}
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	__block id massiveCacheIdentifier = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		massiveCacheIdentifier = response.request.cacheIdentifier;
		dispatch_semaphore_signal(request_sema);
	};
	[massive chunkedDownloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
			
	__block float firstProgress = -1.f;
	progressBlock = ^(CMProgressInfo *progressInfo){
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (firstProgress == -1.f && progress > 0.f && progress < 1.f) {
			firstProgress = progress;
		}
	};
	completionBlock = ^(CMResponse *response) {
		localResponse = response;
		CMProgressInfo *result = response.result;
		self.copiedFileURL = [result.tempFileURL URLByAppendingPathExtension:@"png"];
		
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		[fm moveItemAtURL:result.tempFileURL toURL:self.copiedFileURL error:&error];
		
		dispatch_semaphore_signal(request_sema);
	};

	[massive chunkedDownloadWithProgressBlock:progressBlock completionBlock:completionBlock];

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@", localResponse);

	float initialProgress = (float)currentOffset/(float)localResponse.totalContentLength;
	STAssertTrue(firstProgress >= initialProgress, @"Download should have started at greater than initial progress: %@ > %@",@(firstProgress),@(initialProgress));
		
	NSFileManager *fm = [NSFileManager new];
	NSString *resourceImagePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	STAssertTrue([fm contentsEqualAtPath:resourceImagePath andPath:[self.copiedFileURL path]], @"Completed file should be the same as if it were downloaded without using chunks.");
}


- (void)shouldCompleteChunkedDownloadWhenTheFileIsEmpty {
	STAssertTrue(NO, @"Unimplemented");
}

- (void)shouldReturnEmptyResultsWhenRemoteFileIsEmpty {
	STAssertTrue(NO, @"Unimplemented");
}

- (void)shouldProperlyCancelAChunkedDownload {
	STAssertTrue(NO, @"Unimplemented");
}




// ========================================================================== //

#pragma mark - Helpers

- (void) assertDownloadResourceToDisk:(CMResource *)resource {
	[self assertDownloadResourceToDisk:resource chunked:NO];
}

- (void) assertDownloadResourceToDisk:(CMResource *)resource chunked:(BOOL)chunked {
	
	if (self.cachesDir) {
		resource.cachesDir = self.cachesDir;
	}
	
	// Set up a mock to receive progress blocks
	__block id mockProgressObject = [OCMockObject mockForClass:[NSObject class]];
	
	
	BOOL (^zeroProgressBlock)(id) = ^(id value) {
		float progress = [(NSNumber *)value floatValue];
		return (BOOL)(progress == 0);
	};
	
	BOOL (^someProgressBlock)(id) = ^(id value) {
		float progress = [(NSNumber *)value floatValue];
		return (BOOL)(0.f < progress && progress <= 1.f);
	};
	
	[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:zeroProgressBlock] forKey:@"Progress"];
	
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		[mockProgressObject setValue:progress forKey:@"Progress"];
		if ([progress floatValue] < 1.f) {
			[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:someProgressBlock] forKey:@"Progress"];
		}
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	__block BOOL fileExistedAtCompletion = NO;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		self.downloadedFileURL = [localResponse.result valueForKey:kCumulusProgressInfoKeyTempFileURL];
		NSFileManager *fm = [[NSFileManager alloc] init];
		fileExistedAtCompletion = [fm fileExistsAtPath:[self.downloadedFileURL path]];
		
		CMProgressInfo *result = response.result;
		self.copiedFileURL = [result.tempFileURL URLByAppendingPathExtension:@"png"];
		
		NSError *error = nil;
		[fm moveItemAtURL:result.tempFileURL toURL:self.copiedFileURL error:&error];
		
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	if (chunked) {
		[resource chunkedDownloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	}
	else {
		[resource downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	}
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	
	[mockProgressObject verify];
	
	NSString *filename = [localResponse.result valueForKey:kCumulusProgressInfoKeyFilename];
	NSString *URL =  [localResponse.result valueForKey:kCumulusProgressInfoKeyURL];
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@", localResponse);
	STAssertTrue(localResponse.wasComplete, @"Response should have been complete: %@", localResponse);
	
	STAssertNotNil(filename, @"Filename should not be nil");
	STAssertNotNil(URL, @"URL should not be nil");	
	STAssertNotNil(self.downloadedFileURL, @"Temp file URL should not be nil");
	
	STAssertTrue(fileExistedAtCompletion, @"Downloaded file should exist on disk at completion: %@",self.downloadedFileURL);

	__block BOOL tempFileWasRemovedAfterCompletion = NO;
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [[NSFileManager alloc] init];
		tempFileWasRemovedAfterCompletion = ![fm fileExistsAtPath:[self.downloadedFileURL path]];
	});
	STAssertTrue(tempFileWasRemovedAfterCompletion, @"Downloaded temp file should be cleaned up after completion: %@",self.downloadedFileURL);

}

- (void) assertResumeDownloadingResource:(CMResource *)massive {
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (progress > 0.f) {
			[progressInfo.request cancel];
		}
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	__block id massiveCacheIdentifier = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		massiveCacheIdentifier = response.request.cacheIdentifier;
		dispatch_semaphore_signal(request_sema);
	};
	[massive downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	NSDictionary *downloadState = [CMDownloadInfo downloadInfo];
	CMDownloadInfo *massiveInfo = [downloadState objectForKey:massiveCacheIdentifier];
	NSURL *tempFileURL = massiveInfo.downloadedFileTempURL;
	
	STAssertNotNil(tempFileURL, @"Download state for partial download should include a temp file URL");
	
	NSFileManager *fm = [NSFileManager new];
	BOOL partialDownloadExists = [fm fileExistsAtPath:[tempFileURL path]];
	NSError *error = nil;
	NSDictionary *attributes = [fm attributesOfItemAtPath:[tempFileURL path] error:&error];
	long long currentOffset = (long long)[attributes fileSize];
	
	
	STAssertTrue(partialDownloadExists, @"Resumable file did not exist prior to resuming");
	
	
	__block float firstProgress = -1.f;
	__block BOOL hadRangeHeader = NO;
	__block BOOL writesToSameTempFile = NO;
	__block BOOL sentPartialContent = NO;
	progressBlock = ^(CMProgressInfo *progressInfo){
		if (NO == hadRangeHeader) {
			hadRangeHeader = ([progressInfo.request.headers objectForKey:kCumulusHTTPHeaderRange] != nil);
		}
		writesToSameTempFile = [progressInfo.tempFileURL isEqual:tempFileURL];
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (firstProgress == -1.f && progress > 0.f && progress < 1.f) {
			firstProgress = progress;
		}
	};
	completionBlock = ^(CMResponse *response) {
		localResponse = response;
		CMProgressInfo *result = response.result;
		self.copiedFileURL = [result.tempFileURL URLByAppendingPathExtension:@"png"];
		
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		[fm moveItemAtURL:result.tempFileURL toURL:self.copiedFileURL error:&error];
		
		sentPartialContent = response.HTTPPartialContent;
		
		dispatch_semaphore_signal(request_sema);
	};
	[massive resumeOrBeginDownloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@", localResponse);
	STAssertTrue(hadRangeHeader, @"Request should have included a range header");
	STAssertTrue(writesToSameTempFile, @"Download should have resumed writing to partial download");
	
	float initialProgress = (float)currentOffset/(float)localResponse.totalContentLength;
	if (sentPartialContent) {
		STAssertTrue(firstProgress >= initialProgress, @"Download should have started at greater than initial progress: %@ > %@",@(firstProgress),@(initialProgress));
	}
	else {
		STAssertTrue(firstProgress < initialProgress, @"Download should have started at less than initial progress: %@ > %@",@(firstProgress),@(initialProgress));
	}
	
	
	NSString *resourceImagePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	STAssertTrue([fm contentsEqualAtPath:resourceImagePath andPath:[self.copiedFileURL path]], @"Completed file should be the same as if it were downloaded without interruption.");
}



@end
