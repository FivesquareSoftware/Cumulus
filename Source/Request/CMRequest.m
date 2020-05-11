//
//	CMRequest.m
//	Cumulus
//
//	Created by John Clayton on 7/23/11.
//	Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

/*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *	  notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *	  this list of conditions and the following disclaimer in the documentation
 *	  and/or other materials provided with the distribution.
 *
 * 3. Neither the name of Fivesquare Software nor the names of its contributors may
 *	  be used to endorse or promote products derived from this software without
 *	  specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL FIVESQUARE SOFTWARE BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CMRequest.h"
#import "CMRequest+Protected.h"

#import "Cumulus.h"


static dispatch_queue_t __activityQueue = nil;

@implementation CMRequest


+ (void) load {
	static dispatch_once_t __activityQueueOnceToken;
	dispatch_once(&__activityQueueOnceToken, ^{
		__activityQueue = dispatch_queue_create("com.fivesquaresoftware.CMRequest.activityQueue", DISPATCH_QUEUE_SERIAL);
	});
}


static NSInteger __requestCount = 0;
+ (NSUInteger) requestCount {
	__block NSInteger requestCount = 0;
	dispatch_sync(__activityQueue, ^{
		requestCount = __requestCount;
	});
	if (requestCount < 0) {
		requestCount = 0;
	}
	return (NSUInteger)requestCount;
}

static BOOL __networkActivityIndicatorVisible = NO;
+ (void) incrementRequestCountFor:(id)context {
	dispatch_sync(__activityQueue, ^{
		__requestCount++;
//		CMLog(@"__requestCount++: %@ ** %@ **",@(__requestCount),context);
#if TARGET_OS_IPHONE
		if (__requestCount > 0 && NO == __networkActivityIndicatorVisible) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
				__networkActivityIndicatorVisible = YES;
			});
		}
#endif
	});
}

+ (void) decrementRequestCountFor:(id)context {
	dispatch_sync(__activityQueue, ^{
		__requestCount--;
//		CMLog(@"__requestCount--: %@ ** %@ **",@(__requestCount),context);
		if (__requestCount < 0) {
			CMLog(@"** Unbalanced calls to request count  ** %@)",context);
		}
#if TARGET_OS_IPHONE
		if (__requestCount < 1 && __networkActivityIndicatorVisible) {
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
			__networkActivityIndicatorVisible = NO;
		}
#endif
	});
}

// ========================================================================== //

#pragma mark - Properties



// Public


@dynamic elapsed;
- (NSTimeInterval) elapsed {
	NSDate *endDate = self.endedAt;
	if (nil == endDate) {
		endDate = [NSDate date];
	}
	return [endDate timeIntervalSinceDate:self.startedAt];
}

@dynamic bytesPerSecond;
- (NSUInteger) bytesPerSecond {
	NSUInteger bytesPerSecond = 0;
	NSTimeInterval elapsed = self.elapsed;
	if (elapsed > 0) {
		long long receivedBytes = self.receivedContentLength;
		bytesPerSecond = receivedBytes/elapsed;
	}
	return bytesPerSecond;
}

@dynamic completed;
- (BOOL) didComplete {
	// A streamed file most likely, but either way we don't know the length, assume it's complete
	if (self.responseInternal.expectedContentLength == NSURLResponseUnknownLength) {
		return YES;
	}
	// - A range request is complete if the length of the range was returned
	// - A non-range request is complete if the expected content length was returned
	// #responseInternal.contentLength captures both of these cases
	return self.responseInternal.expectedContentLength == self.receivedContentLength;
}

@dynamic URL;
- (NSURL *) URL {
	return _originalURLRequest.URL;
}

@dynamic progressReceivedInfo;
- (CMProgressInfo *) progressReceivedInfo {
	CMProgressInfo *progressReceivedInfo = [CMProgressInfo new];
	progressReceivedInfo.request = self;
	progressReceivedInfo.URL = [self.URLRequest URL];
	float progress = 0;
	if (self.expectedContentLength > 0) {
		progress = (float)self.receivedContentLength / (float)self.expectedContentLength;
		progressReceivedInfo.progress = @(progress);
	}
	else {
		progressReceivedInfo.progress = @(0);
	}
	progressReceivedInfo.chunkSize = @(self.lastChunkSize);
	progressReceivedInfo.fileOffset = @(self.receivedContentLength);
	progressReceivedInfo.bytesPerSecond = @(self.bytesPerSecond);
	progressReceivedInfo.elapsedTime = @(self.elapsed);
	progressReceivedInfo.contentLength = @(self.responseInternal.expectedContentLength);
	return progressReceivedInfo;
}

@dynamic progressSentInfo;
- (CMProgressInfo *) progressSentInfo {
	CMProgressInfo *progressSentInfo = [CMProgressInfo new];
	progressSentInfo.request = self;
	progressSentInfo.URL = [self.URLRequest URL];
	float progress = 0;
	if (self.bodyContentLength > 0) {
		progress = (float)self.sentContentLength / (float)self.bodyContentLength;
		progressSentInfo.progress = [NSNumber numberWithFloat:progress];
	}
	else {
		progressSentInfo.progress = @(0);
	}
	return progressSentInfo;
}


// Private


@dynamic fileExtension;
- (NSString *) fileExtension {
	return [self.URLRequest.URL pathExtension];
}

@dynamic canStart;
- (BOOL) canStart {
	return (NO == self.started && NO == self.finished/* && NO == self.wasCanceled*/);
}

