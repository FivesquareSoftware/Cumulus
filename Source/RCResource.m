//
//  RCResource.m
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

#import "RCResource.h"

#import "RCConstants.h"
#import "RCRequest.h"
#import "RESTClient.h"


@interface RCResource() {
	dispatch_semaphore_t requests_semaphore_;
}

// Readwrite Versions of Public Properties

@property (nonatomic, readwrite, strong) RCResource *parent;
@property (nonatomic, readwrite, strong) NSString *relativePath;
@property (nonatomic, readwrite, strong) NSURL *URL;

// Private Properties

@property (nonatomic, strong) NSMutableSet *requests_; ///< The internal property for directly accessing request objects

// Request Builder

- (RCRequest *) requestForHTTPMethod:(NSString *)method;
- (RCDownloadRequest *) downloadRequest;
- (RCUploadRequest *) uploadRequestWithFileURL:(NSURL *)fileURL;


// Helpers

- (void) setHeadersForContentType:(RESTClientContentType)contentType;
- (NSMutableURLRequest *) URLRequestForHTTPMethod:(NSString *)method;
- (void) configureRequest:(RCRequest *)request;

// Runners

- (RCResponse *) runBlockingRequest:(RCRequest *)request;
- (void) runRequest:(RCRequest *)request withCompletionBlock:(RCCompletionBlock)completionBlock;
- (void) runRequest:(RCRequest *)request withCompletionBlock:(RCCompletionBlock)completionBlock abortBlock:(RCAbortBlock)abortBlock;
- (void) dispatchRequest:(RCRequest *)request withCompletionBlock:(RCCompletionBlock)completionBlock;

- (void) addRequest:(RCRequest *)request;
- (void) removeRequest:(RCRequest *)request;

@end


@implementation RCResource

// ========================================================================== //

#pragma mark - Properties


// Public

@synthesize parent=parent_;
@synthesize relativePath=relativePath_;
@synthesize URL=URL_;
@synthesize headers=headers_;
@synthesize timeout=timeout_;
@synthesize cachePolicy=cachePolicy_;
@synthesize username=username_;
@synthesize password=password_;
@synthesize authProvider=authProvider_;
@synthesize contentType=contentType_;
@synthesize preflightBlock=preflightBlock_;
@synthesize postProcessorBlock=postprocessorBlock_;
@synthesize requests_;


- (NSMutableDictionary *) headers {
    if (nil == headers_) {
        headers_ = [NSMutableDictionary dictionary];
    }
    return headers_;
}

@dynamic mergedHeaders;
- (NSMutableDictionary *) mergedHeaders {
	NSMutableDictionary *mergedHeaders = [NSMutableDictionary dictionary];
	
	[mergedHeaders addEntriesFromDictionary:parent_.mergedHeaders];
	
	[mergedHeaders addEntriesFromDictionary:headers_];
	return mergedHeaders;
}

- (NSTimeInterval) timeout {
	if (timeout_ == 0 && parent_.timeout > 0) {
		return parent_.timeout;
	}
	return timeout_;
}

- (NSURLRequestCachePolicy) cachePolicy {
	if (cachePolicy_ == NSURLRequestUseProtocolCachePolicy && parent_.cachePolicy != NSURLRequestUseProtocolCachePolicy) {
		return parent_.cachePolicy;
	}
	return cachePolicy_;
}

- (id<RCAuthProvider>) authProvider {
	if (nil == authProvider_ && parent_.authProvider) {
		return parent_.authProvider;
	}
	if (nil == authProvider_ && username_.length && password_.length) {
		authProvider_ = [RCBasicAuthProvider withUsername:username_ password:password_];
	}
	return authProvider_;
}

- (RESTClientContentType) contentType {
	if (contentType_ == RESTClientContentTypeNone && parent_.contentType > RESTClientContentTypeNone) {
		return parent_.contentType;
	}
	return contentType_;
}

- (void) setContentType:(RESTClientContentType)contentType {
    if (contentType_ != contentType) {
        contentType_ = contentType;  
        [self setHeadersForContentType:contentType_];
    }
}

- (RCPreflightBlock) preflightBlock {
	if (nil == preflightBlock_ && parent_.preflightBlock != nil) {
		return parent_.preflightBlock;
	}
	return preflightBlock_;
}

- (RCPostProcessorBlock) postProcessorBlock {
	if (nil == postprocessorBlock_ && parent_.postProcessorBlock != nil) {
		return parent_.postProcessorBlock;
	}
	return postprocessorBlock_;
}

