//
//  CMResourceConfigSpec.m
//  Cumulus
//
//  Created by John Clayton on 10/8/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceConfigSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMResourceConfigSpec

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
	self.service = [CMResource withURL:kTestServerHost];
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
	CMResource *resource = [self.service resource:@"abc123"];
	NSURL *URL = [[self.service  URL] URLByAppendingPathComponent:@"abc123"];
	STAssertEqualObjects(resource.URL, URL, @"URL should contain string arg");
}

- (void) shouldConstructResourcesUsingNumbers {
	CMResource *resource = [self.service resource:[NSNumber numberWithInt:123]];
	NSURL *URL = [[self.service  URL] URLByAppendingPathComponent:@"123"];
	STAssertEqualObjects(resource.URL, URL, @"URL should contain resource number");
}

- (void) shouldConstructResourcesUsingFormatStrings {
	CMResource *resource = [self.service resourceWithFormat:@"abc%@",[NSNumber numberWithInt:123]];
	NSURL *URL = [[self.service  URL] URLByAppendingPathComponent:@"abc123"];
	STAssertEqualObjects(resource.URL, URL, @"URL should contain resource format and arguments");
}

- (void)shouldSetJSONContentTypeHeadersCorrectly {
	CMResource *resource = [self.service resource:@"test"];
	resource.contentType = CMContentTypeJSON;
	
	NSDictionary *headers = [NSDictionary dictionaryWithObjectsAndKeys:
							 @"application/json", kCumulusHTTPHeaderContentType
							 , @"application/json", kCumulusHTTPHeaderAccept
							 , nil];
	STAssertEqualObjects(resource.headers, headers, @"Should set resource headsers from content type");
}

- (void)shouldCreateAuthProviderFromUsernameAndPassword {
	CMResource *resource = [self.service resource:@"test"];
	resource.username = @"foo";
	resource.password = @"bar";
	
	CMBasicAuthProvider *provider = [CMBasicAuthProvider withUsername:@"foo" password:@"bar"];
	
	STAssertNotNil([resource.mergedAuthProviders lastObject], @"Default auth provider should not be nil");
	STAssertEqualObjects([resource.mergedAuthProviders lastObject], provider, @"Providers should contain the BASIC provider");
}

- (void)shouldStandardizeURLsWithLeadingSlashes {
	CMResource *childOne = [self.service resource:@"child"];
	CMResource *childTwo = [self.service resource:@"/child"];

	STAssertEqualObjects([childOne.URL absoluteString], [childTwo.URL absoluteString], @"Should standardize URLs with leading slashes");	
}

- (void)shouldStandardizeURLsWithMultipleLeadingSlashes {
	CMResource *childOne = [self.service resource:@"child"];
	CMResource *childTwo = [self.service resource:@"///child"];
	
	STAssertEqualObjects([childOne.URL absoluteString], [childTwo.URL absoluteString], @"Should standardize URLs with mutliple leading slashes");	
}

- (void)shouldStandardizeURLsWithExtraSlashes {
	CMResource *ancestor = [self.service resource:@"ancestor"];
	CMResource *parent = [ancestor resource:@"parent"];
	CMResource *child = [parent resource:@"/child"];

	
	NSURL *fullURL = [[self.service  URL] URLByAppendingPathComponent:@"ancestor/parent/child"];
	STAssertEqualObjects([fullURL absoluteString], [child.URL absoluteString], @"Should standardize URLs with extra slashes");
}

- (void)shouldStandardizeURLsWithExtraDots {
	CMResource *ancestor = [self.service resource:@"ancestor"];
	CMResource *parent = [ancestor resource:@"parent"];
	CMResource *child = [parent resource:@"/../child"];
	
	
	NSURL *fullURL = [[self.service  URL] URLByAppendingPathComponent:@"ancestor/child"];
	STAssertEqualObjects([fullURL absoluteString], [child.URL absoluteString], @"Should standardize URLs with extra dots");
}

- (void) shouldCorrectlyInitializeFromURLWithQueryString {
	CMResource *resource = [CMResource withURL:@"http://example.com?foo==bar"];
	NSString *URLString = @"http://example.com?foo==bar";
	STAssertEqualObjects([resource.URL absoluteString], URLString, @"URL with query string should be equal to URL string");
}

- (void) shouldParseQueryStringProperly {
	CMResource *resource = [self.service resource:@"resource"];
	CMResource *childWithQueryString = [resource resource:@"child?foo=bar"];
	
	STAssertEqualObjects(@"foo=bar", childWithQueryString.queryString, @"Should properly append a query string");
}

- (void) shouldConvertNonStringHeaderFieldValuesToStrings {
	CMResource *resource = [self.service resource:@"abc123"];
	[resource setValue:[NSNumber numberWithInt:42] forHeaderField:@"Foo"];
	id headerField = [resource valueForHeaderField:@"Foo"];
	STAssertTrue([headerField isKindOfClass:[NSString class]], @"Header fields should be converted to strings");
}

@end
