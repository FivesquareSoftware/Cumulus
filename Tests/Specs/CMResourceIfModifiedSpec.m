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


@import Nimble;


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
	expect([index valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince]).toNotWithDescription(beNil(),@"If modified since header should have been set");
}

- (void)shouldNotSendIfModifiedHeaderIfLastModifiedIsNotSet {
	CMResource *index = [self.service resource:@"index"];
	expect([index valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince]).toWithDescription(beNil(), @"If modified since header should have been set");
}

- (void)shouldNotSendIfModifiedHeaderIfLastModifiedIsSetToNil {
	CMResource *index = [self.service resource:@"index"];
	index.lastModified = nil;
	expect([index valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince]).toWithDescription(beNil(), @"If modified since header should have been set");
}

- (void)shouldSendIfModifiedHeaderIfTrackingLastModifiedAndLastModifiedSetInResponse {
	CMResource *tracksModified = [self.service resource:@"/test/last-modified"];
	tracksModified.automaticallyTracksLastModified = YES;
	CMResponse *response = [tracksModified get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",response]);
	expect(tracksModified.lastModified).toNotWithDescription(beNil(),@"Last modified should have been set by response");
	expect([tracksModified valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince]).toNotWithDescription(beNil(),@"If modified since header should have been set");
	expect(tracksModified.lastModified).toWithDescription(equal(response.lastModified), @"Resource last modified should equal response last modified");
}

- (void)shouldSendIfModifiedHeaderIfTrackingLastModifiedAndLastModifiedNotSetInResponseButWasPreviouslySet {
	CMResource *tracksModified = [self.service resource:@"/test/no-last-modified"];
	tracksModified.automaticallyTracksLastModified = YES;
	NSDate *modified = [NSDate date];
	tracksModified.lastModified = modified;
	CMResponse *response = [tracksModified get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",response]);
	expect(tracksModified.lastModified).toNotWithDescription(beNil(),@"Last modified should be set");
	expect([tracksModified valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince]).toNotWithDescription(beNil(),@"If modified since header should have been set");
	expect(tracksModified.lastModified).toWithDescription(equal(modified), @"Resource last modified should equal response last modified");
}

- (void)shouldBeNotModifiedWhenSendingLastModifiedToAnUnmodifiedResource {
	CMResource *notModified = [self.service resource:@"/test/if-modified/not"];
	notModified.automaticallyTracksLastModified = YES;
	CMResponse *response = [notModified get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",response]);
	expect(notModified.lastModified).toNotWithDescription(beNil(),@"Last modified should have been set by initial response");
	expect([notModified valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince]).toNotWithDescription(beNil(),@"If modified since header should have been set by initial response");
	
	response = [notModified get];
	expect(response.wasNotModified).toWithDescription(beTrue(), [NSString stringWithFormat:@"Subsequent response should have been not modified: %@",response]);
}

- (void)shouldBeModifiedWhenSendingLastModifiedToAModifiedResource {
	CMResource *wasModified = [self.service resource:@"/test/if-modified/is"];
	wasModified.automaticallyTracksLastModified = YES;
	CMResponse *response = [wasModified get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",response]);
	expect(wasModified.lastModified).toNotWithDescription(beNil(),@"Last modified should have been set by initial response");
	expect([wasModified valueForHeaderField:kCumulusHTTPHeaderIfModifiedSince]).toNotWithDescription(beNil(),@"If modified since header should have been set by initial response");
	
	response = [wasModified get];
	expect(response.wasNotModified).toWithDescription(beFalse(),[NSString stringWithFormat:@"Subsequent response should have been modified: %@", response]);
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Subsequent response should have been successful: %@",response]);
}



@end
