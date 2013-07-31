//
//  CMRequestSpec.m
//  Cumulus
//
//  Created by John Clayton on 12/3/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMRequestSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMRequestSpec

+ (NSString *)description {
	return @"Request Internals";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
	// set up resources common to all examples here
}

- (void)beforeEach {
	// set up resources that need to be initialized before each example here 
}

- (void)afterEach {
	// tear down resources specific to each example here
}


- (void)afterAll {
	// tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs


- (void)shouldNotBeAbleToStartARequestThatIsStarted {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];

	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];

	[request startWithCompletionBlock:nil];
#ifdef DEBUG
	STAssertThrows([request start], @"Should not be able to start a request twice");
#endif
}

- (void)shouldNotBeAbleToStartARequestThatIsCanceled {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	[request startWithCompletionBlock:nil];
	[request cancel];
	STAssertThrows([request start], @"Should not be able to start a request that is canceled");
}

- (void)shouldNotBeAbleToStartARequestThatIsFinished {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[request startWithCompletionBlock:^(CMResponse *response) {
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	STAssertThrows([request start], @"Should not be able to start a request that is finished");
}

- (void)shouldBeCanceledWhenCanceled {
	NSString *endpoint = [NSString stringWithFormat:@"%@/slow",kTestServerHost];

	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	[request startWithCompletionBlock:nil];
	[request cancel];	

	STAssertTrue(request.wasCanceled, @"wasCanceled should be YES");
	STAssertNil(request.URLResponse, @"URLResponse should be nil");
}

- (void)shouldRunCompletionBlockWhenCanceled {
	NSString *endpoint = [NSString stringWithFormat:@"%@/slow",kTestServerHost];
	
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	__block BOOL touched = NO;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[request startWithCompletionBlock:^(CMResponse *response){
		touched = YES;
		dispatch_semaphore_signal(request_sema);
	}];
	[request cancel];	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	STAssertTrue(touched, @"Touched should be YES");
}

- (void) shouldTimeoutWhenNoResponseAfterTimeoutInterval {
	NSString *endpoint = [NSString stringWithFormat:@"%@/slow",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.timeout = .01;
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[request startWithCompletionBlock:^(CMResponse *response) {
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);

	STAssertNotNil(request.error, @"Error should not be nil");
	STAssertTrue([request.error.domain isEqualToString:NSURLErrorDomain] && request.error.code == NSURLErrorTimedOut, @"Error should be timeout error", request.error);
}

- (void) shouldRunCompletionBlockOnTimeout {
	NSString *endpoint = [NSString stringWithFormat:@"%@/slow",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.timeout = .01;
	
	__block BOOL touched = NO;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[request startWithCompletionBlock:^(CMResponse *response) {
		touched = YES;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	STAssertTrue(touched, @"Touched should be YES");
}

- (void) shouldFailToCreateARequestWithNoURLRequest {
	CMRequest *request;
#ifdef DEBUG	
	STAssertThrows((request = [[CMRequest alloc] initWithURLRequest:nil]), @"Should not create a request without a URL request");
#else
	request = [[CMRequest alloc] initWithURLRequest:nil];
	STAssertNil(request, @"Should not create a request without a URL request");
#endif
}

- (void) shouldZeroOutResponseInternalWhenThereIsNoCompletionBlock {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	[request startWithCompletionBlock:nil];
	while (NO == request.isFinished) {
		[NSThread sleepForTimeInterval:.001];
	}
	id responseInternal = [request valueForKey:@"responseInternal"];
	STAssertNil(responseInternal, @"Internal response pointer should be nil on finish");
}

- (void) shouldZeroOutResponseInternalAfterCompletionBlockRuns {
	NSString *endpoint = [NSString stringWithFormat:@"%@/slow",kTestServerHost];
	
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	[request startWithCompletionBlock:^(CMResponse *response){
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	id responseInternal = [request valueForKey:@"responseInternal"];
	STAssertNil(responseInternal, @"Internal response pointer should be nil after completion block runs");
}

- (void) shouldZeroOutResponseInternalWhenCanceled {	
	NSString *endpoint = [NSString stringWithFormat:@"%@/slow",kTestServerHost];
	
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	[request startWithCompletionBlock:^(CMResponse *response){
		dispatch_semaphore_signal(request_sema);
	}];
	[request cancel];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	id responseInternal = [request valueForKey:@"responseInternal"];
	STAssertNil(responseInternal, @"Internal response pointer should be nil after cancelation");
}

- (void) shouldReportCompleteForACompletedRequest {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block BOOL complete = NO;
	[request startWithCompletionBlock:^(CMResponse *response) {
		complete = response.wasComplete;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(complete, @"Simple request should have completed");
}

- (void) shouldReportCompleteForAStreamedFile {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/stream/hero",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);

	__block BOOL complete = NO;
	[request startWithCompletionBlock:^(CMResponse *response) {
		complete = response.wasComplete;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(complete, @"Streamed request should have completed");
}

- (void) shouldReportCompleteForARangeRequest {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/download/hero",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.range = CMContentRangeMake(0, 1000, 0);
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block BOOL complete = NO;
	[request startWithCompletionBlock:^(CMResponse *response) {
		complete = response.wasComplete;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertTrue(complete, @"Simple request should have completed");
}

- (void) shouldReportIncompleteForAnInterruptedRequest {
	NSString *endpoint = [NSString stringWithFormat:@"%@/test/download/massive",kTestServerHost];
	
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMDownloadRequest *request = [[CMDownloadRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	request.cachesDir  = [Cumulus cachesDir];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);

	__block BOOL complete = NO;
	__weak CMRequest *weakRequest = request;
	request.didReceiveDataBlock = ^(CMProgressInfo *progressInfo) {
//		NSLog(@"progress: %@",progressInfo.progress);
		if (progressInfo.progress.floatValue > 0.f) {
			[weakRequest cancel];
		}
	};
	
	[request startWithCompletionBlock:^(CMResponse *response) {
		complete = response.wasComplete;
		dispatch_semaphore_signal(request_sema);
	}];

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(request_sema);
	
	STAssertFalse(complete,@"Interrupted request should not have been complete");
}

- (void) shouldReturnRequestQueryStringAsADictionary {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index?foo=bar",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	NSDictionary *query = @{ @"foo" : @"bar" };
	
	STAssertTrue([query isEqualToDictionary:request.queryDictionary], @"Request query dictionary should equal sent dictionary");
}


@end
