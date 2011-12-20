//
//  RCResourceNestingSpec.m
//  RESTClient
//
//  Created by John Clayton on 11/25/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCResourceNestingSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCResourceNestingSpec

@synthesize service;
@synthesize ancestor;
@synthesize parent;
@synthesize child;

+ (NSString *)description {
    return @"Resource Nesting";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
	self.service = [RCResource withURL:kTestServerHost];
	
	self.ancestor = [self.service resource:@"ancestor"];
	self.parent = [self.ancestor resource:@"parent"];
	self.child = [self.parent resource:@"child"];

}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

- (void)shouldProperlyBuildNestedURLs {
	NSURL *fullURL = [[self.service  URL] URLByAppendingPathComponent:@"ancestor/parent/child"];
	STAssertEqualObjects(fullURL, [self.child URL], @"Child URL should be parent URL plus child URL");
}

- (void)shouldStronglyReferenceParentResource {
	__weak RCResource *weakAncestor = [self.service resource:@"ancestor"];
	__weak RCResource *weakParent = [weakAncestor resource:@"parent"];
	RCResource *referencingChild = [weakParent resource:@"child"];

	weakAncestor = nil;
	STAssertNotNil(referencingChild.parent.parent, @"Ancetors should be strongly referenced by children");

	weakParent = nil;
	STAssertNotNil(referencingChild.parent, @"Parents should be strongly referenced by children");
}

// Headers

- (void)shouldInheritHeadersFromAllAncestors {
	[self.ancestor setValue:@"foo" forHeaderField:@"bar"];
	[self.parent setValue:@"baz" forHeaderField:@"bing"];
	[self.child setValue:@"ping" forHeaderField:@"pong"];
	
	NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
	[headers setValue:@"baz" forKey:@"bing"];
	STAssertEqualObjects(self.parent.mergedHeaders, headers, @"Parent headers should equal parent headers merged with ancestor's headers");
	
	[headers setValue:@"ping" forKey:@"pong"];
	STAssertEqualObjects(self.child.mergedHeaders, headers, @"Child headers should equal child headers merged with all ancestor headers");
}

// Auth

- (void)shouldInheritAuthProvidersFromAllParents {	
	RCBasicAuthProvider *one = [RCBasicAuthProvider withUsername:@"foo" password:@"bar"];
	RCBasicAuthProvider *two = [RCBasicAuthProvider withUsername:@"baz" password:@"bat"];
	RCBasicAuthProvider *three = [RCBasicAuthProvider withUsername:@"ping" password:@"pong"];
	
	[self.ancestor addAuthProvider:one];
	[self.parent addAuthProvider:two];

	NSMutableArray *providers = [NSMutableArray arrayWithObjects:two,one,nil];
	STAssertEqualObjects(self.parent.mergedAuthProviders, providers, @"Child should inherit merged providers from ancestors");

	[self.child addAuthProvider:three];

	providers = [NSMutableArray arrayWithObjects:three,two,one,nil];
	STAssertEqualObjects(self.child.mergedAuthProviders, providers, @"Child auth providers should be equal to child providers merged with all ancestor providers");
	
}

- (void)shouldUseOwnProvidersBeforeParentProviders {
	RCBasicAuthProvider *one = [RCBasicAuthProvider withUsername:@"foo" password:@"bar"];
	RCBasicAuthProvider *two = [RCBasicAuthProvider withUsername:@"baz" password:@"bat"];
	
	[self.parent addAuthProvider:two];
	
	NSMutableArray *providers = [NSMutableArray arrayWithObjects:two,nil];
	STAssertEqualObjects(self.child.mergedAuthProviders, providers, @"Child should inherit parent auth providers");
	
	[self.child addAuthProvider:one];

	providers = [NSMutableArray arrayWithObjects:one,two,nil];	
	STAssertEqualObjects(self.child.mergedAuthProviders, providers, @"Child providers should take precedence over ancestor providers");
}


// Timeout

- (void)shouldInheritTimeoutFromParent {
	self.parent.timeout = 30;
	STAssertTrue(self.child.timeout == 30, @"Child should inherit timeout from parent");
}

- (void)shouldUseOwnTimeoutOverParents {
	self.parent.timeout = 30;
	self.child.timeout = 60;
	STAssertTrue(self.child.timeout == 60, @"Child should use own timeout over parent's");
}

- (void)shouldInheritTimeoutFromFirstParentOnlyIfSet {
	self.child.timeout = 60;
	STAssertTrue(self.child.timeout == 60, @"Child should use parent's timeout only if set");
}

- (void)shouldInheritTimeoutFromAnyParent {
	self.ancestor.timeout = 30;
	STAssertTrue(self.child.timeout == 30, @"Child should inherit timeout from any parent");
}


// Content type

- (void)shouldInheritContentTypeFromParent {
	self.parent.contentType = RESTClientContentTypeJSON;
	STAssertTrue(self.child.contentType == RESTClientContentTypeJSON, @"Child should inherit content type from parent");
}

