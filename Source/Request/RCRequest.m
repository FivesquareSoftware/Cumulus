//
//  RCRequest.m
//  RESTClient
//
//  Created by John Clayton on 7/23/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

/*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 * 
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *    this list of conditions and the following disclaimer in the documentation
 *    and/or other materials provided with the distribution.
 * 
 * 3. Neither the name of Fivesquare Software nor the names of its contributors may
 *    be used to endorse or promote products derived from this software without
 *    specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "RCRequest.h"
#import "RCRequest+Protected.h"

#import "RESTClient.h"

@interface RCRequest() 

// Readwrite versions of public properties

@property (readwrite) BOOL started;
@property (readwrite) BOOL finished;
@property (readwrite) BOOL canceled;

@property (readwrite, strong) NSURLResponse *URLResponse;

@property (readwrite, strong) NSString *responseBody;


// Private properties

@property BOOL connectionFinished;
@property (readwrite, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSURLRequest *originalURLRequest;
@property (weak) NSTimer *timeoutTimer;
@property (readonly) BOOL canStart;
@property (readonly) BOOL canCancel;
@property (readonly) BOOL canAbort;

// Private Methods

- (void) timeoutFired:(NSTimer *)timer;

@end



@implementation RCRequest

+ (NSOperationQueue *) opQ {
	static NSOperationQueue *opQ = nil;
	@synchronized(self) {
		if (nil == opQ) {
			opQ = [NSOperationQueue new];
		}
	}
	return opQ;
}


static NSUInteger requestCount = 0;
+ (void) incrementRequestCount {
	@synchronized(@"RCRequest.requestCount") {
		requestCount++;
#if TARGET_OS_IPHONE
		if (requestCount > 0) {
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
		}
#endif	
	}
}

+ (void) decrementRequestCount {
	@synchronized(@"RCRequest.requestCount") {
		requestCount--;
#if TARGET_OS_IPHONE
		if (requestCount < 1) {
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
		}
#endif
	}	
}

// ========================================================================== //

#pragma mark - Properties


// Private


// Public


#pragma mark - -Request State


@synthesize started=started_;
@synthesize finished=finished_;
@synthesize canceled=canceled_;

#pragma mark - -Lifecycle


@synthesize didSendDataBlock=didSendDataBlock_;
@synthesize didReceiveDataBlock=didReceiveDataBlock_;
@synthesize postProcessorBlock=resultProcessor_;
@synthesize abortBlock=abortBlock_;
@synthesize completionBlock=completionBlock_;


#pragma mark - -Content Encoding/Decoding

@synthesize payloadEncoder=payloadEncoder_;
@synthesize responseDecoder=responseDecoder_;


#pragma mark - -Configuration


@synthesize headers=headers_;
@synthesize timeout=timeout_;
@synthesize cachePolicy=cachePolicy_;
@synthesize authProviders=authProviders_;
@synthesize maxAuthRetries=maxAuthRequests_;
@synthesize payload=payload_;


#pragma mark - -Execution Context


@synthesize URLRequest=URLRequest_;
@synthesize URLResponse=URLResponse_;
@synthesize bodyContentLength=bodyContentLength_;
@synthesize sentContentLength=sentContentLength_;
@synthesize expectedContentLength=expectedContentLength_;
@synthesize receivedContentLength=receivedContentLength_;
@synthesize data=data_;
@synthesize result=result_;
@synthesize responseBody=responseBody_;
@synthesize error=error_;


// Private

@synthesize connectionFinished=connectionFinished_;
@synthesize connection=connection_;
@synthesize originalURLRequest=originalURLRequest_;
@synthesize timeoutTimer=timeoutTimer_;

@dynamic canStart;
- (BOOL) canStart {
	return (NO == self.started && NO == self.finished && NO == self.wasCanceled);
}

@dynamic canCancel;
- (BOOL) canCancel {
	return (YES == self.isStarted && NO == self.isFinished && NO == self.wasCanceled);
}

@dynamic canAbort;
- (BOOL) canAbort {
	return (NO == self.started && NO == self.finished && NO == self.wasCanceled);
}



// Overrides

- (NSURLRequest *) URLRequest {
	if (URLRequest_ == nil) {
		URLRequest_ = [originalURLRequest_ mutableCopy];
		[self configureURLRequest:URLRequest_];
	}
	return URLRequest_;
}

- (NSMutableDictionary *) headers {
	if (headers_ == nil) {
		headers_ = [NSMutableDictionary new];
	}
	return headers_;
}

- (NSMutableArray *) authProviders {
	if (nil == authProviders_) {
		authProviders_ = [NSMutableArray new];
	}
	return authProviders_;
}

- (NSMutableData *) data {
    if (data_ == nil) {
        data_ = [NSMutableData new];
    }
    return data_;
}

- (id<RCCoder>) payloadEncoder {
	NSString *contentType = @"Not set";
    if (payloadEncoder_ == nil) {
		// First, check for obvious conversions of payload by class
		payloadEncoder_ = [RCCoder coderForObject:payload_];
		
		contentType = [URLRequest_ valueForHTTPHeaderField:@"Content-Type"];

        if (nil == payloadEncoder_) { // we have an non-literal object type, figure out encoding based on content type
            if (contentType && contentType.length > 0) {
                payloadEncoder_ = [RCCoder coderForMimeType:contentType];
            }
        }
        
    }
	NSAssert2(payloadEncoder_ != nil,  @"Unable to convert payload to HTTPBody using payload.class: %@, Content-Type: %@. Make sure you are using a compatible object type or have set an appropriate Content-Type.", NSStringFromClass([payload_ class]), contentType);
    return payloadEncoder_;
}

- (id<RCCoder>) responseDecoder {
    if (responseDecoder_ == nil) {
        NSString *contentType = [[URLResponse_ allHeaderFields] valueForKey:@"Content-Type"];
        if (contentType.length > 0) { // First, let's try content type, because the server is telling us what it sent
            responseDecoder_ = [RCCoder coderForMimeType:contentType];
        }
        if (responseDecoder_ == nil) { 
            // If we didn't get a decoder from content type, we will try and build a decoder based on what we were expecting
            NSString *accepts = [URLRequest_ valueForHTTPHeaderField:@"Accept"];
            if (accepts && accepts.length > 0) {
                responseDecoder_ = [RCCoder coderForMimeType:accepts];
            }
        }
        if (responseDecoder_ == nil) { // We will essentially just pass set the NSData as the result and downstream users will have to figure out what to do with it
            responseDecoder_ = [RCIdentityCoder new];
        }
    }
    return responseDecoder_;
}


// ========================================================================== //

#pragma mark - Object



- (id) initWithURLRequest:(NSURLRequest*)URLRequest {
    self = [super init];
	NSAssert(URLRequest != nil, @"URLRequest cannot be nil!");
	if (nil == URLRequest) {
		self = nil;
	}
    if (self) {
		self.originalURLRequest = URLRequest;
		self.cachePolicy = NSURLRequestUseProtocolCachePolicy;
		self.maxAuthRetries = 1;
    }
    
    return self;
}

+ (id) startRequestWithURLRequest:(NSURLRequest*)URLRequest queue:(NSOperationQueue *)queue completionBlock:(RCCompletionBlock)block {
	RCRequest *request = [[self alloc] initWithURLRequest:URLRequest];
	request.completionBlock = block;
	[request start];
    return request;
}

- (NSString *) description {
	NSURLRequest *request = nil == URLRequest_ ? originalURLRequest_ : URLRequest_;
	return [NSString stringWithFormat:@"%@ : %@ %@",[super description],[request HTTPMethod],[request description]];
}



// ========================================================================== //

#pragma mark - Control


- (void) start {
	NSAssert(NO == self.started, @"Attempting to start a request that has already been started, canceled or finished");
	if (NO == self.canStart) {
		return;
	}
	
    self.started = YES;

	self.connection = [[NSURLConnection alloc] initWithRequest:self.URLRequest delegate:self startImmediately:NO];
//    [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	[self.connection setDelegateQueue:[RCRequest opQ]];
    [self.connection start];
	RCLog(@"%@", self);

	[self handleConnectionDidSendData];
	[self handleConnectionDidReceiveData];
	

	if (self.timeout > 0) {
		self.timeoutTimer = [NSTimer timerWithTimeInterval:self.timeout target:self selector:@selector(timeoutFired:) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:self.timeoutTimer forMode:NSDefaultRunLoopMode];		
	}	
}

- (void) startWithCompletionBlock:(RCCompletionBlock)block {
    self.completionBlock = block;
    [self start];
}

- (void) cancel {
    if (NO == self.canCancel) {
		RCLog(@"Attempting to cancel a request that has not been started, has already been canceled or has finished ");
        return;
    }
    self.canceled = YES;

//	[self.connection cancel];
	// strangely, not calling this on the main thread will cause other calls to dispatch on the main thread (like to completion block) to deadlock, freakish
	[self.connection performSelectorOnMainThread:@selector(cancel) withObject:nil waitUntilDone:NO];
    [self handleConnectionFinished];
}


- (void) abort {
	if (NO == self.canAbort) {
		RCLog(@"Attempting to abort a request that has already been started, canceled or finished ");
		return;
	}
    if (self.abortBlock) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.abortBlock(self);
        });
    }
}

- (void) abortWithBlock:(RCAbortBlock)abortBlock {
	self.abortBlock = abortBlock;
	[self abort];
}

- (void) timeoutFired:(NSTimer *)timer {
	[self.timeoutTimer invalidate];
	self.timeoutTimer = nil;
    if (nil == self.URLResponse) {
		NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
							  [NSString stringWithFormat:@"Request did not receive a response before specified timeout (%f)",self.timeout], NSLocalizedDescriptionKey
							  , self.URLRequest.URL, NSURLErrorFailingURLErrorKey
							  , nil];
		NSError *timeoutError = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorTimedOut userInfo:info];
		self.error = timeoutError;
        [self cancel];
    }
}



// ========================================================================== //

#pragma mark - Connection Event Handlers



- (void) handleConnectionFinished {
    if (self.connectionFinished) {
        return;
    }
	self.connectionFinished = YES;
	RCResponse *response = [[RCResponse alloc] initWithRequest:self];

	// Make sure processing the results doesn't stop us from calling our completion block
	@try {
		dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		dispatch_queue_t q_current = dispatch_get_current_queue();
		NSAssert(q != q_current, @"Tried to run response processing on the current queue! ** DEADLOCK **");
		dispatch_sync(q, ^{
			[self processResponse:response];
		});
	}
	@catch (NSException *exception) {
		self.error = [NSError errorWithDomain:kRESTClientErrorDomain code:kRESTClientErrorCodeErrorProcessingResponse userInfo:[exception userInfo]];
	}
	@finally {
		if (self.completionBlock) {
			dispatch_async(dispatch_get_main_queue(), ^{
				self.completionBlock(response);
			});
		}
		self.timeoutTimer = nil;
		self.finished = YES;
	}
}


- (void) handleConnectionDidReceiveData {
	float progress = 0;
	if (self.expectedContentLength > 0) {
		progress = self.receivedContentLength / self.expectedContentLength;
	}
	if (self.didReceiveDataBlock) {
		
		NSMutableDictionary *progressInfo = [NSDictionary dictionaryWithObjectsAndKeys:
											 [NSNumber numberWithFloat:progress], kRESTClientProgressInfoKeyProgress
											 , [self.URLRequest URL], kRESTClientProgressInfoKeyURL
											 , nil];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.didReceiveDataBlock(progressInfo);
		});
	}
}

- (void) handleConnectionDidSendData {
	float progress = 0;
	if (self.bodyContentLength > 0) {
		progress = self.sentContentLength / self.bodyContentLength;
	}
	
	if (self.didSendDataBlock) {		
		NSMutableDictionary *progressInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:
											 [NSNumber numberWithFloat:progress], kRESTClientProgressInfoKeyProgress
											 , [self.URLRequest URL], kRESTClientProgressInfoKeyURL
											 , nil];
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.didSendDataBlock(progressInfo);
		});
	}
}


// ========================================================================== //

#pragma mark - URLRequest/Response Helpers


- (void) configureURLRequest:(NSMutableURLRequest *)URLRequest {
	[URLRequest setAllHTTPHeaderFields:self.headers];
	
	for (id<RCAuthProvider> authProvider in self.authProviders) {
		[authProvider authorizeRequest:URLRequest];
	}
	
	URLRequest.cachePolicy = self.cachePolicy;
    
	// if there is a payload, encode it
	if (self.payload) {
		URLRequest.HTTPBody = [self.payloadEncoder encodeObject:self.payload];
	}
}

- (void) processResponse:(RCResponse *)response {
    
	// if there was a response body, decode it
    if (self.data.length) {
        NSString *responseString = [[NSString alloc] initWithData:self.data encoding:NSUTF8StringEncoding];
		self.responseBody = responseString;
        
		if (self.responseDecoder) {
			self.result = [self.responseDecoder decodeData:self.data];
		}
		
		if (self.postProcessorBlock) {
			self.result = self.postProcessorBlock(response, self.result);
		}
    }
}


// ========================================================================== //

#pragma mark - NSURLConnectionDelegate


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	self.error = error;
	[self handleConnectionFinished];
}

// NSURLConnection.h says this is still valid, docs say it's deprecated, in any event it seems to never get called anymore ...
- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection {
	return NO;
}

- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	NSString *authMethod = [[challenge protectionSpace] authenticationMethod];
	
	id<RCAuthProvider> providerForMethod = nil;
	for (id<RCAuthProvider> provider in self.authProviders) {
		if ([provider.providedAuthenticationMethod isEqualToString:authMethod]) {
			providerForMethod = provider;
			break;
		}
	}

	if (providerForMethod) {		
		NSURLCredential *credential = [providerForMethod credentialForAuthenticationChallenge:challenge];	
		if (credential) {
            if ([challenge previousFailureCount] < self.maxAuthRetries) {
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
            } else {
                [[challenge sender] cancelAuthenticationChallenge:challenge];
            }
		} else {
			[[challenge sender] cancelAuthenticationChallenge:challenge];
		}
	} else {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
    }
}


// ========================================================================== //

#pragma mark - NSURLConnectionDataDelegate


- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
	if (response && self.authProviders.count > 0) {
		NSMutableURLRequest *authorizedRequest = [request mutableCopy];
		for (id<RCAuthProvider> authProvider in self.authProviders) {
			[authProvider authorizeRequest:authorizedRequest];
		}
		return authorizedRequest;
	}
	return request;
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	self.sentContentLength = totalBytesWritten;
	self.bodyContentLength = totalBytesExpectedToWrite;
	
	[self handleConnectionDidSendData];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	self.URLResponse = (NSHTTPURLResponse *)response;
	self.expectedContentLength = [response expectedContentLength];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.data appendData:data];

	NSUInteger dataLength = [data length];
	self.receivedContentLength += dataLength;
	[self handleConnectionDidReceiveData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self handleConnectionFinished];
}






@end
