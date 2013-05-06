//
//  CMRelativeBenchmarksSpec.m
//  Cumulus
//
//  Created by John Clayton on 11/27/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMRelativeBenchmarksSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@interface CMRelativeBenchmarksSpec()
- (void) warmUpServer;
@end

@implementation CMRelativeBenchmarksSpec

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
	self.service = [CMResource withURL:kTestServerHost];
	self.benchmarks = [self.service resource:@"test/benchmarks"];
//    NSLog(@"item: %@",self.specHelper.item);
	self.largeList = self.specHelper.largeList;
//    NSLog(@"largeList: %@",self.largeList);
	self.complicatedList = self.specHelper.complicatedList;
//    NSLog(@"complicatedList: %@",self.complicatedList);
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
	self.benchmarks.contentType = CMContentTypeJSON;


	CMResource *smallResource = [self.benchmarks resource:@"small-resource.json"];
	CMResource *largeResource = [self.benchmarks resource:@"large-resource.json"];
	CMResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	CMResource *smallFile = [self.benchmarks resource:@"small-file.png"];
	CMResource *largeFile = [self.benchmarks resource:@"large-file.png"];

	smallResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	largeResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	complicatedResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	smallFile.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	largeFile.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	[smallResource get];
	[largeResource get];
	[complicatedResource get];
	[smallFile get];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[largeFile downloadWithProgressBlock:nil completionBlock:^(CMResponse *response){
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
}



// ========================================================================== //

#pragma mark - Specs

- (void)shouldGetManySmallResourcesWithNoCaching {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *smallResource = [self.benchmarks resource:@"small-resource.json"];
	smallResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	__block BOOL success = YES;
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();
	
	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(1000, queue, ^(size_t i) {
		CMResponse *response = [smallResource get];
		if (NO == response.wasSuccessful) {
			success = NO;
		}
	});

	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 3.f;
	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];
	
	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetManySmallResourcesWithExplicitCaching {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *smallResource = [self.benchmarks resource:@"small-resource.json"];
	smallResource.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	__block BOOL success = YES;

	// generate cache
	[smallResource get];

	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(1000, queue, ^(size_t i) {
		CMResponse *response = [smallResource get];
		if (NO == response.wasSuccessful) {
			success = NO;
		}
	});
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 1.f;
	
	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetOneLargeResourceWithNoCaching {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *largeResource = [self.benchmarks resource:@"large-resource.json"];
	largeResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;

	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	CMResponse *localResponse = [largeResource get];
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 1.f;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetOneLargeResourceWithExplicitCaching {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	complicatedResource.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	// generate cache
	[complicatedResource get];
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	CMResponse *localResponse = [complicatedResource get];
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .1;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetABunchOfComplicatedResourcesWithNoCaching {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	complicatedResource.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	__block BOOL success = YES;
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(15, queue, ^(size_t i) {
		CMResponse *response = [complicatedResource get];
		if (NO == response.wasSuccessful) {
			success = NO;
		}
	});

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 1.f;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldGetABunchOfComplicatedResourceWithExplicitCaching {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
	complicatedResource.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	__block BOOL success = YES;

	// generate cache
	[complicatedResource get];
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(15, queue, ^(size_t i) {
		CMResponse *response = [complicatedResource get];
		if (NO == response.wasSuccessful) {
			success = NO;
		}
	});
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .5;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldPostManySmallResources {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *smallResource = [self.benchmarks resource:@"small-resource.json"];
	__block BOOL success = YES;
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(1000, queue, ^(size_t i) {
		CMResponse *response = [smallResource post:self.specHelper.item];
		if (NO == response.wasSuccessful) {
			success = NO;
		}
	});
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 2.f;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldPostOneLargeResource {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *largeResource = [self.benchmarks resource:@"large-resource.json"];
//	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.largeList forKey:@"list"];  // our service likes hashes not arrays as the payload
    NSDictionary  *payload = @{@"list" : self.largeList};
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	CMResponse *localResponse = [largeResource post:payload];
	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = 7.f;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldPostABunchOfComplicatedResources {
	self.benchmarks.contentType = CMContentTypeJSON;
	CMResource *complicatedResource = [self.benchmarks resource:@"complicated-resource.json"];
//	NSDictionary  *payload = [NSDictionary dictionaryWithObject:self.complicatedList forKey:@"list"];  // our service likes hashes not arrays as the payload
    NSDictionary *payload = @{@"list" : self.complicatedList};
	__block BOOL success = YES;

	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(15, queue, ^(size_t i) {
		CMResponse *response = [complicatedResource post:payload];
		if (NO == response.wasSuccessful) {
			success = NO;
		}
	});

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .75;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldUploadManySmallFiles {
	CMResource *smallFile = [self.benchmarks resource:@"small-file.png"];
	__block BOOL success = YES;
	
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"t_hero" ofType:@"png"];
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_group_t group = dispatch_group_create();
	dispatch_group_enter(group); // wait on the last completion block

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		dispatch_group_async(group, dispatch_get_current_queue(), ^{
			[smallFile uploadFile:[NSURL fileURLWithPath:filePath] withProgressBlock:nil completionBlock:^(CMResponse *response){
				if (NO == response.wasSuccessful) {
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

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldUploadOneLargeFile {
	CMResource *largeFile = [self.benchmarks resource:@"large-file.png"];
	NSString *filePath = [[NSBundle mainBundle] pathForResource:@"hs-2006-01-c-full_tif" ofType:@"png"];
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	
	__block CMResponse *localResponse = nil;
	[largeFile uploadFile:[NSURL fileURLWithPath:filePath] withProgressBlock:nil completionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .5;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldDownloadManySmallFilesWithNoCaching {
	CMResource *smallFile = [self.benchmarks resource:@"small-file.png"];
	smallFile.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	__block BOOL success = YES;
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_group_t group = dispatch_group_create();
	dispatch_group_enter(group); // wait on the last completion block

	dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
	dispatch_apply(100, queue, ^(size_t i) {
		dispatch_group_async(group, dispatch_get_current_queue(), ^{
			[smallFile downloadWithProgressBlock:nil completionBlock:^(CMResponse *response){			
				if (NO == response.wasSuccessful) {
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

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldDownloadManySmallFilesWithExplicitCaching {
	CMResource *smallFile = [self.benchmarks resource:@"small-file.png"];
	smallFile.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	__block BOOL success = YES;
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);

	// generate cache
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[smallFile downloadWithProgressBlock:nil completionBlock:^(CMResponse *response){
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
			[smallFile downloadWithProgressBlock:nil completionBlock:^(CMResponse *response){			
				if (NO == response.wasSuccessful) {
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

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

	STAssertTrue(success, @"Should have succeeded");
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldDownloadOneLargeFileWithNoCaching {
	CMResource *largeFile = [self.benchmarks resource:@"large-file.png"];
	largeFile.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	__block CMResponse *localResponse = nil;
	
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[largeFile downloadWithProgressBlock:nil completionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	
	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .5;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}

- (void)shouldDownloadOneLargeFileWithExplicitCaching {
	CMResource *largeFile = [self.benchmarks resource:@"large-file.png"];
	largeFile.cachePolicy = NSURLRequestReturnCacheDataElseLoad;
	__block CMResponse *localResponse = nil;

	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	// generate cache
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[largeFile downloadWithProgressBlock:nil completionBlock:^(CMResponse *response){
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	
	CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[largeFile downloadWithProgressBlock:nil completionBlock:^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	CFAbsoluteTime end = CFAbsoluteTimeGetCurrent();
	CFTimeInterval elapsed = (end - start);
	CFTimeInterval expected = .35;

	self.currentResult.context = [NSString stringWithFormat:@"Took: %.2fs, Expected: %.2f",elapsed, expected];

    STAssertTrue(localResponse.wasSuccessful, @"Response should have succeeded: %@",localResponse);
	STAssertTrue(elapsed < expected, @"Should take less than %.2fs",expected);
}




@end