- (void)shouldUseOwnContentTypeOverParents {
	self.parent.contentType = RESTClientContentTypeJSON;
	self.child.contentType = RESTClientContentTypeXML;
	STAssertTrue(self.child.contentType == RESTClientContentTypeXML, @"Child should use own content type over parent's");
}

- (void)shouldInheritContentTypeFromFirstParentOnlyIfSet {
	self.child.contentType = RESTClientContentTypeJSON;
	STAssertTrue(self.child.contentType == RESTClientContentTypeJSON, @"Child should use parent's content type only if set");
}

- (void)shouldInheritContentTypeFromAnyParent {
	self.ancestor.contentType = RESTClientContentTypeJSON;
	STAssertTrue(self.child.contentType == RESTClientContentTypeJSON, @"Child should inherit content type from any parent");
}

// Preflight block


- (void)shouldInheritPreflightBlockFromParent {
	RCPreflightBlock block = ^(RCRequest *request) { return NO; };
	self.parent.preflightBlock = block;
	STAssertEqualObjects(self.child.preflightBlock, block, @"Child should inherit preflight block from parent");
}

- (void)shouldUseOwnPreflightBlockOverParents {
	RCPreflightBlock blockOne = ^(RCRequest *request) { 
		NSLog(@"One");
		return NO; 
	};
	RCPreflightBlock blockTwo = ^(RCRequest *request) { 
		NSLog(@"Two");
		return NO; 
	};
	self.parent.preflightBlock = blockOne;
	self.child.preflightBlock = blockTwo;
	STAssertEqualObjects(self.child.preflightBlock, blockTwo, @"Child should prefer own preflight block over parent's");
}

- (void)shouldInheritPreflightBlockFromFirstParentOnlyIfSet {
	RCPreflightBlock block = ^(RCRequest *request) { return NO; };
	self.child.preflightBlock = block;
	STAssertEqualObjects(self.child.preflightBlock, block, @"Child should inherit preflight block from parent only if set");
}

- (void)shouldInheritPreflightBlockFromAnyParent {
	RCPreflightBlock block = ^(RCRequest *request) { return NO; };
	self.ancestor.preflightBlock = block;
	STAssertEqualObjects(self.child.preflightBlock, block, @"Child should inherit preflight block from any parent");
}

// Postprocessor block

- (void)shouldInheritPotsprocessorBlockFromParent {
	RCPostProcessorBlock block = ^(RCResponse *response, id result) { return result; };
	self.parent.postProcessorBlock = block;
	STAssertEqualObjects(self.child.postProcessorBlock, block, @"Child should inherit postprocessor block from parent");
}

- (void)shouldUseOwnPotsprocessorBlockOverParents {
	RCPostProcessorBlock blockOne = ^(RCResponse *response, id result) { 
		NSLog(@"One");
		return result; 
	};
	RCPostProcessorBlock blockTwo = ^(RCResponse *response, id result) { 
		NSLog(@"Two");
		return result; 
	};
	self.parent.postProcessorBlock = blockOne;
	self.child.postProcessorBlock = blockTwo;
	STAssertEqualObjects(self.child.postProcessorBlock, blockTwo, @"Child should prefer own postprocessor block over parent's");
}

- (void)shouldInheritPotsprocessorBlockFromFirstParentOnlyIfSet {
	RCPostProcessorBlock block = ^(RCResponse *response, id result) { return result; };
	self.child.postProcessorBlock = block;
	STAssertEqualObjects(self.child.postProcessorBlock, block, @"Child should inherit postprocessor block from parent only if set");
}

- (void)shouldInheritPotsprocessorBlockFromAnyParent {
	RCPostProcessorBlock block = ^(RCResponse *response, id result) { return result; };
	self.ancestor.postProcessorBlock = block;
	STAssertEqualObjects(self.child.postProcessorBlock, block, @"Child should inherit postprocessor block from any parent");
}

// Caching

- (void)shouldInheritCachePolicyFromParent {
	self.parent.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	STAssertTrue(self.child.cachePolicy == NSURLRequestReloadIgnoringLocalAndRemoteCacheData, @"Child should inherit cache policy from parent");
}

- (void)shouldUseOwnCachePolicyOverParents {
	self.parent.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	self.child.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	STAssertTrue(self.child.cachePolicy == NSURLRequestReloadIgnoringLocalAndRemoteCacheData, @"Child should use own cache policy over parent's");
}

- (void)shouldInheritCachePolicyFromFirstParentOnlyIfSet {
	self.child.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	STAssertTrue(self.child.cachePolicy == NSURLRequestReloadIgnoringLocalAndRemoteCacheData, @"Child should use parent's cache policy only if set");
}

- (void)shouldInheritCachePolicyFromAnyParent {
	self.ancestor.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	STAssertTrue(self.child.cachePolicy == NSURLRequestReloadIgnoringLocalAndRemoteCacheData, @"Child should inherit cache policy from any parent");
}



@end
