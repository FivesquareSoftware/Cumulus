//
//  RCBenchmarksSpec.m
//  RESTClient
//
//  Created by John Clayton on 11/27/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCBenchmarksSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@interface RCBenchmarksSpec()
- (void) warmUpServer;
@end

@implementation RCBenchmarksSpec

@synthesize service;
@synthesize benchmarks;
@synthesize largeList;
@synthesize complicatedList;

+ (NSString *)description {
    return @"Relative Benchmarks"; // Just to make sure we don't drastically degrade performance when changing things
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
	self.service = [RCResource withURL:kTestServerHost];
	self.benchmarks = [self.service resource:@"test/benchmarks"];
	self.largeList = self.specHelper.largeList;
	self.complicatedList = self.specHelper.complicatedList;
	[self warmUpServer];
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
	self.service = nil;
	self.benchmarks = nil;
	
	[self.specHelper cleanCaches];
}

// Make each request once to give the server a chance to warm up
- (void) warmUpServer {
	self.benchmarks.contentType = RESTClientContentTypeJSON;


	RCResource *smallResource = [self.benchmarks resource:@"small-resource.json"];
	RCResource *largeResource = [self.benchmarks resource:@"large-resource.json"];
	RCResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	RCResource *smallFile = [self.benchmarks resource:@"small-file.png"];
	RCResource *largeFile = [self.benchmarks resource:@"large-file.png"];

	smallResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	largeResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	complicatedResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	smallFile.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	largeFile.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;

	[smallResource get];
	[largeResource get];
	[complicatedResource get];
	[smallFile get];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[largeFile downloadWithProgressBlock:nil completionBlock:^(RCResponse *response){
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
}



// ========================================================================== //

#pragma mark - Specs

- (void)shouldGetManySmallResourcesWithNoCaching {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *smallResource = [self.benchmarks resource:@"small-resource.json"];
	smallResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;

	__block BOOL success = YES;
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(1000, queue, ^(size_t i) {
		RCResponse *response = [smallResource get];
		if (NO == response.success) {
			success = NO;
		}
	});

	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 3.f;
	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];
	
	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetManySmallResourcesWithExplicitCaching {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *smallResource = [self.benchmarks resource:@"small-resource.json"];
	smallResource.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	__block BOOL success = YES;

	// generate cache
	[smallResource get];

	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(1000, queue, ^(size_t i) {
		RCResponse *response = [smallResource get];
		if (NO == response.success) {
			success = NO;
		}
	});
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 1.f;
	
	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetOneLargeResourceWithNoCaching {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *largeResource = [self.benchmarks resource:@"large-resource.json"];
	largeResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;

	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	RCResponse *localResponse = [largeResource get];
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 1.f;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetOneLargeResourceWithExplicitCaching {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	complicatedResource.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	// generate cache
	[complicatedResource get];
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	RCResponse *localResponse = [complicatedResource get];
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .1;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetABunchOfComplicatedResourcesWithNoCaching {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	complicatedResource.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	__block BOOL success = YES;
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(15, queue, ^(size_t i) {
		RCResponse *response = [complicatedResource get];
		if (NO == response.success) {
			success = NO;
		}
	});

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 1.f;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetABunchOfComplicatedResourceWithExplicitCaching {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	complicatedResource.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	__block BOOL success = YES;

	// generate cache
	[complicatedResource get];
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(15, queue, ^(size_t i) {
		RCResponse *response = [complicatedResource get];
		if (NO == response.success) {
			success = NO;
		}
	});
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .5;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldPostManySmallResources {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *smallResource = [self.benchmarks resource:@"small-resource.json"];
	__block BOOL success = YES;
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(1000, queue, ^(size_t i) {
		RCResponse *response = [smallResource post:self.specHelper.item];
		if (NO == response.success) {
			success = NO;
		}
	});
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 2.f;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldPostOneLargeResource {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *largeResource = [self.benchmarks resource:@"large-resource.json"];
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.largeList forKey:@"list"];  // our service likes hashes not arrays as the payload

	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	RCResponse *localResponse = [largeResource post:payload];
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 7.f;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldPostABunchOfComplicatedResources {
	self.benchmarks.contentType = RESTClientContentTypeJSON;
	RCResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.complicatedList forKey:@"list"];  // our service likes hashes not arrays as the payload
	__block BOOL success = YES;

	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(15, queue, ^(size_t i) {
		RCResponse *response = [complicatedResource post:payload];
		if (NO == response.success) {
			success = NO;
		}
	});

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .75;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldUploadManySmallFiles {
	RCResource *smallFile = [self.benchmarks resource:@"small-file.png"];
	__block BOOL success = YES;
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"t_hero" ofType:@"png"];
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_group_t group = dispatch_group_create();
	dispatch_group_enter(group); // wait on the last completion block

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		dispatch_group_async(group, dispatch_get_current_queue(), ^{
			[smallFile uploadFile:[NSURL fileURLWithPath:filePath] withProgressBlock:nil completionBlock:^(RCResponse *response){
				if (NO == response.success) {
					success = NO;
				}
				if (i >= 99) {
					dispatch_group_leave(group);
				}
			}];
		});
	});
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	dispatch_release(group);
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 3.f;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldUploadOneLargeFile {
	RCResource *largeFile = [self.benchmarks resource:@"large-file.png"];
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	__block RCResponse *localResponse = nil;
	[largeFile uploadFile:[NSURL fileURLWithPath:filePath] withProgressBlock:nil completionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .5;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldDownloadManySmallFilesWithNoCaching {
	RCResource *smallFile = [self.benchmarks resource:@"small-file.png"];
	smallFile.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	__block BOOL success = YES;
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_group_t group = dispatch_group_create();
	dispatch_group_enter(group); // wait on the last completion block

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		dispatch_group_async(group, dispatch_get_current_queue(), ^{
			[smallFile downloadWithProgressBlock:nil completionBlock:^(RCResponse *response){			
				if (NO == response.success) {
					success = NO;
				}
				if (i >= 99) {
					dispatch_group_leave(group);
				}
			}];
		});
	});
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	dispatch_release(group);


	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 1.25;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldDownloadManySmallFilesWithExplicitCaching {
	RCResource *smallFile = [self.benchmarks resource:@"small-file.png"];
	smallFile.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	__block BOOL success = YES;
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);

	// generate cache
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[smallFile downloadWithProgressBlock:nil completionBlock:^(RCResponse *response){
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_group_t group = dispatch_group_create();
	dispatch_group_enter(group); // wait on the last completion block
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		dispatch_group_async(group, dispatch_get_current_queue(), ^{
			[smallFile downloadWithProgressBlock:nil completionBlock:^(RCResponse *response){			
				if (NO == response.success) {
					success = NO;
				}
				if (i >= 99) {
					dispatch_group_leave(group);
				}
			}];
		});
	});
	
	dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
	dispatch_release(group);

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 1.1f;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldDownloadOneLargeFileWithNoCaching {
	RCResource *largeFile = [self.benchmarks resource:@"large-file.png"];
	largeFile.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	__block RCResponse *localResponse = nil;
	
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[largeFile downloadWithProgressBlock:nil completionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .5;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldDownloadOneLargeFileWithExplicitCaching {
	RCResource *largeFile = [self.benchmarks resource:@"large-file.png"];
	largeFile.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	__block RCResponse *localResponse = nil;

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	// generate cache
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[largeFile downloadWithProgressBlock:nil completionBlock:^(RCResponse *response){
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[largeFile downloadWithProgressBlock:nil completionBlock:^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .35;

	self.result.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.success, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}




@end
