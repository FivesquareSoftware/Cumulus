//
//  CMStaticMethodsSpec.m
//  Cumulus
//
//  Created by John Clayton on 11/26/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMStaticMethodsSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMStaticMethodsSpec

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
	[Cumulus setHeaders:[NSMutableDictionary dictionaryWithObjectsAndKeys:
						 @"application/json", kCumulusHTTPHeaderContentType
						 , @"application/json", kCumulusHTTPHeaderAccept
						 , nil]];
	[Cumulus setAuthProviders:nil];
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
    CMResponse *response = [Cumulus get:endpoint];
	STAssertEqualObjects(response.request.headers, [Cumulus headers], @"Request haeaders should equal static headers");
}

- (void)shouldBeAuthorized {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/protected",kTestServerHost];
    CMBasicAuthProvider *authProvider = [CMBasicAuthProvider withUsername:@"test" password:@"test"];
	[Cumulus setAuthProviders:[NSMutableArray arrayWithObject:authProvider]];
    CMResponse *response = [Cumulus get:endpoint];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
}

- (void)shouldGet {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    CMResponse *response = [Cumulus get:endpoint];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
}

- (void)shouldGetWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	[Cumulus get:endpoint withCompletionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldGetWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	
	CMProgressBlock progressBlock = ^(NSDictionary *progressInfo){
//		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		//		NSLog(@"progress: %@",progress);
	};
	
	CMCompletionBlock completionBlock = ^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	[Cumulus get:endpoint withProgressBlock:progressBlock completionBlock:completionBlock];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldHead {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    CMResponse *response = [Cumulus head:endpoint];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
}

- (void)shouldHeadWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	[Cumulus head:endpoint withCompletionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldDelete {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    CMResponse *response = [Cumulus delete:endpoint];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
}

- (void)shouldDeleteWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	[Cumulus delete:endpoint withCompletionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldPost {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    CMResponse *response = [Cumulus post:endpoint payload:self.specHelper.item];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
}

- (void)shouldPostWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	[Cumulus post:endpoint payload:self.specHelper.item withCompletionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldPostWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	
	CMProgressBlock progressBlock = ^(NSDictionary *progressInfo){
//		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		//		NSLog(@"progress: %@",progress);
	};
	
	CMCompletionBlock completionBlock = ^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	[Cumulus post:endpoint payload:self.specHelper.item withProgressBlock:progressBlock completionBlock:completionBlock];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldPut {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
    CMResponse *response = [Cumulus put:endpoint payload:self.specHelper.item];
    STAssertTrue(response.wasSuccessful, @"Response should have succeeded: %@",response);
}

- (void)shouldPutWithCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	[Cumulus put:endpoint payload:self.specHelper.item withCompletionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldPutWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	
	CMProgressBlock progressBlock = ^(NSDictionary *progressInfo){
//		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		//		NSLog(@"progress: %@",progress);
	};
	
	CMCompletionBlock completionBlock = ^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	[Cumulus put:endpoint payload:self.specHelper.item withProgressBlock:progressBlock completionBlock:completionBlock];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}

- (void)shouldDownloadWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/download/hero",kTestServerHost];
	
	CMProgressBlock progressBlock = ^(NSDictionary *progressInfo){
//		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		//		NSLog(@"progress: %@",progress);
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	[Cumulus download:endpoint withProgressBlock:progressBlock completionBlock:completionBlock];

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@", localResponse);
}

- (void)shouldUploadWithProgressBlockAndCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/upload/hero",kTestServerHost];
	
	
	CMProgressBlock progressBlock = ^(CMProgressInfo *progressInfo){
//		NSLog(@"progress: %@",progressInfo.progress);
	};
	
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"t_hero" ofType:@"png"];
	NSURL *fileURL = [NSURL fileURLWithPath:filePath];
	[Cumulus uploadFile:fileURL to:endpoint withProgressBlock:progressBlock completionBlock:completionBlock];
	
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
}


@end
