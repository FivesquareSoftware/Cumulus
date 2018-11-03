//
//  CMResourceQuerySpec.m
//  Cumulus
//
//  Created by John Clayton on 1/5/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceQuerySpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


@import Nimble;


@implementation CMResourceQuerySpec


+ (NSString *)description {
	return @"Query Handling";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
	// set up resources common to all examples here
}

- (void)beforeEach {
	// set up resources that need to be initialized before each example here 
	self.service = [CMResource withURL:kTestServerHost];
	self.service.contentType = CMContentTypeJSON;
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


- (void) shouldAppendQueryArgumentAsQueryString {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	CMResponse *response = [resource getWithQuery:query];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	expect(query).toWithDescription(equal(response.result), [NSString stringWithFormat:@"Result should equal sent params:%@",response.result]);
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldAppendQueryArgumentToAnExistingQueryString {
	CMResource *resource = [self.service resource:@"test/query?key=value"];
	CMResponse *response = [resource getWithQuery:@{ @"foo" : @"bar" }];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	NSDictionary *mergedQuery = @{ @"key": @"value", @"foo" : @"bar" };
	expect(mergedQuery).toWithDescription(equal(response.result), [NSString stringWithFormat:@"Result should equal sent params:%@",response.result]);
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"key=value&foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldUseMergedQuery {
	CMResource *parent = [self.service resource:@"test"];
	[parent setValue:@"pong" forQueryKey:@"ping"];
	
	CMResource *resource = [parent resource:@"query"];
	[resource setValue:@"bar" forQueryKey:@"foo"];
	
	NSDictionary *query = @{ @"ping": @"pong", @"foo" : @"bar" };
	
	expect([resource.mergedQuery isEqualToDictionary:query]).toWithDescription(beTrue(), @"Resource should use merged headers for requests");
	
	CMResponse *response = [resource get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	expect([resource.mergedQuery isEqualToDictionary:response.result]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Result should equal sent params:%@",response.result]);
	NSString *queryString = [[response.request.URLRequest URL] query];
//	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
	expect([queryString rangeOfString:@"foo=bar"].location != NSNotFound).toWithDescription(beTrue(), @"Request URL should contain child params");
	expect([queryString rangeOfString:@"ping=pong"].location != NSNotFound).toWithDescription(beTrue(), @"Request URL should contain parent params");
}

- (void) shouldGetWithQueryAttribute {
	CMResource *resource = [self.service resource:@"test/query"];
	[resource setValue:@"bar" forQueryKey:@"foo"];
	CMResponse *response = [resource get];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	expect(resource.query).toWithDescription(equal(response.result), [NSString stringWithFormat:@"Result should equal sent params:%@",response.result]);
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldGetWithQueryArgumentAndBlocks {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource getWithQuery:query progressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
		
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	expect(query).toWithDescription(equal(localResponse.result), [NSString stringWithFormat:@"Result should equal sent params:%@",localResponse.result]);
	NSString *queryString = [[localResponse.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldHeadWithQueryAttribute {
	CMResource *resource = [self.service resource:@"test/query"];
	[resource setValue:@"bar" forQueryKey:@"foo"];
	CMResponse *response = [resource head];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldHeadWithQueryArgument {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	CMResponse *response = [resource headWithQuery:query];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldHeadWithQueryArgumentAndBlocks {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource headWithQuery:query completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
		
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	NSString *queryString = [[localResponse.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldDeleteWithQueryAttribute {
	CMResource *resource = [self.service resource:@"test/query"];
	[resource setValue:@"bar" forQueryKey:@"foo"];
	CMResponse *response = [resource delete];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	expect(resource.query).toWithDescription(equal(response.result), [NSString stringWithFormat:@"Result should equal sent params:%@",response.result]);
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldPostWithQueryAttribute {
	CMResource *resource = [self.service resource:@"test/query"];
	[resource setValue:@"bar" forQueryKey:@"foo"];
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"ping" forKey:@"pong"];
	
	NSMutableDictionary *combinedParams = [NSMutableDictionary dictionaryWithDictionary:resource.query];
	[combinedParams addEntriesFromDictionary:payload];
	
	CMResponse *response = [resource post:payload];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	expect(combinedParams).toWithDescription(equal(response.result), [NSString stringWithFormat:@"Result should equal combined payload and query params:%@",response.result]);
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);

}

- (void) shouldPutWithQueryAttribute {
	CMResource *resource = [self.service resource:@"test/query"];
	[resource setValue:@"bar" forQueryKey:@"foo"];
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"ping" forKey:@"pong"];
	
	NSMutableDictionary *combinedParams = [NSMutableDictionary dictionaryWithDictionary:resource.query];
	[combinedParams addEntriesFromDictionary:payload];
	
	CMResponse *response = [resource put:payload];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	expect(combinedParams).toWithDescription(equal(response.result), [NSString stringWithFormat:@"Result should equal combined payload and query params:%@",response.result]);
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"foo=bar").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}

- (void) shouldMergeQueryStringArgumentWithQueryAttribute {
	CMResource *resource = [self.service resource:@"test/query"];
	[resource setValue:@"bar" forQueryKey:@"foo"];
	NSDictionary *argument = @{ @"ping" : @"pong" };
	
	NSMutableDictionary *combinedParams = [NSMutableDictionary dictionaryWithDictionary:resource.query];
	[combinedParams addEntriesFromDictionary:argument];
	
	CMResponse *response = [resource getWithQuery:argument];
	expect(response.wasSuccessful).toWithDescription(beTrue(), @"Response should succeed");
	expect(combinedParams).toWithDescription(equal(response.result), [NSString stringWithFormat:@"Result should equal combined query argument and query attribute:%@",response.result]);
	NSString *queryString = [[response.request.URLRequest URL] query];
	expect(@"foo=bar&ping=pong").toWithDescription(equal(queryString), [NSString stringWithFormat:@"Request URL query should equal expected query string: %@", queryString]);
}



@end
