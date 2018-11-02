//
//	CMResourceIfModifiedSpec.m
//	Cumulus
//
//	Created by John Clayton on 6/19/13.
//	Copyright 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceIfModifiedSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <XCTest/XCTest.h>


@implementation CMResourceIfModifiedSpec

+ (NSString *)description {
	return @"If Modified";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
	// set up resources common to all examples here
}

- (void)beforeEach {
	// set up resources that need to be initialized before each example here
	self.service = [CMResource withURL:kTestServerHost];
	self.service.cachePolicy = NSURLRequestReloadIgnoringCacheData;
}

- (void)afterEach {
	// tear down resources specific to each example here
}


- (void)afterAll {
	// tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

- (void)shouldSendIfModifiedHeaderIfLastModifiedIsSet {
	CMResource *index = [self.service resource:@"index"];
	index.lastModified = [NSDate date];
	XCTAssertNotNil([index valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince], @"If modified since header should have been set");
}

- (void)shouldNotSendIfModifiedHeaderIfLastModifiedIsNotSet {
	CMResource *index = [self.service resource:@"index"];
	XCTAssertNil([index valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince], @"If modified since header should have been set");
}

- (void)shouldNotSendIfModifiedHeaderIfLastModifiedIsSetToNil {
	CMResource *index = [self.service resource:@"index"];
	index.lastModified = nil;
	XCTAssertNil([index valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince], @"If modified since header should have been set");
}

- (void)shouldSendIfModifiedHeaderIfTrackingLastModifiedAndLastModifiedSetInResponse {
	CMResource *tracksModified = [self.service resource:@"/test/last-modified"];
	tracksModified.automaticallyTracksLastModified = YES;
	CMResponse *response = [tracksModified get];
	XCTAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	XCTAssertNotNil(tracksModified.lastModified, @"Last modified should have been set by response");
	XCTAssertNotNil([tracksModified valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince], @"If modified since header should have been set");
	XCTAssertEqualObjects(tracksModified.lastModified, response.lastModified, @"Resource last modified should equal response last modified");
}

- (void)shouldSendIfModifiedHeaderIfTrackingLastModifiedAndLastModifiedNotSetInResponseButWasPreviouslySet {
	CMResource *tracksModified = [self.service resource:@"/test/no-last-modified"];
	tracksModified.automaticallyTracksLastModified = YES;
	NSDate *modified = [NSDate date];
	tracksModified.lastModified = modified;
	CMResponse *response = [tracksModified get];
	XCTAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	XCTAssertNotNil(tracksModified.lastModified, @"Last modified should be set");
	XCTAssertNotNil([tracksModified valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince], @"If modified since header should have been set");
	XCTAssertEqualObjects(tracksModified.lastModified, modified, @"Resource last modified should equal response last modified");
}

- (void)shouldBeNotModifiedWhenSendingLastModifiedToAnUnmodifiedResource {
	CMResource *notModified = [self.service resource:@"/test/if-modified/not"];
	notModified.automaticallyTracksLastModified = YES;
	CMResponse *response = [notModified get];
	XCTAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	XCTAssertNotNil(notModified.lastModified, @"Last modified should have been set by initial response");
	XCTAssertNotNil([notModified valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince], @"If modified since header should have been set by initial response");
	
	response = [notModified get];
	XCTAssertTrue(response.wasNotModified, @"Subsequent response should have been not modified: %@",response);
}

- (void)shouldBeModifiedWhenSendingLastModifiedToAModifiedResource {
	CMResource *wasModified = [self.service resource:@"/test/if-modified/is"];
	wasModified.automaticallyTracksLastModified = YES;
	CMResponse *response = [wasModified get];
	XCTAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
	XCTAssertNotNil(wasModified.lastModified, @"Last modified should have been set by initial response");
	XCTAssertNotNil([wasModified valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince], @"If modified since header should have been set by initial response");
	
	response = [wasModified get];
	XCTAssertFalse(response.wasNotModified, @"Subsequent response should have been modified: %@",response);
	XCTAssertTrue(response.wasSuccessful, @"Subsequent response should have been successful: %@",response);
}



@end