@dynamic requests;
- (NSMutableSet *) requests {
	dispatch_semaphore_wait(requests_semaphore_, DISPATCH_TIME_FOREVER);
	NSMutableSet *requests = [NSMutableSet setWithSet:self.requests_];
	dispatch_semaphore_signal(requests_semaphore_);
	return requests;
}


// Private



// ========================================================================== //

#pragma mark - Object

- (void)dealloc {
	dispatch_release(requests_semaphore_);
}

+ (id) withURL:(NSString *)URLString {
	return [[RCResource alloc] initWithURL:URLString];
}

- (id) initWithURL:(NSString *)URLString {
	self = [super init];
	if (self) {
		self.URL = [NSURL URLWithString:URLString];
		if (URL_ == nil) {
			self = nil;
			return self;
		}
		self.cachePolicy = NSURLRequestUseProtocolCachePolicy;
		requests_ = [NSMutableSet new];
		
		requests_semaphore_ = dispatch_semaphore_create(1);
	}
	return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@: %@",[super description],[self.URL absoluteURL]];
}


// ========================================================================== //

#pragma mark - Resource



- (RCResource *) resource:(id)relativePathObject {
	NSAssert(URL_ != nil,@"Cannot construct a resource without a base URL!");
	
	NSString *relativePath;
	if ([relativePath isKindOfClass:[NSString class]]) {
		relativePath = relativePathObject;
	} else {
		relativePath = [relativePathObject description];
	}
	
	//rdar: 10487909, must remove preceding slash because URLByAppendingPathComponent is adding one incorrectly
	relativePath = [relativePath stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
	
	NSURL *resourceURL = [URL_ URLByAppendingPathComponent:relativePath];
	resourceURL = [resourceURL standardizedURL];
	
	RCResource *resource = [RCResource withURL:[resourceURL absoluteString]];
	
	resource.parent = self;
	
	return resource;
}

- (RCResource *) resourceWithFormat:(NSString *)relativePathFormat,... {
	va_list args;
	va_start(args,relativePathFormat);
	NSString *relativePath = [[NSString alloc] initWithFormat:relativePathFormat arguments:args];
	va_end(args);        

	return [self resource:relativePath];
}


// ========================================================================== //

#pragma mark - Configuration

- (void) setValue:(id)value forHeaderField:(NSString *)key {
	[self.headers setObject:value forKey:key];
}




// ========================================================================== //

#pragma mark - Request Control

- (void) cancelRequests {
	[self cancelRequestsWithBlock:nil];
}

- (void) cancelRequestsWithBlock:(void (^)(void))block {
	dispatch_queue_t request_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

	dispatch_async(request_queue, ^{
		dispatch_semaphore_wait(requests_semaphore_, DISPATCH_TIME_FOREVER);

		for (RCRequest *request in self.requests_) {			
			[request cancel];
		}
		[self.requests_ removeAllObjects];

		dispatch_semaphore_signal(requests_semaphore_);

		if (block) {
			dispatch_async(dispatch_get_main_queue(), block);
		}
	});
}


// ========================================================================== //

#pragma mark - HTTP Requests


#pragma mark -GET



- (RCResponse *) get {        
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodGET];
    return [self runBlockingRequest:request];	
}

- (void) getWithCompletionBlock:(RCCompletionBlock)completionBlock {
	[self getWithProgressBlock:nil completionBlock:completionBlock];
}

- (void) getWithProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodGET];
	request.didReceiveDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -HEAD



- (RCResponse *) head {
    RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodHEAD];
    return [self runBlockingRequest:request];	
}

- (void) headWithCompletionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodHEAD];
	[self runRequest:request withCompletionBlock:completionBlock];
}



#pragma mark -DELETE


- (RCResponse *) delete {
    RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodDELETE];
    return [self runBlockingRequest:request];	
}

- (void) deleteWithCompletionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodDELETE];
	[self runRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -POST


- (RCResponse *) post:(id)payload {
    RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPOST];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) post:(id)payload completionBlock:(RCCompletionBlock)completionBlock {
	[self post:payload progressBlock:nil completionBlock:completionBlock];
}

- (void) post:(id)payload progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPOST];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}



#pragma mark -PUT


- (RCResponse *) put:(id)payload {
    RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPUT];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) put:(id)payload completionBlock:(RCCompletionBlock)completionBlock {
	[self put:payload progressBlock:nil completionBlock:completionBlock];
}

- (void) put:(id)payload progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPUT];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}



#pragma mark -Files


