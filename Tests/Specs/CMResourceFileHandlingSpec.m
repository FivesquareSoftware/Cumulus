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


@import Nimble;
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


- (void)shouldReturnIncompleteResultWhenDownloadIsIncomplete {
	CMResource *massive = [self.service resource:@"test/download/massive"];

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
	[massive downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	CMProgressInfo *result = localResponse.result;
	
	expect(result.tempFileURL).toWithDescription(beNil(), @"When a download is canceled the result should not contain a temp file URL");
	expect(result.didComplete).toWithDescription(beFalse(), @"When a download is canceled the result should not be complete");
}

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
		
	NSString *filename = [localResponse.result valueForKey:kCumulusProgressInfoKeyFilename];
	NSString *URL =  [localResponse.result valueForKey:kCumulusProgressInfoKeyURL];
	
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@", localResponse]);
	
	expect(filename).toNotWithDescription(beNil(),@"Filename should not be nil");
	expect(URL).toNotWithDescription(beNil(),@"URL should not be nil");
	expect(self.downloadedFileURL).toNotWithDescription(beNil(),@"Temp file URL should not be nil");
	expect(fileExistedAtCompletion).toWithDescription(beTrue(), [NSString stringWithFormat:@"Downloaded file should exist on disk at completion: %@",self.downloadedFileURL]);
	expect(@([progress floatValue])).toWithDescription(equal(@(1.f)), [NSString stringWithFormat:@"Final progress should have been 1: %@",progress]);

	__block BOOL tempFileWasRemovedAfterCompletion = NO;
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [[NSFileManager alloc] init];
		tempFileWasRemovedAfterCompletion = ![fm fileExistsAtPath:[self.downloadedFileURL path]];
	});
	expect(tempFileWasRemovedAfterCompletion).toWithDescription(beTrue(), [NSString stringWithFormat:@"Downloaded temp file should be cleaned up after completion: %@",self.downloadedFileURL]);
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
			
	downloadState = [CMDownloadInfo downloadInfo];
	massiveInfo = [downloadState objectForKey:[massiveFailure URL]];
	expect(massiveInfo).toWithDescription(beNil(), @"Download state should have been cleaned up on a resume failure");

	__block BOOL tempFileWasRemovedAfterCompletion = NO;
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [[NSFileManager alloc] init];
		tempFileWasRemovedAfterCompletion = ![fm fileExistsAtPath:[tempFileURL path]];
	});
	expect(tempFileWasRemovedAfterCompletion).toWithDescription(beTrue(), @"Temp file should have been cleaned up on a resume failure");
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
		
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@", localResponse]);
	expect(NO == hadRangeHeader).toWithDescription(beTrue(), @"Request should *NOT* have included a range header");
	expect(firstProgress == 0.f).toWithDescription(beTrue(), @"Download should have reset to a zero byte offset");
	
}

- (void) shouldDownloadARangeAndBeComplete {
	CMResource *massive = [self.service resource:@"resources/hs-2006-01-c-full_tif.png"];
//	CMResource *massive = [self.service resource:@"test/download/massive"];

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
	
	NSDictionary *downloadInfo = [CMDownloadInfo downloadInfo];
	CMDownloadInfo *downloadState = [downloadInfo objectForKey:[massive URL]];
	expect(downloadState).toWithDescription(beNil(), @"Download state for range download should have been reset");
	
	NSFileManager *fm = [NSFileManager new];
	NSError *error = nil;
	NSDictionary *attributes = [fm attributesOfItemAtPath:[copiedFileURL path] error:&error];
	long long fileSize = (long long)[attributes fileSize];
	
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@", localResponse]);
	expect(@(fileSize)).toWithDescription(equal(@(contentRange.length)), @"Downloaded file size should have equaled request range length");
}

// This isnt' really exposed at the resource level, but the chunking tests exercise this
//- (void)shouldResumeARangeAndDownloadJustTheIncompletePortion {
//	expect(NO).toWithDescription(beTrue(), @"Unimplemented");
//}

- (void)shouldUploadAFileFromDisk {
	CMResource *hero = [self.service resource:@"test/upload/hero"];
	
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
//		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
//		NSLog(@"progress: %@",progress);
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
	
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",localResponse]);
}

