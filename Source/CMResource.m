//
//  CMResource.m
//  Cumulus
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

#import "CMResource.h"

#import "Cumulus.h"

#import "CMFixtureRequest.h"
#import "CMFixtureDownloadRequest.h"

#import "CMResourceGroup+Protected.h"
#import "NSDictionary+Cumulus.h"
#import "NSString+Cumulus.h"


@interface CMResource() {
	dispatch_semaphore_t _requests_semaphore;
}

// Readwrite Versions of Public Properties

@property (nonatomic, readwrite, strong) CMResource *parent;
@property (nonatomic, readwrite, strong) NSString *relativePath;
@property (nonatomic, readwrite, strong) NSURL *URL;

// Private Properties

@property (nonatomic, readonly) NSMutableDictionary *mergedHeaders; ///< All headers from all ancestors and the receiver merged into one dictionary
@property (nonatomic, readonly) NSMutableArray *mergedAuthProviders; ///< All #authProviders from all ancestors and the receiver merged into one array
@property (nonatomic, strong) NSMutableSet *_requests; ///< The internal property for directly accessing request objects
@property (nonatomic, strong) NSMutableDictionary *fixtures;


@end


@implementation CMResource

+ (dispatch_queue_t) dispatchQueue {
	static dispatch_queue_t _dispatch_queue = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dispatch_queue = dispatch_queue_create("com.fivesquaresoftware.CMResource.dispatch_queue", DISPATCH_QUEUE_SERIAL);
	});
	return _dispatch_queue;
}

// ========================================================================== //

#pragma mark - Properties


// Public

@synthesize parent=_parent;
@synthesize relativePath=_relativePath;
@synthesize URL=_URL;
@synthesize headers=_headers;
@synthesize timeout=_timeout;
@synthesize cachePolicy=_cachePolicy;
@synthesize cachesDir=_cachesDir;
@synthesize username=_username;
@synthesize password=_password;
@synthesize authProviders=_authProviders;
@synthesize contentType=_contentType;
@synthesize preflightBlock=_preflightBlock;
@synthesize postProcessorBlock=_postprocessorBlock;
@synthesize resourceGroup = _resourceGroup;

@dynamic queryString;
- (NSString *) queryString {
	return [self.URL query];
}

- (NSMutableDictionary *) headers {
    if (nil == _headers) {
        _headers = [NSMutableDictionary dictionary];
    }
    return _headers;
}

- (NSTimeInterval) timeout {
	if (_timeout == 0 && _parent.timeout > 0) {
		return _parent.timeout;
	}
	return _timeout;
}

- (NSURLRequestCachePolicy) cachePolicy {
	if (_cachePolicy == NSURLRequestUseProtocolCachePolicy && _parent.cachePolicy != NSURLRequestUseProtocolCachePolicy) {
		return _parent.cachePolicy;
	}
	return _cachePolicy;
}

- (NSString *) cachesDir {
	if (nil == _cachesDir) {
		return [Cumulus cachesDir];
	}
	return _cachesDir;
}

- (NSMutableArray *) authProviders {
	if (nil == _authProviders) {
		_authProviders = [NSMutableArray new];
	}
	return _authProviders;
}

- (CMContentType) contentType {
	if (_contentType == CMContentTypeNone && _parent.contentType > CMContentTypeNone) {
		return _parent.contentType;
	}
	return _contentType;
}

- (void) setContentType:(CMContentType)contentType {
    if (_contentType != contentType) {
        _contentType = contentType;  
        [self setHeadersForContentType:_contentType];
    }
}

- (CMPreflightBlock) preflightBlock {
	if (nil == _preflightBlock && _parent.preflightBlock != nil) {
		return _parent.preflightBlock;
	}
	return _preflightBlock;
}

- (CMPostProcessorBlock) postProcessorBlock {
	if (nil == _postprocessorBlock && _parent.postProcessorBlock != nil) {
		return _parent.postProcessorBlock;
	}
	return _postprocessorBlock;
}

@dynamic requests;
- (NSMutableSet *) requests {
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	NSMutableSet *requests = [NSMutableSet setWithSet:self._requests];
	dispatch_semaphore_signal(_requests_semaphore);
	return requests;
}

- (void) setResourceGroup:(CMResourceGroup *)resourceGroup {
	if (_resourceGroup != resourceGroup) {
		_resourceGroup = resourceGroup;
		[_resourceGroup addResource:self];
	}
}


// Private

@synthesize _requests;
@synthesize fixtures=_fixtures;


