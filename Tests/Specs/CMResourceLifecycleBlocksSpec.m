//
//	CMResourceLifecycleBlocksSpec.m
//	Cumulus
//
//	Created by John Clayton on 10/8/11.
//	Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceLifecycleBlocksSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


@import Nimble;
#import "OCMock.h"


@implementation CMResourceLifecycleBlocksSpec


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
	
	self.service = [CMResource withURL:kTestServerHost];
	self.service.contentType = CMContentTypeJSON;
	self.service.cachePolicy = NSURLRequestReloadIgnoringCacheData;
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
	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	index.preflightBlock = ^(CMRequest *request) {
		touched = YES;
		return NO;
	};
	
	[index get];
	expect(touched).toWithDescription(beTrue(), @"Should have run preflight block");
}

- (void) shouldReturnNilResponseWhenPreflightAbortsRequest {
	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	index.preflightBlock = ^(CMRequest *request) {
		touched = YES;
		return NO;
	};
	
	CMResponse *response = [index get];
	
	expect(touched).toWithDescription(beTrue(), @"Should have run preflight block");
	expect(response).toWithDescription(beNil(), @"Response should be nil when preflight aborts a request");
	
}

- (void) shouldRunRequestWhenPreflightPasses {
	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	
	index.preflightBlock = ^(CMRequest *request) {
		touched = YES;
		return YES;
	};
	
	CMResponse *response = [index get];
	
	expect(touched).toWithDescription(beTrue(), @"Should have run preflight block");
	expect(response).toNotWithDescription(beNil(),@"Response should not be nil when preflight allows a request to run");
	expect(response.wasSuccessful).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response should have succeeded: %@",response]);
}

- (void) shouldExecutePreflightBlockInNonBlockingMode {
	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	index.preflightBlock = ^(CMRequest *request) {
		touched = YES;
		return NO;
	};
	
	[index getWithCompletionBlock:NULL];
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		// just so we are on the main q after preflight block, to prove we ran it
	});
	
	expect(touched).toWithDescription(beTrue(), @"Should have run preflight block");
}

- (void) shouldRunRequestWhenPreflightPassesInNonBlockingMode {
	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL touched = NO;
	index.preflightBlock = ^(CMRequest *request) {
		touched = YES;
		return YES;
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[index getWithCompletionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
		
	
	expect(touched).toWithDescription(beTrue(), @"Should have run preflight block");
	expect(localResponse).toNotWithDescription(beNil(),@"Response should not be nil when preflight allows a request to run");
	expect(localResponse.wasSuccessful).toWithDescription(beTrue(), @"Response should be ok");
	
}

- (void) shouldExecutePreflightBlockOnMainThread {
	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL mainThread = NO;
	index.preflightBlock = ^(CMRequest *request) {
		mainThread = [NSThread isMainThread];
		return NO;
	};
	
	[index getWithCompletionBlock:NULL];
	
	dispatch_sync(dispatch_get_main_queue(), ^{
		// just so we are on the main q after preflight block, to prove we ran it
	});
	
	expect(mainThread).toWithDescription(beTrue(), @"Should have run preflight block on main thread");
}


#pragma - -Progress

- (void) shouldExecuteProgressBlock {
	CMResource *hero = [self.service resource:@"test/download/hero"];
	
	
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
	
	CMProgressBlock progressBlock = ^(NSDictionary *progressInfo){
		NSNumber *progress = [progressInfo valueForKey:kCumulusProgressInfoKeyProgress];
		[mockProgressObject setValue:progress forKey:@"Progress"];
		if ([progress floatValue] < 1.f) {
			[[mockProgressObject expect] setValue:[OCMArg checkWithBlock:someProgressBlock] forKey:@"Progress"];
		}
	};
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	CMCompletionBlock completionBlock = ^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[hero getWithProgressBlock:progressBlock completionBlock:completionBlock];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
		
	
	[mockProgressObject verify];
}


#pragma - -Post Processor

- (void) shouldExecutePostProcessorBlock {
	CMResource *index = [self.service resource:@"index"];
	
	index.postProcessorBlock = ^(CMResponse *response, id result) {
		NSString *newResult = [NSString stringWithFormat:@"-- %@ --",result];
		return newResult;
	};
	
	CMResponse *response = [index get];
	expect(@"-- OK --").toWithDescription(equal(response.result), @"Result should have been transformed by post-processor");
}

- (void) shouldExecutePostProcessorBlockOnHighPriorityQueue {
	CMResource *index = [self.service resource:@"index"];
	
	__block BOOL highQueue = NO;
	index.postProcessorBlock = ^(CMResponse *response, id result) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
		highQueue = dispatch_get_current_queue() == dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
#pragma clang diagnostic pop
		NSString *newResult = [NSString stringWithFormat:@"-- %@ --",result];
		return newResult;
	};
	
	CMResponse *response = [index get];
	expect(@"-- OK --").toWithDescription(equal(response.result), @"Result should have been transformed by post-processor");
	expect(highQueue).toWithDescription(beTrue(), @"Should have run post-processor block on high priority queue");
}

#pragma - -Completion


- (void) shouldExecuteCompletionBlock {
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	__block BOOL touched = NO;
	CMResource *index = [self.service resource:@"index"];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[index getWithCompletionBlock:^(CMResponse *response){
		localResponse = response;
		touched = YES;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
		
	expect(touched).toWithDescription(beTrue(), @"Should have run completion block");
}

- (void) shouldExecuteCompletionBlockOnMainThread {
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	__block CMResponse *localResponse = nil;
	__block BOOL mainThread = NO;
	
	CMResource *index = [self.service resource:@"index"];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[index getWithCompletionBlock:^(CMResponse *response){
		localResponse = response;
		mainThread = [NSThread isMainThread];
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
		
	expect(mainThread).toWithDescription(beTrue(), @"Completion block should have run on main thread");
}



@end

