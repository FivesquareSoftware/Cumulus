//
//  RCDownloadSpec.m
//  RESTClient
//
//  Created by John Clayton on 11/23/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCFileHandlingSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>
#import "OCMock.h"

@interface RCFileHandlingSpec ()
- (void) assertDownloadAFileToDisk;
@end

@implementation RCFileHandlingSpec

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
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 

	self.service = [RCResource withURL:kTestServerHost];
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
	[self assertDownloadAFileToDisk];
}

- (void)shouldDownloadAFileToCustomCacheLocation {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
	NSString *directory = [paths lastObject];
	
	self.cachesDir = [directory stringByAppendingPathComponent:@"RESTClientSpecs"];
	
	[self assertDownloadAFileToDisk];
}

- (void)shouldUploadAFileFromDisk {
	RCResource *hero = [self.service resource:@"test/upload/hero"];
	
	RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
		NSLog(@"progress: %@",progress);
//		[mockProgressObject setValue:progress forKey:@"Progress"];
//		if ([progress floatValue] < 1.f) {
//			[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:someProgressBlock] forKey:@"Progress"];
//		}
	};

	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	RCCompletionBlock completionBlock = ^(RCResponse *response) {
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

- (void) assertDownloadAFileToDisk {
	RCResource *hero = [self.service resource:@"test/download/hero"];
	
	if (self.cachesDir) {
		hero.cachesDir = self.cachesDir;
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
	
	RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
		[mockProgressObject setValue:progress forKey:@"Progress"];
		if ([progress floatValue] < 1.f) {
			[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:someProgressBlock] forKey:@"Progress"];
		}
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	__block BOOL fileExistedAtCompletion = NO;
	RCCompletionBlock completionBlock = ^(RCResponse *response) {
		localResponse = response;
		self.downloadedFileURL = [localResponse.result valueForKey:kRESTClientProgressInfoKeyTempFileURL];
		NSFileManager *fm = [[NSFileManager alloc] init];
		fileExistedAtCompletion = [fm fileExistsAtPath:[self.downloadedFileURL path]];
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[hero downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	
	[mockProgressObject verify];
	
	NSString *filename = [localResponse.result valueForKey:kRESTClientProgressInfoKeyFilename];
	NSString *URL =  [localResponse.result valueForKey:kRESTClientProgressInfoKeyURL];
	
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
