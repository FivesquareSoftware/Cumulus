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
#import "RCFixtureRequest.h"
#import "RCFixtureDownloadRequest.h"
#import "RESTClient.h"

#import "NSDictionary+RESTClient.h"
#import "NSString+RESTClient.h"


@interface RCResource() {
	dispatch_semaphore_t requests_semaphore_;
}

// Readwrite Versions of Public Properties

@property (nonatomic, readwrite, strong) RCResource *parent;
@property (nonatomic, readwrite, strong) NSString *relativePath;
@property (nonatomic, readwrite, strong) NSURL *URL;

// Private Properties

@property (nonatomic, readonly) NSMutableDictionary *mergedHeaders; ///< All headers from all ancestors and the receiver merged into one dictionary
@property (nonatomic, readonly) NSMutableArray *mergedAuthProviders; ///< All #authProviders from all ancestors and the receiver merged into one array
@property (nonatomic, strong) NSMutableSet *requests_; ///< The internal property for directly accessing request objects
@property (nonatomic, strong) NSMutableDictionary *fixtures;

// Request Builder

- (RCRequest *) requestForHTTPMethod:(NSString *)method;
- (RCRequest *) requestForHTTPMethod:(NSString *)method query:(id)query;
- (RCRequest *) downloadRequestWithQuery:query;
- (RCRequest *) uploadRequestWithFileURL:(NSURL *)fileURL query:(id)query;

// Helpers

- (void) setHeadersForContentType:(RESTClientContentType)contentType;
- (NSMutableURLRequest *) URLRequestForHTTPMethod:(NSString *)method query:(id)query ;
- (void) configureRequest:(RCRequest *)request;
- (NSString *) requestSignatureForHTTPMethod:(NSString *)method;

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
@synthesize cachesDir=cachesDir_;
@synthesize username=username_;
@synthesize password=password_;
@synthesize authProviders=authProviders_;
@synthesize contentType=contentType_;
@synthesize preflightBlock=preflightBlock_;
@synthesize postProcessorBlock=postprocessorBlock_;

@dynamic queryString;
- (NSString *) queryString {
	return [self.URL query];
}

