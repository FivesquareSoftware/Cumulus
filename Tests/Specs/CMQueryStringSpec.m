//
//  CMQueryStringSpec.m
//  Cumulus
//
//  Created by John Clayton on 1/5/12.
//  Copyright 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMQueryStringSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMQueryStringSpec

@synthesize service;

+ (NSString *)description {
    return @"Query String Handling";
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
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

- (void) shouldAppendQueryStringValuesAndKeys {
	CMResource *resource = [self.service resource:@"test/query"];
	CMResponse *response = [resource getWithQuery:[NSArray arrayWithObjects:@"foo",@"bar",nil]];
	STAssertTrue(response.success, @"Response should succeed");
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	STAssertEqualObjects(query, response.result, @"Result should equal sent params:%@",response.result);
	NSString *queryString = [[response.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldAppendArrayAsCollectionToQueryString {
	CMResource *resource = [self.service resource:@"test/query"];
	NSArray *arrayParam = [NSArray arrayWithObjects:@"1", @"2", nil];
	CMResponse *response = [resource getWithQuery:[NSArray arrayWithObjects:@"foo",arrayParam,nil]];
	STAssertTrue(response.success, @"Response should succeed");
	NSDictionary *params = [NSDictionary dictionaryWithObjectsAndKeys:arrayParam, @"foo", nil];
	STAssertEqualObjects(params, response.result, @"Result should equal sent params:%@",response.result);
//	NSString *queryString = [[response.request.URLRequest URL] query];
//	STAssertEqualObjects(@"foo[]=1&foo[]=2", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldAppendDictionaryAsQueryString {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	CMResponse *response = [resource getWithQuery:query];
	STAssertTrue(response.success, @"Response should succeed");
	STAssertEqualObjects(query, response.result, @"Result should equal sent params:%@",response.result);
	NSString *queryString = [[response.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldDropQueryObjectsFollowingDictionary {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	CMResponse *response = [resource getWithQuery:[NSArray arrayWithObjects:query,@"bad",@"news",nil]];
	STAssertTrue(response.success, @"Response should succeed");
	STAssertEqualObjects(query, response.result, @"Result should equal sent params:%@",response.result);
	NSString *queryString = [[response.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldAppendQueryArgumentToAnExistingQueryString {
	CMResource *resource = [self.service resource:@"test/query?key=value"];
	CMResponse *response = [resource getWithQuery:[NSArray arrayWithObjects:@"foo",@"bar",nil]];
	STAssertTrue(response.success, @"Response should succeed");
	NSDictionary *query = [NSDictionary dictionaryWithObjectsAndKeys:@"value",@"key",@"bar",@"foo",nil];
	STAssertEqualObjects(query, response.result, @"Result should equal sent params:%@",response.result);
	NSString *queryString = [[response.request.URLRequest URL] query];
	STAssertEqualObjects(@"key=value&foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldReturnQueryStringAsADictionary {
    CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = @{ @"foo" : @"bar" };
	CMResponse *response = [resource getWithQuery:query];

	NSDictionary *requestQueryDictionary = [response.request queryDictionary];
    STAssertTrue([query isEqualToDictionary:requestQueryDictionary], @"Request query dictionary should equal sent dictionary");
}

- (void) shouldGetWithQueryAndBlocks {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource getWithProgressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	} query:query];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.success, @"Response should succeed");
	STAssertEqualObjects(query, localResponse.result, @"Result should equal sent params:%@",localResponse.result);
	NSString *queryString = [[localResponse.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldHeadWithQuery {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	CMResponse *response = [resource headWithQuery:query];
	STAssertTrue(response.success, @"Response should succeed");
	NSString *queryString = [[response.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldHeadWithQueryAndBlocks {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource headWithCompletionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	} query:query];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.success, @"Response should succeed");
	NSString *queryString = [[localResponse.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldDeleteWithQuery {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	CMResponse *response = [resource deleteWithQuery:query];
	STAssertTrue(response.success, @"Response should succeed");
	STAssertEqualObjects(query, response.result, @"Result should equal sent params:%@",response.result);
	NSString *queryString = [[response.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldDeleteWithQueryAndBlocks {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource getWithCompletionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	} query:query];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.success, @"Response should succeed");
	STAssertEqualObjects(query, localResponse.result, @"Result should equal sent params:%@",localResponse.result);
	NSString *queryString = [[localResponse.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldPostWithQuery {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"ping" forKey:@"pong"];
	
	NSMutableDictionary *combinedParams = [NSMutableDictionary dictionaryWithDictionary:query];
	[combinedParams addEntriesFromDictionary:payload];
	
	CMResponse *response = [resource post:payload withQuery:query];
	STAssertTrue(response.success, @"Response should succeed");
	STAssertEqualObjects(combinedParams, response.result, @"Result should equal combined payload and query params:%@",response.result);
	NSString *queryString = [[response.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldPostWithQueryAndBlocks {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"ping" forKey:@"pong"];
	
	NSMutableDictionary *combinedParams = [NSMutableDictionary dictionaryWithDictionary:query];
	[combinedParams addEntriesFromDictionary:payload];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource post:payload withProgressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	} query:query];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.success, @"Response should succeed");
	STAssertEqualObjects(combinedParams, localResponse.result, @"Result should equal combined payload and query params:%@",localResponse.result);
	NSString *queryString = [[localResponse.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldPutWithQuery {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"ping" forKey:@"pong"];
	
	NSMutableDictionary *combinedParams = [NSMutableDictionary dictionaryWithDictionary:query];
	[combinedParams addEntriesFromDictionary:payload];
	
	CMResponse *response = [resource put:payload withQuery:query];
	STAssertTrue(response.success, @"Response should succeed");
	STAssertEqualObjects(combinedParams, response.result, @"Result should equal combined payload and query params:%@",response.result);
	NSString *queryString = [[response.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}

- (void) shouldPutWithQueryAndBlocks {
	CMResource *resource = [self.service resource:@"test/query"];
	NSDictionary *query = [NSDictionary dictionaryWithObject:@"bar" forKey:@"foo"];
	NSDictionary *payload = [NSDictionary dictionaryWithObject:@"ping" forKey:@"pong"];
	
	NSMutableDictionary *combinedParams = [NSMutableDictionary dictionaryWithDictionary:query];
	[combinedParams addEntriesFromDictionary:payload];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[resource put:payload withProgressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	} query:query];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.success, @"Response should succeed");
	STAssertEqualObjects(combinedParams, localResponse.result, @"Result should equal combined payload and query params:%@",localResponse.result);
	NSString *queryString = [[localResponse.request.URLRequest URL] query];
	STAssertEqualObjects(@"foo=bar", queryString, @"Request URL query should equal expected query string: %@", queryString);
}



@end