@dynamic canCancel;
- (BOOL) canCancel {
	return (/*YES == self.isStarted && */NO == self.isFinished && NO == self.wasCanceled);
}

@dynamic canAbort;
- (BOOL) canAbort {
	return (NO == self.started && NO == self.finished && NO == self.wasCanceled);
}

@dynamic cacheIdentifier;
- (id) cacheIdentifier {
	NSMutableString *identifier = [NSMutableString stringWithString:self.URL.absoluteString];
	if (self.range.location != kCFNotFound) {
		[identifier appendFormat:@", bytes=%lld-%lld",self.range.location,CMContentRangeLastByte(self.range)];
	}
	return identifier;
}

- (CMResponse *) responseInternal {
	if (nil == _responseInternal && NO == self.connectionFinished) {
		_responseInternal = [[CMResponse alloc] initWithRequest:self];
	}
	return _responseInternal;
}


// Overrides

@synthesize URLRequest=_URLRequest;
- (NSURLRequest *) URLRequest {
	if (_URLRequest == nil) {
		_URLRequest = [_originalURLRequest mutableCopy];
		[self configureURLRequest:_URLRequest];
	}
	return _URLRequest;
}

@synthesize headers=_headers;
- (NSMutableDictionary *) headers {
	if (_headers == nil) {
		_headers = [NSMutableDictionary new];
	}
	// Once the request exists, we defer to it for the current headers
	if (self.requestIsConfigured) {
		[_headers removeAllObjects];
		[_headers addEntriesFromDictionary:[_URLRequest allHTTPHeaderFields]];
	}
	return _headers;
}

@dynamic acceptHeader;
- (NSString *) acceptHeader {
	return [self.headers objectForKey:kCumulusHTTPHeaderAccept];
}

@dynamic contentTypeHeader;
- (NSString *) contentTypeHeader {
	return [self.headers objectForKey:kCumulusHTTPHeaderContentType];
}

@synthesize authProviders=_authProviders;
- (NSMutableArray *) authProviders {
	if (nil == _authProviders) {
		_authProviders = [NSMutableArray new];
	}
	return _authProviders;
}

@synthesize data=_data;
- (NSMutableData *) data {
	if (_data == nil) {
		_data = [NSMutableData new];
	}
	return _data;
}

- (id<CMCoder>) payloadEncoder {
	NSString *contentType = @"Not set";
	if (_payloadEncoder == nil) {
		// First, check for obvious conversions of payload by class and file extension
		_payloadEncoder = [CMCoder coderForObject:_payload];
		
		if (_payloadEncoder == nil) {
			_payloadEncoder = [CMCoder coderForFileExtension:self.fileExtension];
		}
		
		contentType = [_URLRequest valueForHTTPHeaderField:kCumulusHTTPHeaderContentType];
		
		if (nil == _payloadEncoder) { // we have an non-literal object type, figure out encoding based on content type
			if (contentType && contentType.length > 0) {
				_payloadEncoder = [CMCoder coderForMimeType:contentType];
			}
		}
		
	}
	NSAssert2(_payloadEncoder != nil,  @"Unable to convert payload to HTTPBody using payload.class: %@, Content-Type: %@. Make sure you are using a compatible object type or file extension, or have set an appropriate Content-Type.", NSStringFromClass([_payload class]), contentType);
	return _payloadEncoder;
}

- (id<CMCoder>) responseDecoder {
	if (_responseDecoder == nil) {
		NSString *contentType = [[_URLResponse allHeaderFields] valueForKey:kCumulusHTTPHeaderContentType];
		if (contentType.length > 0) { // First, let's try content type, because the server is telling us what it sent
			_responseDecoder = [CMCoder coderForMimeType:contentType];
		}
		if (_responseDecoder == nil) {
			// If we didn't get a decoder from content type, we will try and build a decoder based on what we were expecting
			
			_responseDecoder = [CMCoder coderForFileExtension:self.fileExtension];
			
			if (_responseDecoder == nil) {
				NSString *accepts = [_URLRequest valueForHTTPHeaderField:kCumulusHTTPHeaderAccept];
				if (accepts && accepts.length > 0) {
					_responseDecoder = [CMCoder coderForMimeType:accepts];
				}
			}
			
		}
		if (_responseDecoder == nil) { // We will essentially just pass set the NSData as the result and downstream users will have to figure out what to do with it
			_responseDecoder = [CMIdentityCoder new];
		}
	}
	return _responseDecoder;
}