@dynamic mergedHeaders;
- (NSMutableDictionary *) mergedHeaders {
	NSMutableDictionary *mergedHeaders = [NSMutableDictionary dictionary];	
	[mergedHeaders addEntriesFromDictionary:_parent.mergedHeaders];
	[mergedHeaders addEntriesFromDictionary:_headers];
	return mergedHeaders;
}


@dynamic mergedAuthProviders;
- (NSMutableArray *) mergedAuthProviders {
	NSMutableArray *mergedProviders = [NSMutableArray array];
	if (self.authProviders.count == 0 && _username.length && _password.length) {
		[self addAuthProvider:[CMBasicAuthProvider withUsername:_username password:_password]];
	}
	[mergedProviders addObjectsFromArray:_authProviders];
	[mergedProviders addObjectsFromArray:_parent.mergedAuthProviders];
	return mergedProviders;
}

- (NSMutableDictionary *) fixtures {
	if (_fixtures == nil) {
		_fixtures = [NSMutableDictionary new];
	}
	return _fixtures;
}


// ========================================================================== //

#pragma mark - Object

- (void)dealloc {
	dispatch_release(_requests_semaphore);
}

+ (id) withURL:(id)URL {
	return [[CMResource alloc] initWithURL:URL];
}

- (id) initWithURL:(id)URL {
	self = [super init];
	if (self) {
		if ([URL isKindOfClass:[NSString class]]) {
			self.URL = [NSURL URLWithString:URL];
		} else {
			self.URL = URL;
		}
		if (_URL == nil) {
			self = nil;
			return self;
		}
		self.cachePolicy = NSURLRequestUseProtocolCachePolicy;
		_requests = [NSMutableSet new];
		
		_requests_semaphore = dispatch_semaphore_create(1);
	}
	return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@: %@",[super description],[self.URL absoluteURL]];
}


// ========================================================================== //

#pragma mark - Resource



- (CMResource *) resource:(id)relativePathObject {
	NSAssert(_URL != nil,@"Cannot construct a resource without a base URL!");
	
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
	
	NSURL *resourceURL = [_URL URLByAppendingPathComponent:relativePath];
	resourceURL = [resourceURL standardizedURL];
	
	if (queryString.length) {
		resourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",[resourceURL absoluteString],queryString]];
	}
	
	CMResource *resource = [CMResource withURL:[resourceURL absoluteString]];
	
	resource.parent = self;
	
	return resource;
}

- (CMResource *) resourceWithFormat:(NSString *)relativePathFormat,... {
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

- (void) addAuthProvider:(id<CMAuthProvider>)authProvider {
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
	if (fixture == nil && [Cumulus usingFixtures]) {
		fixture = [[Cumulus fixtures] objectForKey:requestSignature];
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
		dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);

		for (CMRequest *request in self._requests) {			
			[request cancel];
		}
		[self._requests removeAllObjects];

		dispatch_semaphore_signal(_requests_semaphore);

		if (block) {
			dispatch_async(dispatch_get_main_queue(), block);
		}
	});
}


// ========================================================================== //

#pragma mark - HTTP Requests


#pragma mark -GET



- (CMResponse *) get {        
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET];
    return [self runBlockingRequest:request];	
}

- (void) getWithCompletionBlock:(CMCompletionBlock)completionBlock {
	[self getWithProgressBlock:nil completionBlock:completionBlock];
}

- (void) getWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET];
	request.didReceiveDataBlock = progressBlock;
	[self launchRequest:request withCompletionBlock:completionBlock];
}

- (CMResponse *) getWithQuery:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET query:query];
    return [self runBlockingRequest:request];	
}

- (void) getWithCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	[self getWithProgressBlock:nil completionBlock:completionBlock query:query];
}

- (void) getWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET query:query];
	request.didReceiveDataBlock = progressBlock;
	[self launchRequest:request withCompletionBlock:completionBlock];
}

#pragma mark -HEAD



- (CMResponse *) head {
    CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD];
    return [self runBlockingRequest:request];	
}

- (void) headWithCompletionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD];
	[self launchRequest:request withCompletionBlock:completionBlock];
}

- (CMResponse *) headWithQuery:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD query:query];
    return [self runBlockingRequest:request];	
}

- (void) headWithCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD query:query];
	[self launchRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -DELETE


- (CMResponse *) delete {
    CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodDELETE];
    return [self runBlockingRequest:request];	
}

- (void) deleteWithCompletionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodDELETE];
	[self launchRequest:request withCompletionBlock:completionBlock];
}

- (CMResponse *) deleteWithQuery:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodDELETE query:query];
    return [self runBlockingRequest:request];	
}

- (void) deleteWithCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodDELETE query:query];
	[self launchRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -POST


- (CMResponse *) post:(id)payload {
    CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPOST];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) post:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock {
	[self post:payload withProgressBlock:nil completionBlock:completionBlock];
}

