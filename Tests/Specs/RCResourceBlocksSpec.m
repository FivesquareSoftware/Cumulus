//
//  RCResourceBlocksSpec.m
//  RESTClient
//
//  Created by John Clayton on 10/8/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCResourceBlocksSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>
#import "OCMock.h"


@implementation RCResourceBlocksSpec

@synthesize service;

+ (NSString *)description {
    return @"Resource Blocks";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
	
	self.service = [RCResource withURL:kTestServerHost];
	self.service.contentType = RESTClientContentTypeJSON;
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


#pragma - -Preflight

- (void) shouldExecutePreflightBlock {
	RCResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	index.preflightBlock = ^(RCRequest *request) {
		touched = YES;
		return NO;
	};
	
	[index get];
	STAssertTrue(touched, @"Should have run preflight block");
}

- (void) shouldReturnNilResponseWhenPreflightAbortsRequest {
	RCResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	index.preflightBlock = ^(RCRequest *request) {
		touched = YES;
		return NO;
	};
	
	RCResponse *response = [index get];

	STAssertTrue(touched, @"Should have run preflight block");
	STAssertNil(response, @"Response should be nil when preflight aborts a request");
}

- (void) shouldRunRequestWhenPreflightPasses {
	RCResource *index = [self.service resource:@"index"];

	__block BOOL touched = NO;

	index.preflightBlock = ^(RCRequest *request) {
		touched = YES;
		return YES;
	};
	
	RCResponse *response = [index get];

	STAssertTrue(touched, @"Should have run preflight block");
	STAssertNotNil(response, @"Response should not be nil when preflight allows a request to run");
    STAssertTrue(response.success, @"Response should have succeeded: %@",response);
}

- (void) shouldExecutePreflightBlockInNonBlockingMode {
	RCResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	index.preflightBlock = ^(RCRequest *request) {
		touched = YES;
		return NO;
	};
	
	[index getWithCompletionBlock:NULL];
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		// just so we are on the main q after preflight block, to prove we ran it
	});
	
	STAssertTrue(touched, @"Should have run preflight block");
}

- (void) shouldRunRequestWhenPreflightPassesInNonBlockingMode {
	RCResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	index.preflightBlock = ^(RCRequest *request) {
		touched = YES;
		return YES;
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[index getWithCompletionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	
	STAssertTrue(touched, @"Should have run preflight block");
	STAssertNotNil(localResponse, @"Response should not be nil when preflight allows a request to run");
    STAssertTrue(localResponse.success, @"Response should be ok");

}

- (void) shouldExecutePreflightBlockOnMainThread {
	RCResource *index = [self.service resource:@"index"];
	
	__block BOOL mainThread = NO;
	index.preflightBlock = ^(RCRequest *request) {
		mainThread = [NSThread isMainThread];
		return NO;
	};

	[index getWithCompletionBlock:NULL];
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		// just so we are on the main q after preflight block, to prove we ran it
	});

	STAssertTrue(mainThread, @"Should have run preflight block on main thread");
}


#pragma - -Progress

- (void) shouldExecuteProgressBlock {
	RCResource *hero = [self.service resource:@"test/download/hero"];
	
	
	// Set up a mock to receive progress blocks
	__block id mockProgressObject = [OCMockObject mockForClass:[NSObject class]];
	
	
	BOOL (^zeroProgressBlock)(id) = ^(id value) {
		float progress = [(NSNumber *)value floatValue];
		return (BOOL)(progress == 0);
	};
	
	BOOL (^someProgressBlock)(id) = ^(id value) {
		float progress = [(NSNumber *)value floatValue];
		return (BOOL)(0.f <= progress && progress <= 1.f);
	};
	
	[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:zeroProgressBlock] forKey:@"Progress"];
	
	RCProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kRESTClientProgressInfoKeyProgress];
		[mockProgressObject setValue:progress forKey:@"Progress"];
		if ([progress floatValue] < 1.f) {
			[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:someProgressBlock] forKey:@"Progress"];
		}
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	RCCompletionBlock completionBlock = ^(RCResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[hero getWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	
	[mockProgressObject verify];
}


#pragma - -Post Processor

- (void) shouldExecutePostProcessorBlock {
	RCResource *index = [self.service resource:@"index"];
		
	index.postProcessorBlock = ^(RCResponse *response, id result) {
		NSString *newResult = [NSString stringWithFormat:@"-- %@ --",result];
		return newResult;
	};
	
	RCResponse *response = [index get];
	STAssertEqualObjects(@"-- OK --", response.result, @"Result should have been transformed by post-processor");
}

- (void) shouldExecutePostProcessorBlockOnHighPriorityQueue {
	RCResource *index = [self.service resource:@"index"];
	
	__block BOOL highQueue = NO;
	index.postProcessorBlock = ^(RCResponse *response, id result) {
		highQueue = dispatch_get_current_queue() == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		NSString *newResult = [NSString stringWithFormat:@"-- %@ --",result];
		return newResult;
	};
	
	RCResponse *response = [index get];
	STAssertEqualObjects(@"-- OK --", response.result, @"Result should have been transformed by post-processor");
	STAssertTrue(highQueue, @"Should have run post-processor block on high priority queue");
}

#pragma - -Completion


- (void) shouldExecuteCompletionBlock {
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block RCResponse *localResponse = nil;
	__block BOOL touched = NO;
	RCResource *index = [self.service resource:@"index"];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[index getWithCompletionBlock:^(RCResponse *response){
		localResponse = response;
		touched = YES;
		dispatch_semaphore_signal(request_sema);
	}];
		
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(touched, @"Should have run completion block");
}

- (void) shouldExecuteCompletionBlockOnMainThread {
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
    __block RCResponse *localResponse = nil;
	__block BOOL mainThread = NO;	

	RCResource *index = [self.service resource:@"index"];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[index getWithCompletionBlock:^(RCResponse *response){
		localResponse = response;
		mainThread = [NSThread isMainThread];
		dispatch_semaphore_signal(request_sema);
	}];
		
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

    STAssertTrue(mainThread, @"Completion block should have run on main thread");
}



@end