@dynamic queryDictionary;
- (NSDictionary *) queryDictionary {
	NSMutableDictionary *queryDictionary = [NSMutableDictionary new];
	NSString *queryString = [[self.URLRequest URL] query];
	if (queryString) {
		NSArray *paramPairs = [queryString componentsSeparatedByString:@"&"];
		[paramPairs enumerateObjectsUsingBlock:^(NSString *pair, NSUInteger idx, BOOL *stop) {
			NSArray *params = [pair componentsSeparatedByString:@"="];
			if (params.count == 2) {
				id key = params[0];
				id value = params[1];
				[queryDictionary setObject:value forKey:key];
			}
		}];
	}
	return queryDictionary;
}


// ========================================================================== //

#pragma mark - Object

- (void)dealloc {
	//	  [self removeObserver:self forKeyPath:@"scope"];
}

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
		self.range = (CMContentRange){ kCFNotFound , 0, 0 };
	}
	
	return self;
}

- (NSString *) description {
	NSURLRequest *request = nil == _URLRequest ? _originalURLRequest : _URLRequest;
	NSString *stateString;
	if (self.wasCanceled) {
		stateString = @"canceled";
	}
	else if (self.isFinished) {
		stateString = @"finished";
	}
	else if (self.isStarted) {
		stateString = @"running";
	}
	else {
		stateString = @"waiting";
	}
	return [NSString stringWithFormat:@"%@(identifier: '%@', state: %@) : %@ %@",[super description],_identifier,stateString,[request HTTPMethod],[request description]];
}


// ========================================================================== //

#pragma mark - Control


- (BOOL) start {
	NSAssert(self.canStart, @"Attempting to start a request that has already been started or has finished");
	if (NO == self.canStart) {
		CMLog(@"Attempting to start a request that has already been started or has finished");
		return NO;
	}
	
	// If a request was asked to cancel before it was completely set up, we will handle that now and bail
	if (self.wasCanceled) {
		CMLog(@"Attempting to start a canceled request, completing now instead");
		[self handleConnectionFinished];
		return NO;
	}
	
	
	self.started = YES;
	self.startedAt = [NSDate date];
	
	[self handleConnectionWillStart];

	NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:self.URLRequest delegate:self startImmediately:NO];
	if (nil == self.connectionDelegateQueue) {
		[connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
	}
	else {
		[connection setDelegateQueue:self.connectionDelegateQueue];
	}

	[connection start];
	self.connection = connection;
	CMLog(@"%@", self);
	
	[self handleConnectionDidSendData];
	[self handleConnectionDidReceiveData];
	
	
	if (self.timeout > 0) {
		NSTimer *timeoutTimer = [NSTimer timerWithTimeInterval:self.timeout target:self selector:@selector(timeoutFired:) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:timeoutTimer forMode:NSDefaultRunLoopMode];
		self.timeoutTimer = timeoutTimer;
	}
	return YES;
}

- (BOOL) startWithCompletionBlock:(CMCompletionBlock)block {
	self.completionBlock = block;
	return [self start];
}

- (BOOL) startOnQueue:(NSOperationQueue *)delegateQueue withCompletionBlock:(CMCompletionBlock)completionBlock {
	self.connectionDelegateQueue = delegateQueue;
	return [self start];
}

- (BOOL) cancel {
	if (NO == self.canCancel) {
		CMLog(@"Attempting to cancel a request that has already been canceled or has finished ");
		return NO;
	}
	self.canceled = YES;

	// We don't call the completion block otherwise, deferring until start is called. i.e. unless someone has called start, we assume they don't really want to fire the completion block
	if (self.started) {
		//	[self.connection cancel];
		// strangely, *NOT* calling this on the main thread will cause other calls to dispatch on the main thread (like to completion block) to deadlock, freakish, something about the connection needing to be canceled on the same runloop it was canceled on?
		[self.connection performSelectorOnMainThread:@selector(cancel) withObject:nil waitUntilDone:NO];
		[self handleConnectionFinished];
	}
	return YES;
}


- (BOOL) abort {
	if (NO == self.canAbort) {
		CMLog(@"Attempting to abort a request that has already been started, canceled or finished ");
		return NO;
	}
	if (self.abortBlock) {
		dispatch_async(dispatch_get_main_queue(), ^{
			self.abortBlock(self);
		});
	}
	return YES;
}

