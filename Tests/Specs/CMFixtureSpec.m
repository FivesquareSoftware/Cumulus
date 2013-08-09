//
//	CMFixtureSpec.m
//	Cumulus
//
//	Created by John Clayton on 5/3/12.
//	Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMFixtureSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>
#import "OCMock.h"



@implementation CMFixtureSpec



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
	
	self.service = [CMResource withURL:kTestServerHost];
	[Cumulus setFixtures:nil];
	[Cumulus useFixtures:NO];
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
	CMResource *resource = [self.service resource:@"anything"];
	[resource setFixture:@"FOO" forHTTPMethod:kCumulusHTTPMethodGET];
	resource.contentType = CMContentTypeText;
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(response.result, @"FOO", @"Result did not equal text");
}

- (void) shouldGetADataFixture {
	CMResource *resource = [self.service resource:@"anything"];
	NSData *data = [@"FOO" dataUsingEncoding:NSUTF8StringEncoding];
	[resource setFixture:data forHTTPMethod:kCumulusHTTPMethodGET];
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(response.result, data, @"Result did not equal data");
}

- (void) shouldGetAnItemFixture {
	CMResource *resource = [self.service resource:@"anything"];
	resource.contentType = CMContentTypeJSON;
	[resource setFixture:self.specHelper.item forHTTPMethod:kCumulusHTTPMethodGET];
	
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(response.result, self.specHelper.item, @"Result did not equal item");
}

- (void) shouldGetAListFixture {
	CMResource *resource = [self.service resource:@"anything"];
	resource.contentType = CMContentTypeJSON;
	[resource setFixture:self.specHelper.list forHTTPMethod:kCumulusHTTPMethodGET];
	
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(response.result, self.specHelper.list, @"Result did not equal list");
}

- (void) shouldGetAnImageFixture {
	CMResource *resource = [self.service resource:@"anything"];
	UIImage *image = [UIImage imageNamed:@"t_hero.png"];
	NSData *imageData = UIImagePNGRepresentation(image);
	[resource setFixture:image forHTTPMethod:kCumulusHTTPMethodGET];
	
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(UIImagePNGRepresentation(response.result), imageData, @"Result did not equal image");
}

- (void) shouldGetAnFixtureSuppliedAsURL {
	CMResource *resource = [self.service resource:@"anything"];
	NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"t_hero" withExtension:@"png"];
	UIImage *image = [UIImage imageNamed:@"t_hero.png"];
	NSData *imageData = UIImagePNGRepresentation(image);
	
	[resource setFixture:imageURL forHTTPMethod:kCumulusHTTPMethodGET];
	
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(UIImagePNGRepresentation(response.result), imageData, @"Result did not equal image");
}

- (void) shouldDownloadFixture {
	[self doFixtureDownload:NO];
}

- (void) shouldDownloadFixtureSuppliedAsURL {
	[self doFixtureDownload:YES];
}

- (void) shouldNotGetAFixtureMeantForPost {
	CMResource *resource = [self.service resource:@"index"];
	[resource setFixture:@"FOO" forHTTPMethod:kCumulusHTTPMethodPOST];
	resource.contentType = CMContentTypeText;
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(response.result, @"OK", @"Result did not equal expected response for GET");
}

- (void) shouldUseAGlobalFixture {
	CMResource *resource = [self.service resource:@"anything"];
	resource.contentType = CMContentTypeText;
	
	[Cumulus addFixture:@"FOO" forRequestSignature:[NSString stringWithFormat:@"%@ %@", kCumulusHTTPMethodGET,[resource.URL absoluteString]]];
	[Cumulus useFixtures:YES];
	
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(response.result, @"FOO", @"Result did not equal text");
}

- (void) shouldNotUseAGlobalFixtureWhenThereIsALocalFixture {
	CMResource *resource = [self.service resource:@"index"];
	resource.contentType = CMContentTypeText;
	[resource setFixture:@"FOO" forHTTPMethod:kCumulusHTTPMethodGET];
	
	[Cumulus addFixture:@"BAR" forRequestSignature:[NSString stringWithFormat:@"%@ %@", kCumulusHTTPMethodGET,[resource.URL absoluteString]]];
	[Cumulus useFixtures:YES];
	
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(response.result, @"FOO", @"Result did not equal text");
}

- (void) shouldNotUseAGlobalFixtureWhenNotUsingFixtures {
	CMResource *resource = [self.service resource:@"index"];
	resource.contentType = CMContentTypeText;
	
	[Cumulus addFixture:@"FOO" forRequestSignature:[NSString stringWithFormat:@"%@ %@", kCumulusHTTPMethodGET,[resource.URL absoluteString]]];
	[Cumulus useFixtures:NO];
	
	CMResponse *response = [resource get];
	STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	STAssertEqualObjects(response.result, @"OK", @"Result did not equal expected response for GET");
}

// ========================================================================== //

#pragma mark - Helpers



- (void) doFixtureDownload:(BOOL)asURL {
	CMResource *resource = [self.service resource:@"anything"];
	
	NSURL *imageURL = [[NSBundle mainBundle] URLForResource:@"t_hero" withExtension:@"png"];
	UIImage *image = [UIImage imageNamed:@"t_hero.png"];
	NSData *imageData = asURL ? [NSData dataWithContentsOfURL:imageURL] : UIImagePNGRepresentation(image);
	
	id fixture = asURL ? imageURL : image;
	[resource setFixture:fixture forHTTPMethod:kCumulusHTTPMethodGET];
	
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
	
	
	// Progress block
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
		NSNumber *progress = [progressInfo progress];
		[mockProgressObject setValue:progress forKey:@"Progress"];
		if ([progress floatValue] < 1.f) {
			[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:someProgressBlock] forKey:@"Progress"];
		}
	};
	
	// Completion block
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	__block NSURL *downloadedFileURL = nil;
	__block BOOL fileExistedAtCompletion = NO;
	__block NSData *resultData = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		downloadedFileURL = [localResponse.result valueForKey:kCumulusProgressInfoKeyTempFileURL];
		NSFileManager *fm = [[NSFileManager alloc] init];
		fileExistedAtCompletion = [fm fileExistsAtPath:[downloadedFileURL path]];
		resultData = [NSData dataWithContentsOfURL:downloadedFileURL];
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	//dispatch_release(request_sema);
	
	CMProgressInfo *resultObject = (CMProgressInfo *)localResponse.result;
	
	
	[mockProgressObject verify];
	
	NSString *filename = [resultObject filename];
	NSURL *URL =  [resultObject URL];
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@", localResponse);
	
	STAssertNotNil(filename, @"Filename should not be nil");
	STAssertNotNil(URL, @"URL should not be nil");
	STAssertNotNil(downloadedFileURL, @"Temp file URL should not be nil");
	
	
	STAssertTrue(fileExistedAtCompletion, @"Downloaded file should exist on disk at completion: %@",downloadedFileURL);
	STAssertEqualObjects(resultData, imageData, @"Result did not equal image");
	
	__block BOOL tempFileWasRemovedAfterCompletion = NO;
	dispatch_sync(dispatch_get_main_queue(), ^{
		NSFileManager *fm = [[NSFileManager alloc] init];
		tempFileWasRemovedAfterCompletion = ![fm fileExistsAtPath:[downloadedFileURL path]];
	});
	STAssertTrue(tempFileWasRemovedAfterCompletion, @"Downloaded temp file should be cleaned up after completion: %@",downloadedFileURL);
}



@end
