//
//  RCRequestSpec.m
//  RESTClient
//
//  Created by John Clayton on 12/3/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCRequestSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCRequestSpec

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
	[URLRequest setHTTPMethod:kRESTClientHTTPMethodGET];

	RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];

	[request startWithCompletionBlock:nil];
#ifdef DEBUG
	STAssertThrows([request start], @"Should not be able to start a request twice");
#endif
}

- (void)shouldNotBeAbleToStartARequestThatIsCanceled {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kRESTClientHTTPMethodGET];
	
	RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];
	[request startWithCompletionBlock:nil];
	[request cancel];
	STAssertThrows([request start], @"Should not be able to start a request that is canceled");
}

- (void)shouldNotBeAbleToStartARequestThatIsFinished {
	NSString *endpoint = [NSString stringWithFormat:@"%@/index",kTestServerHost];
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kRESTClientHTTPMethodGET];
	
	RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[request startWithCompletionBlock:^(RCResponse *response) {
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
	[URLRequest setHTTPMethod:kRESTClientHTTPMethodGET];
	
	RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	
	[request startWithCompletionBlock:nil];
	[request cancel];	

	STAssertTrue(request.wasCanceled, @"wasCanceled should be YES");
	STAssertNil(request.URLResponse, @"URLResponse should be nil");
}

- (void)shouldRunCompletionBlockWhenCanceled {
	NSString *endpoint = [NSString stringWithFormat:@"%@/slow",kTestServerHost];
	
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:endpoint]];
	[URLRequest setHTTPMethod:kRESTClientHTTPMethodGET];
	
	RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];
	request.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
	
	__block BOOL touched = NO;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[request startWithCompletionBlock:^(RCResponse *response){
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
	[URLRequest setHTTPMethod:kRESTClientHTTPMethodGET];
	
	RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];
	request.timeout = .01;
	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[request startWithCompletionBlock:^(RCResponse *response) {
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
	[URLRequest setHTTPMethod:kRESTClientHTTPMethodGET];
	
	RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];
	request.timeout = .01;
	
	__block BOOL touched = NO;
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[request startWithCompletionBlock:^(RCResponse *response) {
		touched = YES;
		dispatch_semaphore_signal(request_sema);
	}];
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
	
	STAssertTrue(touched, @"Touched should be YES");
}

- (void) shouldFailToCreateARequestWithNoURLRequest {
	RCRequest *request;
#ifdef DEBUG	
	STAssertThrows((request = [[RCRequest alloc] initWithURLRequest:nil]), @"Should not create a request without a URL request");
#else
	request = [[RCRequest alloc] initWithURLRequest:nil];
	STAssertNil(request, @"Should not create a request without a URL request");
#endif
}

@end
