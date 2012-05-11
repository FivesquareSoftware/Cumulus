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

@implementation RCFileHandlingSpec

@synthesize service;
@synthesize downloadedFileURL;

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
	
	NSFileManager *fm = [[NSFileManager alloc] init];
	__autoreleasing NSError *error = nil;
	[fm removeItemAtURL:self.downloadedFileURL error:&error];
}


- (void)afterAll {
    // tear down common resources here
	[self.specHelper cleanCaches];
}

// ========================================================================== //

#pragma mark - Specs

- (void)shouldDownloadAFileToDisk {
	RCResource *hero = [self.service resource:@"test/download/hero"];
	
	
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
	RCCompletionBlock completionBlock = ^(RCResponse *response) {
		localResponse = response;
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
	self.downloadedFileURL = [localResponse.result valueForKey:kRESTClientProgressInfoKeyTempFileURL];

	STAssertTrue(localResponse.success, @"Response should have succeeded: %@", localResponse);

	STAssertNotNil(filename, @"Filename should not be nil");
	STAssertNotNil(URL, @"URL should not be nil");	
	STAssertNotNil(self.downloadedFileURL, @"Temp file URL should not be nil");
	
	NSFileManager *fm = [[NSFileManager alloc] init];
	BOOL exists = [fm fileExistsAtPath:[self.downloadedFileURL path]];
	STAssertTrue(exists, @"Downloaded file should exist on disk: %@",self.downloadedFileURL);
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



@end
