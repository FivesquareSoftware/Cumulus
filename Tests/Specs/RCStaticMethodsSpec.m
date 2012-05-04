//
//  RCStaticMethodsSpec.m
//  RESTClient
//
//  Created by John Clayton on 11/26/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCStaticMethodsSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCStaticMethodsSpec

+ (NSString *)description {
    return @"Static Routes";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
	[RESTClient setHeaders:[NSMutableDictionary dictionaryWithObjectsAndKeys:
							@"application/json", kRESTClientHTTPHeaderContentType
							, @"application/json", kRESTClientHTTPHeaderAccept
							, nil]];
	[RESTClient setAuthProviders:nil];
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
	[self.specHelper cleanCaches];

}

// ========================================================================== //

#pragma mark - Specs

- (void) shouldSetHeaders {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    RCResponse *response = [RESTClient get:endpoint];
	STAssertEqualObjects(response.request.headers, [RESTClient headers], @"Request haeaders should equal static headers");
}

- (void)shouldBeAuthorized {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/protected",kTestServerHost];
    RCBasicAuthProvider *authProvider = [RCBasicAuthProvider withUsername:@"test" password:@"test"];
	[RESTClient setAuthProviders:[NSMutableArray arrayWithObject:authProvider]];
    RCResponse *response = [RESTClient get:endpoint];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void)shouldGet {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    RCResponse *response = [RESTClient get:endpoint];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void)shouldGetWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[RESTClient get:endpoint withCompletionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldGetWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
		NSLog(@"progress: %@",progress);
	};

	RCCompletionBlock completionBlock = ^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	[RESTClient get:endpoint withProgressBlock:progressBlock completionBlock:completionBlock];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldHead {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    RCResponse *response = [RESTClient head:endpoint];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void)shouldHeadWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[RESTClient head:endpoint withCompletionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldDelete {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    RCResponse *response = [RESTClient delete:endpoint];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void)shouldDeleteWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[RESTClient delete:endpoint withCompletionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldPost {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    RCResponse *response = [RESTClient post:endpoint payload:self.specHelper.item];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void)shouldPostWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[RESTClient post:endpoint payload:self.specHelper.item withCompletionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldPostWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
		NSLog(@"progress: %@",progress);
	};
	
	RCCompletionBlock completionBlock = ^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	[RESTClient post:endpoint payload:self.specHelper.item withProgressBlock:progressBlock completionBlock:completionBlock];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldPut {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    RCResponse *response = [RESTClient put:endpoint payload:self.specHelper.item];
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void)shouldPutWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[RESTClient put:endpoint payload:self.specHelper.item withCompletionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldPutWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
		NSLog(@"progress: %@",progress);
	};
	
	RCCompletionBlock completionBlock = ^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	[RESTClient put:endpoint payload:self.specHelper.item withProgressBlock:progressBlock completionBlock:completionBlock];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldDownloadWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/download/hero",kTestServerHost];

	RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
		NSLog(@"progress: %@",progress);
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	RCCompletionBlock completionBlock = ^(RCResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[RESTClient download:endpoint withProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	
	STAssertTrue(localResponse.success, @"Response should have succeeded: %@", localResponse);
}

- (void)shouldUploadWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/upload/hero",kTestServerHost];

	
	RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
		NSLog(@"progress: %@",progress);
	};
	
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	RCCompletionBlock completionBlock = ^(RCResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"t_hero" ofType:@"png"];
	NSURL *fileURL = [NSURL fileURLWithPath:filePath];
	[RESTClient uploadFile:fileURL to:endpoint withProgressBlock:progressBlock completionBlock:completionBlock];
	
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
}


@end
