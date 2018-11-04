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


@import Nimble;


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
#if !defined(NS_BLOCK_ASSERTIONS) || NS_BLOCK_ASSERTIONS == 0
	expect([request start]).toWithDescription(raiseException(), @"Should not be able to start a request twice");
#else 
	expect([request start]).toWithDescription(beFalse(), @"Should not be able to start a request twice");
#endif
}

- (void)shouldNotBeAbleToStartARequestThatIsCanceled {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	[request startWithCompletionBlock:nil];
	[request cancel];
#if !defined(NS_BLOCK_ASSERTIONS) || NS_BLOCK_ASSERTIONS == 0
	expect([request start]).toWithDescription(raiseException(), @"Should not be able to start a request that is canceled");
#else
	expect([request start]).toWithDescription(beFalse(), @"Should not be able to start a request that is canceled");
#endif

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
	
#if !defined(NS_BLOCK_ASSERTIONS) || NS_BLOCK_ASSERTIONS == 0
	expect([request start]).toWithDescription(raiseException(), @"Should not be able to start a request that is finished");
#else
	expect([request start]).toWithDescription(beFalse(), @"Should not be able to start a request that is finished");
#endif

}

- (void)shouldBeCanceledWhenCanceled {
	NSString *endpoint = [NSString stringWithFormat:@"%@/slow",kTestServerHost];

	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	[request startWithCompletionBlock:nil];
	[request cancel];	

	expect(request.wasCanceled).toWithDescription(beTrue(), @"wasCanceled should be YES");
	expect(request.URLResponse).toWithDescription(beNil(), @"URLResponse should be nil");
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
		
	expect(touched).toWithDescription(beTrue(), @"Touched should be YES");
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
	
	expect(request.error).toNotWithDescription(beNil(),@"Error should not be nil");
	expect([request.error.domain isEqualToString:NSURLErrorDomain] && request.error.code == NSURLErrorTimedOut).toWithDescription(beTrue(), [NSString stringWithFormat:@"Error should be timeout error %@", request.error]);
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
		
	expect(touched).toWithDescription(beTrue(), @"Touched should be YES");
}

- (void) shouldFailToCreateARequestWithNoURLRequest {
	__block CMRequest *request;
#if !defined(NS_BLOCK_ASSERTIONS) || NS_BLOCK_ASSERTIONS == 0
	expect(request = [[CMRequest alloc] initWithURLRequest:nil]).toWithDescription(raiseException(), @"Should not create a request without a URL request");
#else
	request = [[CMRequest alloc] initWithURLRequest:nil];
	expect(request).toWithDescription(beNil(), @"Should not create a request without a URL request");
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
	expect(responseInternal).toWithDescription(beNil(), @"Internal response pointer should be nil on finish");
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
		
	id responseInternal = [request valueForKey:@"responseInternal"];
	expect(responseInternal).toWithDescription(beNil(), @"Internal response pointer should be nil after completion block runs");
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
		
	id responseInternal = [request valueForKey:@"responseInternal"];
	expect(responseInternal).toWithDescription(beNil(), @"Internal response pointer should be nil after cancelation");
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
		
	expect(complete).toWithDescription(beTrue(), @"Simple request should have completed");
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
		
	expect(complete).toWithDescription(beTrue(), @"Streamed request should have completed");
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
		
	expect(complete).toWithDescription(beTrue(), @"Simple request should have completed");
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
		
	expect(complete).toWithDescription(beFalse(), @"Interrupted request should not have been complete");
}

- (void) shouldReturnRequestQueryStringAsADictionary {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index?foo=bar",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kCumulusHTTPMethodGET];
	
	CMRequest *request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	NSDictionary *query = @{ @"foo" : @"bar" };
	
	expect([query isEqualToDictionary:request.queryDictionary]).toWithDescription(beTrue(), @"Request query dictionary should equal sent dictionary");
}


@end