- (void)shouldReturnIncompleteResultWhenChunkedDownloadIsIncomplete {
	CMResource *massive = [self.service resource:@"test/download/massive"];
	
	massive.preflightBlock = ^(CMRequest *request) {
		CMChunkedDownloadRequest *chunkedRequest = (CMChunkedDownloadRequest *)request;
		chunkedRequest.minumumProgressUpdateInterval = 0;
		return YES;
	};

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
	[massive downloadInChunksWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	CMProgressInfo *result = localResponse.result;
	
	expect(result.tempFileURL).toWithDescription(beNil(), @"When a chunked download is canceled the result should not contain a temp file URL");
	expect(result.didComplete).toWithDescription(beFalse(), @"When a chunked download is canceled the result should not be complete");
}

- (void)shouldDownloadAFileInChunks {
	CMResource *massive = [self.service resource:@"test/download/massive"];
	[self assertDownloadResourceToDisk:massive chunked:YES];

	NSFileManager *fm = [NSFileManager new];
	NSString *resourceImagePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	expect([fm contentsEqualAtPath:resourceImagePath andPath:[self.copiedFileURL path]]).toWithDescription(beTrue(), @"Completed file should be the same as if it were downloaded without using chunks.");
}

- (void) shouldResumeDownloadingAChunkedFileToDisk {
	CMResource *massive = [self.service resource:@"test/download/massive"];
	
	massive.preflightBlock = ^(CMRequest *request) {
		CMChunkedDownloadRequest *chunkedRequest = (CMChunkedDownloadRequest *)request;
		chunkedRequest.minumumProgressUpdateInterval = 0;
		return YES;
	};

	__block long long currentOffset = 0;
	__block float initialProgress = -1;
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (initialProgress == -1 && progress > 0.f) {
			currentOffset = [progressInfo.fileOffset longLongValue];
			initialProgress = progress;
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
	[massive downloadInChunksWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
			
	__block float firstProgress = -1.f;
	progressBlock = ^(CMProgressInfo *progressInfo){
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (firstProgress == -1.f && progress > 0.f && progress < 1.f) {
			firstProgress = progress;
		}
	};
	completionBlock = ^(CMResponse *response) {
//		if (firstProgress == -1) {
//			firstProgress = [response.request.progressReceivedInfo.progress floatValue];
//		}
		localResponse = response;
		CMProgressInfo *result = response.result;
		self.copiedFileURL = [result.tempFileURL URLByAppendingPathExtension:@"png"];
		
		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		[fm moveItemAtURL:result.tempFileURL toURL:self.copiedFileURL error:&error];
		
		dispatch_semaphore_signal(request_sema);
	};

	[massive downloadInChunksWithProgressBlock:progressBlock completionBlock:completionBlock];

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
		
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@", localResponse]);

//	float initialProgress = (float)currentOffset/(float)localResponse.totalContentLength;
	expect(firstProgress >= initialProgress).toWithDescription(beTrue(), [NSString stringWithFormat:@"Download should have started at greater than initial progress: %@ > %@",@(firstProgress),@(initialProgress)]);
		
	NSFileManager *fm = [NSFileManager new];
	NSString *resourceImagePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	expect([fm contentsEqualAtPath:resourceImagePath andPath:[self.copiedFileURL path]]).toWithDescription(beTrue(), @"Completed file should be the same as if it were downloaded without using chunks.");
}

- (void)shouldCompleteChunkedDownloadWhenRemoteFileIsEmpty {
	CMResource *empty = [self.service resource:@"test/download/empty"];
	__block CMResponse *localResponse = nil;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	[empty downloadInChunksWithProgressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@", localResponse]);
}

// This is exercised by the resume chunks spec
//- (void)shouldProperlyCancelAChunkedDownload {
//	expect(NO).toWithDescription(beTrue(), @"Unimplemented");
//}

- (void)shouldNotRequestChunksWhenInitialHeadFails {
	CMResource *empty = [self.service resource:@"test/download/fail"];
	
	__block float firstProgress = -1;
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo) {
		if (firstProgress == -1) {
			firstProgress = [progressInfo.progress floatValue];
		}
	};
	
	__block CMResponse *localResponse = nil;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	[empty downloadInChunksWithProgressBlock:progressBlock completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);

	expect(localResponse.wasUnsuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have failed: %@", localResponse]);
	expect(firstProgress == 0).toWithDescription(beTrue(), @"No chunk progress shoud have been reported for a failed HEAD");
}

- (void) shouldComputeChunkSizesBasedOnNumberOfWorkers {
	CMResource *massive = [self.service resource:@"test/download/massive"];
	
	NSString *resourceImagePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	NSFileManager *fm = [NSFileManager new];
	NSError *error = nil;
	NSDictionary *fileAtts = [fm attributesOfItemAtPath:resourceImagePath error:&error];
	expect(error).toWithDescription(beNil(), @"Error getting file size");
	unsigned long long fileSize = [fileAtts fileSize];
	unsigned long long chunkSize = (fileSize/2ULL)+1;
	
	__block unsigned long long computedChunkSize = 0;
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo) {
		if (computedChunkSize == 0 && [progressInfo.progress floatValue] > 0.f) {
			CMChunkedDownloadRequest *chunkedRequest = (CMChunkedDownloadRequest *)progressInfo.request;
			computedChunkSize = (unsigned long long)chunkedRequest.chunkSize;
			[chunkedRequest cancel];
		}
	};
	
	massive.maxConcurrentChunks = 2;
	
	__block CMResponse *localResponse = nil;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	[massive downloadInChunksWithProgressBlock:progressBlock completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	expect(@(chunkSize)).toWithDescription(equal(@(computedChunkSize)), @"Chunk size should be computed based on number of workers");
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
		[resource downloadInChunksWithProgressBlock:progressBlock completionBlock:completionBlock];
	}
	else {
		[resource downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	}
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
		
	
	[mockProgressObject verify];
	
	NSString *filename = [localResponse.result valueForKey:kCumulusProgressInfoKeyFilename];
	NSString *URL =  [localResponse.result valueForKey:kCumulusProgressInfoKeyURL];
	
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@", localResponse]);
	expect(localResponse.wasComplete).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have been complete: %@", localResponse]);
	
	expect(filename).toNotWithDescription(beNil(),@"Filename should not be nil");
	expect(URL).toNotWithDescription(beNil(),@"URL should not be nil");	
	expect(self.downloadedFileURL).toNotWithDescription(beNil(),@"Temp file URL should not be nil");
	
	expect(fileExistedAtCompletion).toWithDescription(beTrue(), [NSString stringWithFormat:@"Downloaded file should exist on disk at completion: %@",self.downloadedFileURL]);

	__block BOOL tempFileWasRemovedAfterCompletion = NO;
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [[NSFileManager alloc] init];
		tempFileWasRemovedAfterCompletion = ![fm fileExistsAtPath:[self.downloadedFileURL path]];
	});
	expect(tempFileWasRemovedAfterCompletion).toWithDescription(beTrue(), [NSString stringWithFormat:@"Downloaded temp file should be cleaned up after completion: %@",self.downloadedFileURL]);

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
	
	expect(tempFileURL).toNotWithDescription(beNil(),@"Download state for partial download should include a temp file URL");
	
	NSFileManager *fm = [NSFileManager new];
	BOOL partialDownloadExists = [fm fileExistsAtPath:[tempFileURL path]];
	NSError *error = nil;
	NSDictionary *attributes = [fm attributesOfItemAtPath:[tempFileURL path] error:&error];
	long long currentOffset = (long long)[attributes fileSize];
	
	
	expect(partialDownloadExists).toWithDescription(beTrue(), @"Resumable file did not exist prior to resuming");
	
	
	__block float firstProgress = -1.f;
	__block BOOL hadRangeHeader = NO;
	__block BOOL writesToSameTempFile = NO;
	__block BOOL sentPartialContent = NO;
	progressBlock = ^(CMProgressInfo *progressInfo){
		if (NO == hadRangeHeader) {
			hadRangeHeader = ([progressInfo.request.headers objectForKey:kCumulusHTTPHeaderRange] != nil);
		}
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (firstProgress == -1.f && progress > 0.f && progress < 1.f) {
			firstProgress = progress;
		}
	};
	completionBlock = ^(CMResponse *response) {
		localResponse = response;
		CMProgressInfo *result = response.result;
		self.copiedFileURL = [result.tempFileURL URLByAppendingPathExtension:@"png"];
		writesToSameTempFile = [result.tempFileURL isEqual:tempFileURL];

		NSFileManager *fm = [NSFileManager new];
		NSError *error = nil;
		[fm moveItemAtURL:result.tempFileURL toURL:self.copiedFileURL error:&error];
		
		sentPartialContent = response.HTTPPartialContent;
		
		dispatch_semaphore_signal(request_sema);
	};
	[massive resumeOrBeginDownloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
		
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@", localResponse]);
	expect(hadRangeHeader).toWithDescription(beTrue(), @"Request should have included a range header");
	expect(writesToSameTempFile).toWithDescription(beTrue(), @"Download should have resumed writing to partial download");
	
	float initialProgress = (float)currentOffset/(float)localResponse.totalContentLength;
	if (sentPartialContent) {
		expect(firstProgress >= initialProgress).toWithDescription(beTrue(), [NSString stringWithFormat:@"Download should have started at greater than initial progress: %@ > %@",@(firstProgress),@(initialProgress)]);
	}
	else {
		expect(firstProgress < initialProgress).toWithDescription(beTrue(), [NSString stringWithFormat:@"Download should have started at less than initial progress: %@ > %@",@(firstProgress),@(initialProgress)]);
	}
	
	
	NSString *resourceImagePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	BOOL equalContents = [fm contentsEqualAtPath:resourceImagePath andPath:[self.copiedFileURL path]];
	NSDictionary *resourceAttributes = nil;
	NSDictionary *copiedFileAttributes = nil;
	if (NO == equalContents) {
		resourceAttributes = [fm attributesOfItemAtPath:resourceImagePath error:NULL];
		copiedFileAttributes = [fm attributesOfItemAtPath:[self.copiedFileURL path] error:NULL];
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDir = [paths lastObject];
		NSString *documentFilePath = [documentsDir stringByAppendingPathComponent:[self.copiedFileURL lastPathComponent]];
		[fm copyItemAtPath:[self.copiedFileURL path] toPath:documentFilePath error:NULL];
	}
	expect(equalContents).toWithDescription(beTrue(), [NSString stringWithFormat:@"Completed file should be the same as if it were downloaded without interruption. (%@ != %@)",resourceAttributes,copiedFileAttributes]);
}



@end