- (void) post:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPOST];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self launchRequest:request withCompletionBlock:completionBlock];
}

- (CMResponse *) post:(id)payload withQuery:(id)query {
    CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPOST query:query];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) post:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	[self post:payload withProgressBlock:nil completionBlock:completionBlock query:query];
}

- (void) post:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPOST query:query];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self launchRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -PUT


- (CMResponse *) put:(id)payload {
    CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPUT];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) put:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock {
	[self put:payload withProgressBlock:nil completionBlock:completionBlock];
}

- (void) put:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPUT];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self launchRequest:request withCompletionBlock:completionBlock];
}

- (CMResponse *) put:(id)payload withQuery:(id)query {
    CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPUT query:query];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (void) put:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	[self post:payload withProgressBlock:nil completionBlock:completionBlock query:query];
}

- (void) put:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPUT query:query];
    request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	[self launchRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -Files


- (void) downloadWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	[self downloadWithResume:NO progressBlock:progressBlock completionBlock:completionBlock];
}

- (void) downloadWithResume:(BOOL)shouldResume progressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest<CMDownloadRequest> *request = [self downloadRequestWithQuery:nil];
	request.didReceiveDataBlock = progressBlock;
	request.shouldResume = shouldResume;
	[self launchRequest:request withCompletionBlock:completionBlock];
}

- (void) uploadFile:(NSURL *)fileURL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self uploadRequestWithFileURL:fileURL query:nil];
	request.didSendDataBlock = progressBlock;
	[self launchRequest:request withCompletionBlock:completionBlock];
}



// ========================================================================== //

#pragma mark - Request Builders



- (CMRequest *) requestForHTTPMethod:(NSString *)method {
	return [self requestForHTTPMethod:method query:nil];
}

- (CMRequest *) requestForHTTPMethod:(NSString *)method query:(id)query {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:method query:query];
	CMRequest *request;
	id fixture = nil;
	if ( (fixture = [self fixtureForHTTPMethod:method]) ) {
		request = [[CMFixtureRequest alloc] initWithURLRequest:URLRequest fixture:fixture];
	} else {
		request = [[CMRequest alloc] initWithURLRequest:URLRequest];
	}
	[self configureRequest:request];
	return request;
}

- (CMRequest<CMDownloadRequest> *) downloadRequestWithQuery:query {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:kCumulusHTTPMethodGET query:query];
	CMRequest<CMDownloadRequest> *request;
	id fixture = nil;
	if ( (fixture = [self fixtureForHTTPMethod:kCumulusHTTPMethodGET]) ) {
		request = [[CMFixtureDownloadRequest alloc] initWithURLRequest:URLRequest fixture:fixture];
	} else {
		request = [[CMDownloadRequest alloc] initWithURLRequest:URLRequest];
	}
	[(CMDownloadRequest *)request setCachesDir:self.cachesDir];
	[self configureRequest:request];
	return request;
}

- (CMRequest *) uploadRequestWithFileURL:(NSURL *)fileURL query:(id)query {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:kCumulusHTTPMethodPUT query:query];
	CMUploadRequest *request = [[CMUploadRequest alloc] initWithURLRequest:URLRequest];
	[self configureRequest:request];
	request.fileToUploadURL = fileURL;
	return request;
}




// ========================================================================== //

#pragma mark - Request Helpers