- (NSMutableDictionary *) headers {
    if (nil == headers_) {
        headers_ = [NSMutableDictionary dictionary];
    }
    return headers_;
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

- (NSString *) cachesDir {
	if (nil == cachesDir_) {
		return [RESTClient cachesDir];
	}
	return cachesDir_;
}

- (NSMutableArray *) authProviders {
	if (nil == authProviders_) {
		authProviders_ = [NSMutableArray new];
	}
	return authProviders_;
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

@synthesize requests_;
@synthesize fixtures=fixtures_;


@dynamic mergedHeaders;
- (NSMutableDictionary *) mergedHeaders {
	NSMutableDictionary *mergedHeaders = [NSMutableDictionary dictionary];	
	[mergedHeaders addEntriesFromDictionary:parent_.mergedHeaders];
	[mergedHeaders addEntriesFromDictionary:headers_];
	return mergedHeaders;
}


@dynamic mergedAuthProviders;
- (NSMutableArray *) mergedAuthProviders {
	NSMutableArray *mergedProviders = [NSMutableArray array];
	if (self.authProviders.count == 0 && username_.length && password_.length) {
		[self addAuthProvider:[RCBasicAuthProvider withUsername:username_ password:password_]];
	}
	[mergedProviders addObjectsFromArray:authProviders_];
	[mergedProviders addObjectsFromArray:parent_.mergedAuthProviders];
	return mergedProviders;
}

- (NSMutableDictionary *) fixtures {
	if (fixtures_ == nil) {
		fixtures_ = [NSMutableDictionary new];
	}
	return fixtures_;
}


// ========================================================================== //

#pragma mark - Object

- (void)dealloc {
	dispatch_release(requests_semaphore_);
}

+ (id) withURL:(id)URL {
	return [[RCResource alloc] initWithURL:URL];
}

- (id) initWithURL:(id)URL {
	self = [super init];
	if (self) {
		if ([URL isKindOfClass:[NSString class]]) {
			self.URL = [NSURL URLWithString:URL];
		} else {
			self.URL = URL;
		}
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
	relativePath = [relativePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	NSString *queryString = [relativePath queryString:&relativePath];
	
	NSURL *resourceURL = [URL_ URLByAppendingPathComponent:relativePath];
	resourceURL = [resourceURL standardizedURL];
	
	if (queryString.length) {
		resourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",[resourceURL absoluteString],queryString]];
	}
	
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
	if (value) {
		if (NO == [value isKindOfClass:[NSString class]]) {
			value = [value description];
		}
		[self.headers setObject:value forKey:key];
	} else {
		[self.headers removeObjectForKey:key];
	}
}

- (id) valueForHeaderField:(NSString *)key {
	return [self.headers objectForKey:key];
}

- (void) addAuthProvider:(id<RCAuthProvider>)authProvider {
	[self.authProviders addObject:authProvider];
}


// ========================================================================== //

#pragma mark - Fixtures


- (void) setFixture:(id)value forHTTPMethod:(NSString *)method {
	[self.fixtures setObject:value forKey:[self requestSignatureForHTTPMethod:method]];
}

- (id) fixtureForHTTPMethod:(NSString *)method {
	NSString *requestSignature = [self requestSignatureForHTTPMethod:method];
	id fixture =  [self.fixtures objectForKey:requestSignature];
	if (fixture == nil && [RESTClient usingFixtures]) {
		fixture = [[RESTClient fixtures] objectForKey:requestSignature];
	}
	return fixture;
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

- (RCResponse *) getWithQuery:(id)query {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodGET query:query];
    return [self runBlockingRequest:request];	
}

- (void) getWithCompletionBlock:(RCCompletionBlock)completionBlock query:(id)query {
	[self getWithProgressBlock:nil completionBlock:completionBlock query:query];
}

- (void) getWithProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock query:(id)query {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodGET query:query];
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

- (RCResponse *) headWithQuery:(id)query {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodHEAD query:query];
    return [self runBlockingRequest:request];	
}

- (void) headWithCompletionBlock:(RCCompletionBlock)completionBlock query:(id)query {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodHEAD query:query];
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

- (RCResponse *) deleteWithQuery:(id)query {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodDELETE query:query];
    return [self runBlockingRequest:request];	
}

- (void) deleteWithCompletionBlock:(RCCompletionBlock)completionBlock query:(id)query {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodDELETE query:query];
	[self runRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -POST


- (RCResponse *) post:(id)payload {
    RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPOST];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) post:(id)payload withCompletionBlock:(RCCompletionBlock)completionBlock {
	[self post:payload withProgressBlock:nil completionBlock:completionBlock];
}

- (void) post:(id)payload withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPOST];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}

- (RCResponse *) post:(id)payload withQuery:(id)query {
    RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPOST query:query];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) post:(id)payload withCompletionBlock:(RCCompletionBlock)completionBlock query:(id)query {
	[self post:payload withProgressBlock:nil completionBlock:completionBlock query:query];
}

- (void) post:(id)payload withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock query:(id)query {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPOST query:query];
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

- (void) put:(id)payload withCompletionBlock:(RCCompletionBlock)completionBlock {
	[self put:payload withProgressBlock:nil completionBlock:completionBlock];
}

- (void) put:(id)payload withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPUT];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}

- (RCResponse *) put:(id)payload withQuery:(id)query {
    RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPUT query:query];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) put:(id)payload withCompletionBlock:(RCCompletionBlock)completionBlock query:(id)query {
	[self post:payload withProgressBlock:nil completionBlock:completionBlock query:query];
}

- (void) put:(id)payload withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock query:(id)query {
	RCRequest *request = [self requestForHTTPMethod:kRESTClientHTTPMethodPUT query:query];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -Files


- (void) downloadWithProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self downloadRequestWithQuery:nil];
	request.didReceiveDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}

- (void) uploadFile:(NSURL *)fileURL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCRequest *request = [self uploadRequestWithFileURL:fileURL query:nil];
	request.didSendDataBlock = progressBlock;
	[self runRequest:request withCompletionBlock:completionBlock];
}



// ========================================================================== //

#pragma mark - Request Builders



- (RCRequest *) requestForHTTPMethod:(NSString *)method {
	return [self requestForHTTPMethod:method query:nil];
}

- (RCRequest *) requestForHTTPMethod:(NSString *)method query:(id)query {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:method query:query];
	RCRequest *request;
	id fixture = nil;
	if ( (fixture = [self fixtureForHTTPMethod:method]) ) {
		request = [[RCFixtureRequest alloc] initWithURLRequest:URLRequest fixture:fixture];
	} else {
		request = [[RCRequest alloc] initWithURLRequest:URLRequest];
	}
	[self configureRequest:request];
	return request;
}

