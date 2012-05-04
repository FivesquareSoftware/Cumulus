//
//  RCFixtureSpec.m
//  RESTClient
//
//  Created by John Clayton on 5/3/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCFixtureSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCFixtureSpec

@synthesize service;


+ (NSString *)description {
    return @"Fixtures";
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
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs


- (void) shouldGetAStringFixture {
	RCResource *resource = [self.service resource:@"anything"];
	resource.fixture = @"FOO";
	resource.contentType = RESTClientContentTypeText;
    RCResponse *response = [resource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, @"FOO", @"Result did not equal text");
}

- (void) shouldGetADataFixture {
	RCResource *resource = [self.service resource:@"anything"];
	NSData *data = [@"FOO" dataUsingEncoding:NSUTF8StringEncoding];
	resource.fixture = data;
    RCResponse *response = [resource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, data, @"Result did not equal data");
}

- (void) shouldGetAnItemFixture {
	RCResource *resource = [self.service resource:@"anything"];
	resource.contentType = RESTClientContentTypeJSON;
	resource.fixture = self.specHelper.item;
    RCResponse *response = [resource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void) shouldGetAListFixture {
	RCResource *resource = [self.service resource:@"anything"];
	resource.contentType = RESTClientContentTypeJSON;
	resource.fixture = self.specHelper.list;
    RCResponse *response = [resource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");	
}

- (void) shouldGetAnImageFixture {
	RCResource *resource = [self.service resource:@"anything"];
	UIImage *image = [UIImage imageNamed:@"t_hero.png"];
	NSData *imageData = UIImagePNGRepresentation(image);
	resource.fixture = image;
    RCResponse *response = [resource get];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
    STAssertEqualObjects(UIImagePNGRepresentation(response.result), imageData, @"Result did not equal image");
}

- (void) shouldDownloadFixture {
	RCResource *resource = [self.service resource:@"anything"];
	UIImage *image = [UIImage imageNamed:@"t_hero.png"];
	NSData *imageData = UIImagePNGRepresentation(image);
	resource.fixture = image;

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	RCCompletionBlock completionBlock = ^(RCResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource downloadWithProgressBlock:nil completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	RCProgressInfo *resultObject = (RCProgressInfo *)localResponse.result;
	
	NSString *filename = [resultObject filename];
	NSURL *URL =  [resultObject URL];
	NSURL *downloadedFileURL = [resultObject tempFileURL];
	
	STAssertTrue(localResponse.success, @"Response should have succeeded: %@", localResponse);
	
	STAssertNotNil(filename, @"Filename should not be nil");
	STAssertNotNil(URL, @"URL should not be nil");	
	STAssertNotNil(downloadedFileURL, @"Temp file URL should not be nil");
	
	NSFileManager *fm = [[NSFileManager alloc] init];
	BOOL exists = [fm fileExistsAtPath:[downloadedFileURL path]];
	STAssertTrue(exists, @"Downloaded file should exist on disk: %@",downloadedFileURL);
	
	NSData *resultData = [NSData dataWithContentsOfURL:downloadedFileURL];

    STAssertEqualObjects(resultData, imageData, @"Result did not equal image");
}


@end
