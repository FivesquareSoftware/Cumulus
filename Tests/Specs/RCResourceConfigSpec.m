//
//  RCResourceConfigSpec.m
//  RESTClient
//
//  Created by John Clayton on 10/8/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCResourceConfigSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCResourceConfigSpec

@synthesize service;

+ (NSString *)description {
    return @"Resource Configuration";
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

- (void) shouldConstructResourcesUsingStrings {
	RCResource *resource = [self.service resource:@"abc123"];
	NSURL *URL = [[self.service  URL] URLByAppendingPathComponent:@"abc123"];
	STAssertEqualObjects(resource.URL, URL, @"URL should contain string arg");
}

- (void) shouldConstructResourcesUsingNumbers {
	RCResource *resource = [self.service resource:[NSNumber numberWithInt:123]];
	NSURL *URL = [[self.service  URL] URLByAppendingPathComponent:@"123"];
	STAssertEqualObjects(resource.URL, URL, @"URL should contain resource number");
}

- (void) shouldConstructResourcesUsingFormatStrings {
	RCResource *resource = [self.service resourceWithFormat:@"abc%@",[NSNumber numberWithInt:123]];
	NSURL *URL = [[self.service  URL] URLByAppendingPathComponent:@"abc123"];
	STAssertEqualObjects(resource.URL, URL, @"URL should contain resource format and arguments");
}

- (void)shouldSetJSONContentTypeHeadersCorrectly {
	RCResource *resource = [self.service resource:@"test"];
	resource.contentType = RESTClientContentTypeJSON;
	
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"application/json", @"Content-Type"
							 , @"application/json", @"Accept"
							 , nil];
	STAssertEqualObjects(resource.headers, headers, @"Should set resource headsers from content type");
}

- (void)shouldCreateAuthProviderFromUsernmaeAndPassword {
	RCResource *resource = [self.service resource:@"test"];
	resource.username = @"foo";
	resource.password = @"bar";
	
	STAssertNotNil(resource.authProvider, @"Default auth provider should not be nil");
}

- (void)shouldStandardizeURLsWithLeadingSlashes {
	RCResource *childOne = [self.service resource:@"child"];
	RCResource *childTwo = [self.service resource:@"/child"];

	STAssertEqualObjects([childOne.URL absoluteString], [childTwo.URL absoluteString], @"Should standardize URLs with leading slashes");	
}

- (void)shouldStandardizeURLsWithMultipleLeadingSlashes {
	RCResource *childOne = [self.service resource:@"child"];
	RCResource *childTwo = [self.service resource:@"///child"];
	
	STAssertEqualObjects([childOne.URL absoluteString], [childTwo.URL absoluteString], @"Should standardize URLs with mutliple leading slashes");	
}

- (void)shouldStandardizeURLsWithExtraSlashes {
	RCResource *ancestor = [self.service resource:@"ancestor"];
	RCResource *parent = [ancestor resource:@"parent"];
	RCResource *child = [parent resource:@"/child"];

	
	NSURL *fullURL = [[self.service  URL] URLByAppendingPathComponent:@"ancestor/parent/child"];
	STAssertEqualObjects([fullURL absoluteString], [child.URL absoluteString], @"Should standardize URLs with extra slashes");
}

- (void)shouldStandardizeURLsWithExtraDots {
	RCResource *ancestor = [self.service resource:@"ancestor"];
	RCResource *parent = [ancestor resource:@"parent"];
	RCResource *child = [parent resource:@"/../child"];
	
	
	NSURL *fullURL = [[self.service  URL] URLByAppendingPathComponent:@"ancestor/child"];
	STAssertEqualObjects([fullURL absoluteString], [child.URL absoluteString], @"Should standardize URLs with extra dots");
}

@end