- (RCRequest *) downloadRequestWithQuery:query {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:kRESTClientHTTPMethodGET query:query];
	RCRequest *request;
	id fixture = nil;
	if ( (fixture = [self fixtureForHTTPMethod:kRESTClientHTTPMethodGET]) ) {
		request = [[RCFixtureDownloadRequest alloc] initWithURLRequest:URLRequest fixture:fixture];
	} else {
		request = [[RCDownloadRequest alloc] initWithURLRequest:URLRequest];
	}
	[(RCDownloadRequest *)request setCachesDir:self.cachesDir];
	[self configureRequest:request];
	return request;
}

- (RCRequest *) uploadRequestWithFileURL:(NSURL *)fileURL query:(id)query {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:kRESTClientHTTPMethodPUT query:query];
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
			[self.headers setObject:@"application/json" forKey:kRESTClientHTTPHeaderContentType];
			[self.headers setObject:@"application/json" forKey:kRESTClientHTTPHeaderAccept];
			break;
		case RESTClientContentTypeXML:
			[self.headers setObject:@"application/xml" forKey:kRESTClientHTTPHeaderContentType];
			[self.headers setObject:@"application/xml" forKey:kRESTClientHTTPHeaderAccept];
			break;
		case RESTClientContentTypeHTML:
			[self.headers setObject:@"text/html" forKey:kRESTClientHTTPHeaderContentType];
			[self.headers setObject:@"text/html" forKey:kRESTClientHTTPHeaderAccept];
			break;			
		case RESTClientContentTypeText:
			[self.headers setObject:@"text/plain" forKey:kRESTClientHTTPHeaderContentType];
			[self.headers setObject:@"text/plain" forKey:kRESTClientHTTPHeaderAccept];
			break;			
		case RESTClientContentTypePNG:
			[self.headers setObject:@"image/png" forKey:kRESTClientHTTPHeaderContentType];
			[self.headers setObject:@"image/png" forKey:kRESTClientHTTPHeaderAccept];
			break;			
		default:
			break;
	}
}

- (NSMutableURLRequest *) URLRequestForHTTPMethod:(NSString *)method query:(id)query {
	NSString *queryString = nil;
	if (query) {
		NSDictionary *queryDictionary;
		if ([query isKindOfClass:[NSDictionary class]]) {
			queryDictionary = query;
		} else {
			id firstObject = [query count] > 0 ? [query objectAtIndex:0] : nil;
			if ([firstObject isKindOfClass:[NSDictionary class]]) {
				queryDictionary = firstObject;
			} else {
				NSUInteger idx = 0;
				NSMutableArray *queryValues = [NSMutableArray new];
				NSMutableArray *queryKeys = [NSMutableArray new];
				for (id queryObject in query) {
					BOOL isKey = ( (idx % 2) == 0 );
					if (isKey) {
						[queryKeys addObject:queryObject];
					} else {
						[queryValues addObject:queryObject];
					}
					idx++;
				}	
				queryDictionary = [NSDictionary dictionaryWithObjects:queryValues forKeys:queryKeys];
			}			
		}
		queryString = [queryDictionary toQueryString];
	}
	
	NSURL *requestURL;
	if (queryString.length) {
		if (self.queryString) {
			requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@&%@",self.URL,queryString]];
		} else {
			requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",self.URL,queryString]];
		}
	} else {
		requestURL = self.URL;
	}
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];
	[URLRequest setHTTPMethod:method];
	return URLRequest;
}

- (void) configureRequest:(RCRequest *)request {
	request.timeout = self.timeout;
	[request.authProviders addObjectsFromArray:self.mergedAuthProviders];
	request.postProcessorBlock = self.postProcessorBlock;
	request.cachePolicy = self.cachePolicy;
	[request.headers addEntriesFromDictionary:self.mergedHeaders];
}

- (NSString *) requestSignatureForHTTPMethod:(NSString *)method {
	return [NSString stringWithFormat:@"%@ %@",method,URL_];
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

	if ([NSThread currentThread] == [NSThread mainThread]) {
		while(dispatch_semaphore_wait(request_sema, 0.01) != 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantPast]];
		}
	} else {
		dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	}
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
			BOOL success = self.preflightBlock(request);
			if(success) {
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