- (void) setHeadersForContentType:(CMContentType)contentType {
	switch (contentType) {
		case CMContentTypeJSON:
			[self.headers setObject:@"application/json" forKey:kCumulusHTTPHeaderContentType];
			[self.headers setObject:@"application/json" forKey:kCumulusHTTPHeaderAccept];
			break;
		case CMContentTypeXML:
			[self.headers setObject:@"application/xml" forKey:kCumulusHTTPHeaderContentType];
			[self.headers setObject:@"application/xml" forKey:kCumulusHTTPHeaderAccept];
			break;
		case CMContentTypeHTML:
			[self.headers setObject:@"text/html" forKey:kCumulusHTTPHeaderContentType];
			[self.headers setObject:@"text/html" forKey:kCumulusHTTPHeaderAccept];
			break;			
		case CMContentTypeText:
			[self.headers setObject:@"text/plain" forKey:kCumulusHTTPHeaderContentType];
			[self.headers setObject:@"text/plain" forKey:kCumulusHTTPHeaderAccept];
			break;			
		case CMContentTypePNG:
			[self.headers setObject:@"image/png" forKey:kCumulusHTTPHeaderContentType];
			[self.headers setObject:@"image/png" forKey:kCumulusHTTPHeaderAccept];
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
		}
		else {
			id firstObject = [query count] > 0 ? [query objectAtIndex:0] : nil;
			if ([firstObject isKindOfClass:[NSDictionary class]]) {
				queryDictionary = firstObject;
			}
			else {
				NSUInteger idx = 0;
				NSMutableArray *queryValues = [NSMutableArray new];
				NSMutableArray *queryKeys = [NSMutableArray new];
				for (id queryObject in query) {
					BOOL isKey = ( (idx % 2) == 0 );
					if (isKey) {
						[queryKeys addObject:queryObject];
					}
					else {
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
		}
		else {
			requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",self.URL,queryString]];
		}
	}
	else {
		requestURL = self.URL;
	}
	NSMutableURLRequest *URLRequest = [[NSMutableURLRequest alloc] initWithURL:requestURL];
	[URLRequest setHTTPMethod:method];
	return URLRequest;
}

- (void) configureRequest:(CMRequest *)request {
	request.timeout = self.timeout;
	[request.authProviders addObjectsFromArray:self.mergedAuthProviders];
	request.postProcessorBlock = self.postProcessorBlock;
	request.cachePolicy = self.cachePolicy;
	[request.headers addEntriesFromDictionary:self.mergedHeaders];
}

- (NSString *) requestSignatureForHTTPMethod:(NSString *)method {
	return [NSString stringWithFormat:@"%@ %@",method,_URL];
}




// ========================================================================== //

#pragma mark - Request Runners



- (CMResponse *) runBlockingRequest:(CMRequest *)request {	
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(1);
    __block CMResponse *localResponse = nil;
	
	CMCompletionBlock completionBlock = ^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	CMAbortBlock abortBlock = ^(CMRequest *request) {
		dispatch_semaphore_signal(request_sema);
	};

	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	[self launchRequest:request withCompletionBlock:completionBlock abortBlock:abortBlock];

	if ([NSThread currentThread] == [NSThread mainThread]) {
		while(dispatch_semaphore_wait(request_sema, 0.01) != 0) {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantPast]];
		}
	}
	else {
		dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	}
	dispatch_semaphore_signal(request_sema);
	dispatch_release(request_sema);
    return localResponse;
}

- (void) launchRequest:(CMRequest *)request withCompletionBlock:(CMCompletionBlock)completionBlock {
	[self launchRequest:request withCompletionBlock:completionBlock abortBlock:NULL];
}

- (void) launchRequest:(CMRequest *)request withCompletionBlock:(CMCompletionBlock)completionBlock abortBlock:(CMAbortBlock)abortBlock {
	dispatch_semaphore_t launch_sema = dispatch_semaphore_create(0);
	
	CMPreflightBlock preflightBlock = self.preflightBlock;
	if (preflightBlock) {
		dispatch_async(dispatch_get_main_queue(), ^{
			BOOL success = preflightBlock(request);
			if(success) {
				[self dispatchRequest:request withCompletionBlock:completionBlock launchSemaphore:launch_sema];
			}
			else {
				[request abortWithBlock:abortBlock];
			}
		});
	}
	else {
		[self dispatchRequest:request withCompletionBlock:completionBlock launchSemaphore:launch_sema];
	}
	
	dispatch_semaphore_wait(launch_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(launch_sema);
}

- (void) dispatchRequest:(CMRequest *)request withCompletionBlock:(CMCompletionBlock)completionBlock launchSemaphore:(dispatch_semaphore_t)launch_semaphore {
	dispatch_queue_t request_queue = [CMResource dispatchQueue];//dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	dispatch_async(request_queue, ^{
		[self addRequest:request];
		[request startWithCompletionBlock:^(CMResponse *response){
			if (completionBlock) {
				completionBlock(response);
			}
			dispatch_async(request_queue, ^{
				[self removeRequest:request];
			});
		}];
		dispatch_semaphore_signal(launch_semaphore);
	});
}

- (void) addRequest:(CMRequest *)request {
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	[self._requests addObject:request];
	_resourceGroup = (__bridge CMResourceGroup *)(dispatch_get_context([CMResource dispatchQueue]));
	if (_resourceGroup) {
		RCLog(@"addRequest ->");
		[_resourceGroup enter];
	}
	dispatch_semaphore_signal(_requests_semaphore);
}

- (void) removeRequest:(CMRequest *)request {
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	[self._requests removeObject:request];
	_resourceGroup = (__bridge CMResourceGroup *)(dispatch_get_context([CMResource dispatchQueue]));
	if (_resourceGroup) {
		RCLog(@"removeRequest  ->");
		[_resourceGroup leaveWithResponse:request.response];
	}
	dispatch_semaphore_signal(_requests_semaphore);
}


@end