- (BOOL) abortWithBlock:(CMAbortBlock)abortBlock {
	self.abortBlock = abortBlock;
	return [self abort];
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


- (void) handleConnectionWillStart {
	// Generally used by subclasses to effect request customization
	[CMRequest incrementRequestCountFor:self];
}

- (void) handleConnectionDidReceiveResponse {
	// Generally used by subclasses to make adjustments based on initial information from the server
}

- (void) handleConnectionDidReceiveData {
	if (self.canceled || self.connectionFinished) {
		return;
	}
	if (self.didReceiveDataBlock) {
		CMProgressInfo *progressInfo = self.progressReceivedInfo;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.didReceiveDataBlock(progressInfo);
		});
	}
}

- (void) handleConnectionDidSendData {
	if (self.canceled || self.connectionFinished) {
		return;
	}
	if (self.didSendDataBlock) {
		CMProgressInfo *progressInfo = self.progressSentInfo;
		
		dispatch_async(dispatch_get_main_queue(), ^{
			self.didSendDataBlock(progressInfo);
		});
	}
}

- (void) handleConnectionFinished {
	if (self.connectionFinished) {
		return;
	}
	
	[CMRequest decrementRequestCountFor:self];
	
	CMResponse *blockResponse = self.responseInternal; // Make sure we create one if needed, because they can't be created once we pass connectionFinished = YES
	self.connectionFinished = YES;
	
	// Make sure processing the results doesn't stop us from calling our completion block
	@try {
		dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
		dispatch_sync(q, ^{
			[self postProcessResponse:blockResponse];
		});
	}
	@catch (NSException *exception) {
		self.error = [NSError errorWithDomain:kCumulusErrorDomain code:kCumulusErrorCodeErrorProcessingResponse userInfo:[exception userInfo]];
	}
	@finally {
		if (self.completionBlock) {
			dispatch_async(dispatch_get_main_queue(), ^{
				self.completionBlock(blockResponse);
				self.responseInternal = nil;
			});
		}
		else {
			self.responseInternal = nil;
		}
		self.timeoutTimer = nil;
		self.finished = YES;
		self.endedAt = [NSDate date];
	}
}


// ========================================================================== //

#pragma mark - URLRequest/Response Helpers


- (void) configureURLRequest:(NSMutableURLRequest *)URLRequest {
	[URLRequest setAllHTTPHeaderFields:self.headers];
	
	for (id<CMAuthProvider> authProvider in self.authProviders) {
		[authProvider authorizeRequest:URLRequest];
	}
	
	URLRequest.cachePolicy = self.cachePolicy;
	
	// if there is a payload, encode it
	if (self.payload) {
		URLRequest.HTTPBody = [self.payloadEncoder encodeObject:self.payload];
	}
	
	if (self.timeout > 0) {
		URLRequest.timeoutInterval = self.timeout;
	}
	
	if (self.range.location != kCFNotFound) {
		[URLRequest setValue:[NSString stringWithFormat:@"bytes=%lld-%lld",self.range.location,CMContentRangeLastByte(self.range)] forHTTPHeaderField:kCumulusHTTPHeaderRange];
	}
	
	self.requestConfigured = YES;
}

- (void) postProcessResponse:(CMResponse *)response {
	
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

- (NSString *) mimeTypeForFileAtPath:(NSString *)filePath {
	CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[filePath pathExtension], NULL);
	NSString *MIMEType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
	CFRelease(UTI);
	
	if (nil == MIMEType) {
		MIMEType = @"text/plain";
	}
	return MIMEType;
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
	
	id<CMAuthProvider> providerForMethod = nil;
	for (id<CMAuthProvider> provider in self.authProviders) {
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
	}
	else {
		[[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
	}
}


// ========================================================================== //

#pragma mark - NSURLConnectionDataDelegate


- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response {
	if (response && self.authProviders.count > 0) {
		NSMutableURLRequest *authorizedRequest = [request mutableCopy];
		for (id<CMAuthProvider> authProvider in self.authProviders) {
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
	//	CMLog(@"response.headers: %@",[self.URLResponse allHeaderFields]);
	//	self.expectedContentLength = [response expectedContentLength]; // fails when there is no content length header, often in a range request this is true
	// Works for simple requests as well as range requests
	self.expectedContentLength = self.responseInternal.expectedContentLength;
	[self handleConnectionDidReceiveResponse];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[self.data appendData:data];
	
	NSUInteger dataLength = [data length];
	self.receivedContentLength += dataLength;
	self.lastChunkSize = dataLength;
	[self handleConnectionDidReceiveData];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[self handleConnectionFinished];
}





@end