- (void) downloadWithProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCDownloadRequest *request = [self downloadRequest];
	request.didReceiveDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}

- (void) uploadFile:(NSURL *)fileURL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self uploadRequestWithFileURL:fileURL];
	request.didSendDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}



// ========================================================================== //

#pragma mark - Request Builders



- (RCRequest *) requestForHTTPMethod:(NSString *)method {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:method];
	RCRequest *request = [[RCRequest alloc] initWithURLRequest:URLRequest];
	[self configureRequest:request];
	return request;
}

- (RCDownloadRequest *) downloadRequest {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:kRESTClientHTTPMethodGET];
	RCDownloadRequest *request = [[RCDownloadRequest alloc] initWithURLRequest:URLRequest];
	[self configureRequest:request];
	return request;
}

- (RCUploadRequest *) uploadRequestWithFileURL:(NSURL *)fileURL {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:kRESTClientHTTPMethodPUT];
	RCUploadRequest *request = [[RCUploadRequest alloc] initWithURLRequest:URLRequest];
	[self configureRequest:request];
	request.fileToUploadURL = fileURL;
	return request;
}




// ========================================================================== //

#pragma mark - Request Helpers


- (void) setHeadersForContentType:(RESTClientContentType)contentType {
	switch (contentType) {
		case RESTClientContentTypeJSON:
			[self.headers setObject:@"application/json" forKey:@"Content-Type"];
			[self.headers setObject:@"application/json" forKey:@"Accept"];
			break;
		case RESTClientContentTypeXML:
			[self.headers setObject:@"application/xml" forKey:@"Content-Type"];
			[self.headers setObject:@"application/xml" forKey:@"Accept"];
			break;
		case RESTClientContentTypeHTML:
			[self.headers setObject:@"text/html" forKey:@"Content-Type"];
			[self.headers setObject:@"text/html" forKey:@"Accept"];
			break;			
		default:
			break;
	}
}

- (NSMutableURLRequest *) URLRequestForHTTPMethod:(NSString *)method {
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:self.URL];
	[URLRequest setHTTPMethod:method];
	[URLRequest setAllHTTPHeaderFields:self.mergedHeaders];
	
	return URLRequest;
}

- (void) configureRequest:(RCRequest *)request {
	request.timeout = self.timeout;
	request.authProvider = self.authProvider;
	request.postProcessorBlock = self.postProcessorBlock;
	request.cachePolicy = self.cachePolicy;
}


// ========================================================================== //

#pragma mark - Request Runners



- (RCResponse *) runBlockingRequest:(RCRequest *)request {	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
    __block RCResponse *localResponse = nil;
	
	RCCompletionBlock completionBlock = ^(RCResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	RCAbortBlock abortBlock = ^(RCRequest *request) {
		dispatch_semaphore_signal(request_sema);
	};

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[self runRequest:request withCompletionBlock:completionBlock abortBlock:abortBlock];

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
    return localResponse;
}

- (void) runRequest:(RCRequest *)request withCompletionBlock:(RCCompletionBlock)completionBlock {
	[self runRequest:request withCompletionBlock:completionBlock abortBlock:NULL];
}

- (void) runRequest:(RCRequest *)request withCompletionBlock:(RCCompletionBlock)completionBlock abortBlock:(RCAbortBlock)abortBlock {
	if (self.preflightBlock) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if(self.preflightBlock(request)) {
				[self dispatchRequest:request withCompletionBlock:completionBlock];
			} else {
				[request abortWithBlock:abortBlock];
			}
		});
	} else {
		[self dispatchRequest:request withCompletionBlock:completionBlock];
	}
}

- (void) dispatchRequest:(RCRequest *)request withCompletionBlock:(RCCompletionBlock)completionBlock {
	dispatch_queue_t request_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(request_queue, ^{
		[self addRequest:request];
		[request startWithCompletionBlock:^(RCResponse *response){
			if (completionBlock) {
				completionBlock(response);
			}
			dispatch_async(request_queue, ^{
				[self removeRequest:request];
			});
		}];
	});
}

- (void) addRequest:(RCRequest *)request {
	dispatch_semaphore_wait(requests_semaphore_, DISPATCH_TIME_FOREVER);
	[self.requests_ addObject:request];
	dispatch_semaphore_signal(requests_semaphore_);
}

- (void) removeRequest:(RCRequest *)request {
	dispatch_semaphore_wait(requests_semaphore_, DISPATCH_TIME_FOREVER);
	[self.requests_ removeObject:request];
	dispatch_semaphore_signal(requests_semaphore_);
}


@end
