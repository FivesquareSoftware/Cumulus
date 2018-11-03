//
//  CMResourceNestingSpec.m
//  Cumulus
//
//  Created by John Clayton on 11/25/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceNestingSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"
#import "CMRequestQueue.h"

@import Nimble;

@interface CMResource (ResourceNestingSpecs)
@property (nonatomic, readonly) CMRequestQueue *requestQueue;
@end
@implementation CMResource (ResourceNestingSpecs)
@dynamic requestQueue;
@end


@implementation CMResourceNestingSpec


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
	self.service = [CMResource withURL:kTestServerHost];
	
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
	expect(fullURL).toWithDescription(equal([self.child URL]), @"Child URL should be parent URL plus child URL");
}

- (void)shouldStronglyReferenceParentResource {
	CMResource *ancestor = [self.service resource:@"ancestor"];
	CMResource *parent = [ancestor resource:@"parent"];
	CMResource *referencingChild = [parent resource:@"child"];

	ancestor = nil;
	expect(referencingChild.parent.parent).toNotWithDescription(beNil(),@"Ancestors should be strongly referenced by children");


	parent = nil;
	expect(referencingChild.parent).toNotWithDescription(beNil(),@"Parents should be strongly referenced by children");
}

// Headers

- (void)shouldInheritHeadersFromAllAncestors {
	[self.ancestor setValue:@"foo" forHeaderField:@"bar"];
	[self.parent setValue:@"baz" forHeaderField:@"bing"];
	[self.child setValue:@"ping" forHeaderField:@"pong"];
	
	NSMutableDictionary *headers = [NSMutableDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
	[headers setValue:@"baz" forKey:@"bing"];
	expect(self.parent.mergedHeaders).toWithDescription(equal(headers), @"Parent headers should equal parent headers merged with ancestor's headers");
	
	[headers setValue:@"ping" forKey:@"pong"];
	expect(self.child.mergedHeaders).toWithDescription(equal(headers), @"Child headers should equal child headers merged with all ancestor headers");
}

// Query

- (void)shouldInheritQueryFromAllAncestors {
	[self.ancestor setValue:@"foo" forQueryKey:@"bar"];
	[self.parent setValue:@"baz" forQueryKey:@"bing"];
	[self.child setValue:@"ping" forQueryKey:@"pong"];
	
	NSMutableDictionary *query = [NSMutableDictionary dictionaryWithObject:@"foo" forKey:@"bar"];
	[query setValue:@"baz" forKey:@"bing"];
	expect(self.parent.mergedQuery).toWithDescription(equal(query), @"Parent headers should equal parent headers merged with ancestor's headers");
	
	[query setValue:@"ping" forKey:@"pong"];
	expect(self.child.mergedQuery).toWithDescription(equal(query), @"Child headers should equal child headers merged with all ancestor headers");
}

// Auth

- (void)shouldInheritAuthProvidersFromAllParents {	
	CMBasicAuthProvider *one = [CMBasicAuthProvider withUsername:@"foo" password:@"bar"];
	CMBasicAuthProvider *two = [CMBasicAuthProvider withUsername:@"baz" password:@"bat"];
	CMBasicAuthProvider *three = [CMBasicAuthProvider withUsername:@"ping" password:@"pong"];
	
	[self.ancestor addAuthProvider:one];
	[self.parent addAuthProvider:two];

	NSMutableArray *providers = [NSMutableArray arrayWithObjects:two,one,nil];
	expect(self.parent.mergedAuthProviders).toWithDescription(equal(providers), @"Child should inherit merged providers from ancestors");

	[self.child addAuthProvider:three];

	providers = [NSMutableArray arrayWithObjects:three,two,one,nil];
	expect(self.child.mergedAuthProviders).toWithDescription(equal(providers), @"Child auth providers should be equal to child providers merged with all ancestor providers");
	
}

- (void)shouldUseOwnProvidersBeforeParentProviders {
	CMBasicAuthProvider *one = [CMBasicAuthProvider withUsername:@"foo" password:@"bar"];
	CMBasicAuthProvider *two = [CMBasicAuthProvider withUsername:@"baz" password:@"bat"];
	
	[self.parent addAuthProvider:two];
	
	NSMutableArray *providers = [NSMutableArray arrayWithObjects:two,nil];
	expect(self.child.mergedAuthProviders).toWithDescription(equal(providers), @"Child should inherit parent auth providers");
	
	[self.child addAuthProvider:one];

	providers = [NSMutableArray arrayWithObjects:one,two,nil];	
	expect(self.child.mergedAuthProviders).toWithDescription(equal(providers), @"Child providers should take precedence over ancestor providers");
}


// Timeout

- (void)shouldInheritTimeoutFromParent {
	self.parent.timeout = 30;
	expect(self.child.timeout == 30).toWithDescription(beTrue(), @"Child should inherit timeout from parent");
}

- (void)shouldUseOwnTimeoutOverParents {
	self.parent.timeout = 30;
	self.child.timeout = 60;
	expect(self.child.timeout == 60).toWithDescription(beTrue(), @"Child should use own timeout over parent's");
}

- (void)shouldInheritTimeoutFromFirstParentOnlyIfSet {
	self.child.timeout = 60;
	expect(self.child.timeout == 60).toWithDescription(beTrue(), @"Child should use parent's timeout only if set");
}

- (void)shouldInheritTimeoutFromAnyParent {
	self.ancestor.timeout = 30;
	expect(self.child.timeout == 30).toWithDescription(beTrue(), @"Child should inherit timeout from any parent");
}


// Content type

- (void)shouldInheritContentTypeFromParent {
	self.parent.contentType = CMContentTypeJSON;
	expect(self.child.contentType == CMContentTypeJSON).toWithDescription(beTrue(), @"Child should inherit content type from parent");
}

- (void)shouldUseOwnContentTypeOverParents {
	self.parent.contentType = CMContentTypeJSON;
	self.child.contentType = CMContentTypeXML;
	expect(self.child.contentType == CMContentTypeXML).toWithDescription(beTrue(), @"Child should use own content type over parent's");
}

- (void)shouldInheritContentTypeFromFirstParentOnlyIfSet {
	self.child.contentType = CMContentTypeJSON;
	expect(self.child.contentType == CMContentTypeJSON).toWithDescription(beTrue(), @"Child should use parent's content type only if set");
}

- (void)shouldInheritContentTypeFromAnyParent {
	self.ancestor.contentType = CMContentTypeJSON;
	expect(self.child.contentType == CMContentTypeJSON).toWithDescription(beTrue(), @"Child should inherit content type from any parent");
}

// Preflight block


- (void)shouldInheritPreflightBlockFromParent {
	CMPreflightBlock block = ^(CMRequest *request) { return NO; };
	self.parent.preflightBlock = block;
	expect((id)self.child.preflightBlock).toWithDescription(equal((id)block), @"Child should inherit preflight block from parent");
}

- (void)shouldUseOwnPreflightBlockOverParents {
	CMPreflightBlock blockOne = ^(CMRequest *request) { 
		NSLog(@"One");
		return NO; 
	};
	CMPreflightBlock blockTwo = ^(CMRequest *request) { 
		NSLog(@"Two");
		return NO; 
	};
	self.parent.preflightBlock = blockOne;
	self.child.preflightBlock = blockTwo;
	expect((id)self.child.preflightBlock).toWithDescription(equal((id)blockTwo), @"Child should prefer own preflight block over parent's");
}

- (void)shouldInheritPreflightBlockFromFirstParentOnlyIfSet {
	CMPreflightBlock block = ^(CMRequest *request) { return NO; };
	self.child.preflightBlock = block;
	expect((id)self.child.preflightBlock).toWithDescription(equal((id)block), @"Child should inherit preflight block from parent only if set");
}

- (void)shouldInheritPreflightBlockFromAnyParent {
	CMPreflightBlock block = ^(CMRequest *request) { return NO; };
	self.ancestor.preflightBlock = block;
	expect((id)self.child.preflightBlock).toWithDescription(equal((id)block), @"Child should inherit preflight block from any parent");
}

// Postprocessor block

- (void)shouldInheritPotsprocessorBlockFromParent {
	CMPostProcessorBlock block = ^(CMResponse *response, id result) { return result; };
	self.parent.postProcessorBlock = block;
	expect((id)self.child.postProcessorBlock).toWithDescription(equal((id)block), @"Child should inherit postprocessor block from parent");
}

- (void)shouldUseOwnPotsprocessorBlockOverParents {
	CMPostProcessorBlock blockOne = ^(CMResponse *response, id result) { 
		NSLog(@"One");
		return result; 
	};
	CMPostProcessorBlock blockTwo = ^(CMResponse *response, id result) { 
		NSLog(@"Two");
		return result; 
	};
	self.parent.postProcessorBlock = blockOne;
	self.child.postProcessorBlock = blockTwo;
	expect((id)self.child.postProcessorBlock).toWithDescription(equal((id)blockTwo), @"Child should prefer own postprocessor block over parent's");
}

- (void)shouldInheritPotsprocessorBlockFromFirstParentOnlyIfSet {
	CMPostProcessorBlock block = ^(CMResponse *response, id result) { return result; };
	self.child.postProcessorBlock = block;
	expect((id)self.child.postProcessorBlock).toWithDescription(equal((id)block), @"Child should inherit postprocessor block from parent only if set");
}

- (void)shouldInheritPotsprocessorBlockFromAnyParent {
	CMPostProcessorBlock block = ^(CMResponse *response, id result) { return result; };
	self.ancestor.postProcessorBlock = block;
	expect((id)self.child.postProcessorBlock).toWithDescription(equal((id)block), @"Child should inherit postprocessor block from any parent");
}

// Caching

- (void)shouldInheritCachePolicyFromParent {
	self.parent.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	expect(self.child.cachePolicy == NSURLRequestReloadIgnoringCacheData).toWithDescription(beTrue(), @"Child should inherit cache policy from parent");
}

- (void)shouldUseOwnCachePolicyOverParents {
	self.parent.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
	self.child.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	expect(self.child.cachePolicy == NSURLRequestReloadIgnoringCacheData).toWithDescription(beTrue(), @"Child should use own cache policy over parent's");
}

- (void)shouldInheritCachePolicyFromFirstParentOnlyIfSet {
	self.child.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	expect(self.child.cachePolicy == NSURLRequestReloadIgnoringCacheData).toWithDescription(beTrue(), @"Child should use parent's cache policy only if set");
}

- (void)shouldInheritCachePolicyFromAnyParent {
	self.ancestor.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	expect(self.child.cachePolicy == NSURLRequestReloadIgnoringCacheData).toWithDescription(beTrue(), @"Child should inherit cache policy from any parent");
}

// Max Concurrent Requests

- (void)shouldInheritMaxConcurrentRequestsFromParent {
	self.parent.maxConcurrentRequests = 5;
	expect(self.child.maxConcurrentRequests == 5).toWithDescription(beTrue(), @"Child should inherit maxConcurrentRequests from parent");
}

- (void)shouldUseOwnMaxConcurrentRequestsOverParents {
	self.parent.maxConcurrentRequests = 5;
	self.child.maxConcurrentRequests = 10;
	expect(self.child.maxConcurrentRequests == 10).toWithDescription(beTrue(), @"Child should use own maxConcurrentRequests over parent's");
}

- (void)shouldInheritMaxConcurrentRequestsFromFirstParentOnlyIfSet {
	self.child.maxConcurrentRequests = 10;
	expect(self.child.maxConcurrentRequests == 10).toWithDescription(beTrue(), @"Child should use parent's maxConcurrentRequests only if set");
}

- (void)shouldInheritMaxConcurrentRequestsFromAnyParent {
	self.ancestor.maxConcurrentRequests = 5;
	expect(self.child.maxConcurrentRequests == 5).toWithDescription(beTrue(), @"Child should inherit maxConcurrentRequests from any parent");
}

- (void)shouldInheritRequestQueueFromParent {
	self.parent.maxConcurrentRequests = 5;
	CMRequestQueue *parentRequestQueue = self.parent.requestQueue;
	CMRequestQueue *childRequestQueue = self.child.requestQueue;
	expect(parentRequestQueue).toWithDescription(equal(childRequestQueue), @"Child should inherit requestQueue from parent");
}

- (void)shouldUseOwnRequestQueueOverParents {
	self.parent.maxConcurrentRequests = 5;
	self.child.maxConcurrentRequests = 10;
	CMRequestQueue *parentRequestQueue = self.parent.requestQueue;
	CMRequestQueue *childRequestQueue = self.child.requestQueue;
	expect(parentRequestQueue).toNotWithDescription(beNil(),@"Parent must have a request queue for this test");
	expect(parentRequestQueue == childRequestQueue).toWithDescription(beFalse(), @"Child should use own requestQueue over parent's");
}

- (void)shouldInheritRequestQueueFromAnyAncestor {
	self.ancestor.maxConcurrentRequests = 5;
	CMRequestQueue *ancestorRequestQueue = self.ancestor.requestQueue;
	CMRequestQueue *childRequestQueue = self.child.requestQueue;
	expect(ancestorRequestQueue).toWithDescription(equal(childRequestQueue), @"Child should inherit requestQueue from any parent");
}

- (void)shouldUseOwnRequestQueueOverAncestors {
	self.ancestor.maxConcurrentRequests = 5;
	self.child.maxConcurrentRequests = 10;
	CMRequestQueue *ancestorRequestQueue = self.ancestor.requestQueue;
	CMRequestQueue *childRequestQueue = self.child.requestQueue;
	expect(ancestorRequestQueue).toNotWithDescription(beNil(),@"Ancestor must have a request queue for this test");
	expect(ancestorRequestQueue == childRequestQueue).toWithDescription(beFalse(), @"Child should use own requestQueue over ancestor's");
}

- (void) shouldInheritANilRequestQueueWFromParent {
	self.parent.maxConcurrentRequests = 0;
	expect(self.child.requestQueue).toWithDescription(beNil(), @"Child should inherit a nil requestQueue from parent");
}

- (void) shouldInheritANilRequestQueueWFromAnyAncestor {
	self.ancestor.maxConcurrentRequests = 0;
	expect(self.child.requestQueue).toWithDescription(beNil(), @"Child should inherit a nil requestQueue from ancestors");
}


@end
