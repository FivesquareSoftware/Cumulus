//
//  CMDownloadSpec.m
//  Cumulus
//
//  Created by John Clayton on 11/23/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMFileHandlingSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>
#import "OCMock.h"

@interface CMFileHandlingSpec ()
@end

@implementation CMFileHandlingSpec

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
	self.service.cachePolicy = NSURLCacheStorageNotAllowed;
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

- (void)shouldDownloadAFileToDisk {
	CMResource *heroDownload = [self.service resource:@"test/download/hero"];
	[self assertDownloadAFileToDisk:heroDownload];
}

- (void)shouldDownloadAStreamedFileToDisk {
	// no content-length header
	CMResource *heroDownload = [self.service resource:@"test/stream/hero"];
	[self assertDownloadAFileToDisk:heroDownload];
}

- (void)shouldDownloadAFileToCustomCacheLocation {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *directory = [paths lastObject];
	
	self.cachesDir = [directory stringByAppendingPathComponent:@"CumulusSpecs"];
	CMResource *heroDownload = [self.service resource:@"test/download/hero"];

	[self assertDownloadAFileToDisk:heroDownload];
}

- (void) shouldResumeDownloadingAFileToDisk {
	
	CMResource *massive = [self.service resource:@"test/download/massive"];
	
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		self.downloadedFileURL = [progressInfo tempFileURL];
		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		if ([progress floatValue] > 0.f) {
			[massive cancelRequests];
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

	NSDictionary *downloadState = [CMDownloadInfo downloadInfo];
	CMDownloadInfo *massiveInfo = [downloadState objectForKey:[massive URL]];
	NSURL *tempFileURL = massiveInfo.downloadedFileTempURL;
	
	NSFileManager *fm = [NSFileManager new];
	BOOL partialDownloadExists = [fm fileExistsAtPath:[tempFileURL path]];
	
	STAssertTrue(partialDownloadExists, @"Resumable file did not exist prior to resuming");
	

	__block float firstProgress = -1.f;
	__block BOOL hadRangeHeader = NO;
	__block BOOL writesToSameTempFile = NO;
	progressBlock = ^(CMProgressInfo *progressInfo){
		if (NO == hadRangeHeader) {
			hadRangeHeader = ([progressInfo.request.headers objectForKey:kCumulusHTTPHeaderRange] != nil || [progressInfo.request.headers objectForKey:kCumulusHTTPHeaderIfRange] != nil);
		}
		writesToSameTempFile = [progressInfo.tempFileURL isEqual:tempFileURL];
		float progress = [[progressInfo valueForKey:kCumulusProgressInfoKeyProgress] floatValue];
		if (firstProgress == -1.f && progress > 0.f && progress < 1.f) {
			firstProgress = progress;
		}
	};
	[massive downloadWithResume:YES progressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);

	STAssertTrue(localResponse.success, @"Response should have succeeded: %@", localResponse);
	STAssertTrue(hadRangeHeader, @"Request should have included a range header");
	STAssertTrue(writesToSameTempFile, @"Download should have resumed writing to partial download");
	STAssertTrue(firstProgress > 0.f, @"Download should have resumed at a non-zero offset");
}

- (void) shouldFailToResumeDownloadingAStreamedFile {
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
	[massiveStream downloadWithResume:YES progressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.success, @"Response should have succeeded: %@", localResponse);
	STAssertTrue(NO == hadRangeHeader, @"Request should *NOT* have included a range header");
	STAssertTrue(firstProgress == 0.f, @"Download should have reset to a zero byte offset");
	
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

	STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}


// ========================================================================== //

#pragma mark - Helpers

- (void) assertDownloadAFileToDisk:(CMResource *)resource {
	
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
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	
	[mockProgressObject verify];
	
	NSString *filename = [localResponse.result valueForKey:kCumulusProgressInfoKeyFilename];
	NSString *URL =  [localResponse.result valueForKey:kCumulusProgressInfoKeyURL];
	
	STAssertTrue(localResponse.success, @"Response should have succeeded: %@", localResponse);
	
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





@end
