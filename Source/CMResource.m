//
//	CMResource.m
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

#import "CMResource.h"

#import "Cumulus.h"

#import "CMFixtureRequest.h"
#import "CMFixtureDownloadRequest.h"

#import "CMResourceContextScope.h"
#import "CMResourceContextGroup.h"

#import "NSDictionary+Cumulus.h"
#import "NSString+Cumulus.h"


@interface CMResource() {
	dispatch_semaphore_t _requests_semaphore;
}

+ (dispatch_queue_t) dispatchQueue;

// Readwrite Versions of Public Properties

@property (nonatomic, readwrite, strong) CMResource *parent;
@property (nonatomic, readwrite, strong) NSString *relativePath;
@property (nonatomic, readwrite, strong) NSURL *URL;

// Private Properties

/// The mutable headers collection for internal use
@property (nonatomic, strong) NSMutableDictionary *headersInternal;
/// The mutable querty dictionary for internal use
@property (nonatomic, strong) NSMutableDictionary *queryInternal;


/// All headers from all ancestors and the receiver merged into one dictionary
@property (nonatomic, readonly) NSMutableDictionary *mergedHeaders;
/// All queries from all ancestors and the receiver merged into one dictionary
@property (nonatomic, readonly) NSMutableDictionary *mergedQuery;
/// All #authProviders from all ancestors and the receiver merged into one array
@property (nonatomic, readonly) NSMutableArray *mergedAuthProviders;

/// The internal property for directly accessing request objects
@property (nonatomic, strong) NSMutableSet *requestsInternal;
@property (nonatomic, strong) NSMutableDictionary *fixtures;

@property (nonatomic) NSDateFormatter *httpDateFormatter;

/// Queue for controlling write access to the lastModified value
@property (nonatomic, assign) dispatch_queue_t lastModifiedQueue;



@end


@implementation CMResource

+ (dispatch_queue_t) dispatchQueue {
	static dispatch_queue_t _dispatchQueue = nil;
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		_dispatchQueue = dispatch_queue_create("com.fivesquaresoftware.CMResource.dispatchQueue", DISPATCH_QUEUE_CONCURRENT);
	});
	return _dispatchQueue;
}

// ========================================================================== //

#pragma mark - Properties


// Public


@dynamic queryString;
- (NSString *) queryString {
	NSMutableDictionary *queryDictionary = self.mergedQuery;
	
	NSString *queryString = nil;
	if ([queryDictionary count] > 0) {
		queryString = [queryDictionary toQueryString];
	}

	return queryString;
}

@dynamic headers;
- (NSDictionary *) headers {
	return [self.headersInternal copy];
}

- (void) setHeaders:(NSDictionary *)headers {
	self.headersInternal = [headers mutableCopy];
}

- (NSMutableDictionary *) headersInternal {
	if (nil == _headersInternal) {
		_headersInternal = [NSMutableDictionary dictionary];
	}
	return _headersInternal;
}

@dynamic query;
- (NSDictionary *) query {
	return [self.queryInternal copy];
}

- (void) setQuery:(NSDictionary *)query {
	self.queryInternal = [query mutableCopy];
}

- (NSMutableDictionary *) queryInternal {
	if (nil == _queryInternal) {
		_queryInternal = [NSMutableDictionary dictionary];
	}
	return _queryInternal;
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

@synthesize contentType=_contentType;
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

@synthesize lastModified = _lastModified;
- (void) setLastModified:(NSDate *)lastModified {
	if (_lastModified != lastModified) {
		dispatch_barrier_sync(self.lastModifiedQueue, ^{
			_lastModified = lastModified;
			[self setValue:[_httpDateFormatter stringFromDate:_lastModified] forHeaderField:kCumulusHTTPHeaderIfModifiedSince];
		});
	}
}

- (NSDate *)lastModified {
	__block NSDate *lastModifiedValue;
	dispatch_sync(self.lastModifiedQueue, ^{
		lastModifiedValue = _lastModified;
	});
	return lastModifiedValue;
}


- (CMPreflightBlock) preflightBlock {
	if (nil == _preflightBlock && _parent.preflightBlock != nil) {
		return _parent.preflightBlock;
	}
	return _preflightBlock;
}

@synthesize postProcessorBlock=_postprocessorBlock;
- (CMPostProcessorBlock) postProcessorBlock {
	if (nil == _postprocessorBlock && _parent.postProcessorBlock != nil) {
		return _parent.postProcessorBlock;
	}
	return _postprocessorBlock;
}

@dynamic requests;
- (NSMutableSet *) requests {
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	NSMutableSet *requests = [NSMutableSet setWithSet:self.requestsInternal];
	dispatch_semaphore_signal(_requests_semaphore);
	return requests;
}


// Private



@dynamic mergedHeaders;
- (NSMutableDictionary *) mergedHeaders {
	NSMutableDictionary *mergedHeaders = [NSMutableDictionary dictionary];
	[mergedHeaders addEntriesFromDictionary:_parent.mergedHeaders];
	[mergedHeaders addEntriesFromDictionary:_headersInternal];
	return mergedHeaders;
}

@dynamic mergedQuery;
- (NSMutableDictionary *) mergedQuery {
	NSMutableDictionary *mergedQuery = [NSMutableDictionary dictionary];
	[mergedQuery addEntriesFromDictionary:_parent.mergedQuery];
	[mergedQuery addEntriesFromDictionary:_queryInternal];
	return mergedQuery;
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
		_requestsInternal = [NSMutableSet new];
		
		_requests_semaphore = dispatch_semaphore_create(1);
		
		_chunkSize = 0;
		_maxConcurrentChunks = kCMChunkedDownloadRequestDefaultMaxConcurrentChunks;
		_readBufferLength = kCMChunkedDownloadRequestDefaultBufferSize;
		
		NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setDateFormat:kHTTPDateFormat];
		_httpDateFormatter = dateFormatter;
		
		NSString *queueName = [NSString stringWithFormat:@"com.fivesquaresoftware.CMResource.lastModifiedQueue.%p", self];
		_lastModifiedQueue = dispatch_queue_create([queueName UTF8String], DISPATCH_QUEUE_CONCURRENT);
		
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
	
	NSMutableDictionary *query = nil;
	if (queryString.length) {
		//		resourceURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",[resourceURL absoluteString],queryString]];
		query = [NSMutableDictionary new];
		NSArray *pairs = [queryString componentsSeparatedByString:@"&"];
		[pairs enumerateObjectsUsingBlock:^(NSString *pair, NSUInteger idx, BOOL *stop) {
			NSArray *keyValue = [pair componentsSeparatedByString:@"="];
			if (keyValue.count == 2) {
				[query setObject:keyValue[1] forKey:keyValue[0]];
			}
		}];
	}
	
	CMResource *resource = [CMResource withURL:[resourceURL absoluteString]];
	resource.query = query;
	
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
		[self.headersInternal setObject:value forKey:key];
	} else {
		[self.headersInternal removeObjectForKey:key];
	}
}

- (id) valueForHeaderField:(NSString *)key {
	return [self.headers objectForKey:key];
}

- (void) setValue:(id)value forQueryKey:(NSString *)key {
	if (value) {
		[self.queryInternal setObject:value forKey:key];
	} else {
		[self.queryInternal removeObjectForKey:key];
	}
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

- (CMRequest *) requestForIdentifier:(id)identifier {
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	CMRequest *request = [[self.requestsInternal objectsPassingTest:^BOOL(CMRequest *obj, BOOL *stop) {
		return [obj.identifier isEqual:identifier];
	}] anyObject];
	dispatch_semaphore_signal(_requests_semaphore);
	return request;
}

- (void) cancelRequests {
	[self cancelRequestsWithBlock:nil];
}

- (void) cancelRequestsWithBlock:(void (^)(void))block {
	dispatch_queue_t request_cancel_queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
	
	dispatch_async(request_cancel_queue, ^{
		dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
		
		for (CMRequest *request in self.requestsInternal) {
			[request cancel];
		}
		
		dispatch_semaphore_signal(_requests_semaphore);
		
		if (block) {
			dispatch_async(dispatch_get_main_queue(), block);
		}
	});
}

- (void) cancelRequestForIdentifier:(id)identifier {
	CMRequest *request = [self requestForIdentifier:identifier];
	if (request) {
		[request cancel];
	}
	else {
		RCLog(@"Tried to cancel a non-existent request: %@",identifier);
	}
}


// ========================================================================== //

#pragma mark - HTTP Requests


#pragma mark -GET



- (CMResponse *) get {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET];
	return [self runBlockingRequest:request];
}

- (id) getWithCompletionBlock:(CMCompletionBlock)completionBlock {
	return [self getWithProgressBlock:nil completionBlock:completionBlock];
}

- (id) getWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET];
	request.didReceiveDataBlock = progressBlock;
	return [self launchRequest:request withCompletionBlock:completionBlock];
}

- (CMResponse *) getWithQuery:(NSDictionary *)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET query:query];
	return [self runBlockingRequest:request];
}

- (id) getWithQuery:(NSDictionary *)query completionBlock:(CMCompletionBlock)completionBlock {
	return [self getWithQuery:query progressBlock:nil completionBlock:completionBlock];
}

- (id) getWithQuery:(NSDictionary *)query progressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET query:query];
	request.didReceiveDataBlock = progressBlock;
	return [self launchRequest:request withCompletionBlock:completionBlock];
}

#pragma mark -HEAD



- (CMResponse *) head {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD];
	return [self runBlockingRequest:request];
}

- (id) headWithCompletionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD];
	return [self launchRequest:request withCompletionBlock:completionBlock];
}

- (CMResponse *) headWithQuery:(NSDictionary *)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD query:query];
	return [self runBlockingRequest:request];
}

- (id) headWithQuery:(NSDictionary *)query completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD query:query];
	return [self launchRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -DELETE


- (CMResponse *) delete {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodDELETE];
	return [self runBlockingRequest:request];
}

- (id) deleteWithCompletionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodDELETE];
	return [self launchRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -POST


- (CMResponse *) post:(id)payload {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPOST];
	request.payload = payload;
	return [self runBlockingRequest:request];
}

- (id) post:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock {
	return [self post:payload withProgressBlock:nil completionBlock:completionBlock];
}

- (id) post:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPOST];
	request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	return [self launchRequest:request withCompletionBlock:completionBlock];
}


#pragma mark -PUT


- (CMResponse *) put:(id)payload {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPUT];
	request.payload = payload;
	return [self runBlockingRequest:request];
}

- (id) put:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock {
	return [self put:payload withProgressBlock:nil completionBlock:completionBlock];
}

- (id) put:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPUT];
	request.payload = payload;
	request.didReceiveDataBlock = progressBlock;
	return [self launchRequest:request withCompletionBlock:completionBlock];
}



#pragma mark -Files


- (id) downloadWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest<CMDownloadRequest> *request = [self downloadRequestWithQuery:nil];
	request.didReceiveDataBlock = progressBlock;
	return [self launchRequest:request withCompletionBlock:completionBlock];
}

- (id) downloadInChunksWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMChunkedDownloadRequest *request = [self chunkedDownloadRequestWithQuery:nil];
	request.didReceiveDataBlock = progressBlock;
	return [self launchRequest:request withCompletionBlock:completionBlock];
}

- (id) resumeOrBeginDownloadWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest<CMDownloadRequest> *request = [self downloadRequestWithQuery:nil];
	request.didReceiveDataBlock = progressBlock;
	request.shouldResume = YES;
	return [self launchRequest:request withCompletionBlock:completionBlock];
}

- (id) downloadRange:(CMContentRange)range progressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest<CMDownloadRequest> *request = [self downloadRequestWithQuery:nil];
	request.didReceiveDataBlock = progressBlock;
	request.range = range;
	return [self launchRequest:request withCompletionBlock:completionBlock];
}

- (id) uploadFile:(NSURL *)fileURL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMRequest *request = [self uploadRequestWithFileURL:fileURL query:nil];
	request.didSendDataBlock = progressBlock;
	return [self launchRequest:request withCompletionBlock:completionBlock];
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

- (CMChunkedDownloadRequest *) chunkedDownloadRequestWithQuery:query {
	NSMutableURLRequest *URLRequest = [self URLRequestForHTTPMethod:kCumulusHTTPMethodHEAD query:query];
	CMChunkedDownloadRequest *request = [[CMChunkedDownloadRequest alloc] initWithURLRequest:URLRequest];
	[request setCachesDir:self.cachesDir];
	request.maxConcurrentChunks = self.maxConcurrentChunks;
	request.chunkSize = self.chunkSize;
	request.readBufferLength = self.readBufferLength;
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
			[self.headersInternal setObject:@"application/json" forKey:kCumulusHTTPHeaderContentType];
			[self.headersInternal setObject:@"application/json" forKey:kCumulusHTTPHeaderAccept];
			break;
		case CMContentTypeXML:
			[self.headersInternal setObject:@"application/xml" forKey:kCumulusHTTPHeaderContentType];
			[self.headersInternal setObject:@"application/xml" forKey:kCumulusHTTPHeaderAccept];
			break;
		case CMContentTypeHTML:
			[self.headersInternal setObject:@"text/html" forKey:kCumulusHTTPHeaderContentType];
			[self.headersInternal setObject:@"text/html" forKey:kCumulusHTTPHeaderAccept];
			break;
		case CMContentTypeText:
			[self.headersInternal setObject:@"text/plain" forKey:kCumulusHTTPHeaderContentType];
			[self.headersInternal setObject:@"text/plain" forKey:kCumulusHTTPHeaderAccept];
			break;
		case CMContentTypePNG:
			[self.headersInternal setObject:@"image/png" forKey:kCumulusHTTPHeaderContentType];
			[self.headersInternal setObject:@"image/png" forKey:kCumulusHTTPHeaderAccept];
			break;
		default:
			break;
	}
}

- (NSMutableURLRequest *) URLRequestForHTTPMethod:(NSString *)method query:(NSDictionary *)query {	
	NSMutableDictionary *requestQuery = [NSMutableDictionary dictionaryWithDictionary:self.mergedQuery];
	[requestQuery addEntriesFromDictionary:query];
	
	
	NSURL *requestURL;

	if ([requestQuery count] > 0) {
		NSString *requestQueryString = [requestQuery toQueryString];
		requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@?%@",self.URL,requestQueryString]];
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
	
	NSUUID *UUID = [NSUUID new];
	request.identifier = [UUID UUIDString];
}

- (NSString *) requestSignatureForHTTPMethod:(NSString *)method {
	return [NSString stringWithFormat:@"%@ %@",method,_URL];
}




// ========================================================================== //

#pragma mark - Request Runners



- (CMResponse *) runBlockingRequest:(CMRequest *)request {
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	__block CMResponse *localResponse = nil;
	
	CMCompletionBlock completionBlock = ^(CMResponse *response){
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	};
	
	CMAbortBlock abortBlock = ^(CMRequest *request) {
		dispatch_semaphore_signal(request_sema);
	};
	
	[self launchRequest:request withCompletionBlock:completionBlock abortBlock:abortBlock];
	
	if ([NSThread isMainThread]) {
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		} while (dispatch_semaphore_wait(request_sema, 0.01) != 0);
	}
	else {
		dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	}
	dispatch_release(request_sema);
	return localResponse;
}

- (id) launchRequest:(CMRequest *)request withCompletionBlock:(CMCompletionBlock)completionBlock {
	return [self launchRequest:request withCompletionBlock:completionBlock abortBlock:NULL];
}

- (id) launchRequest:(CMRequest *)request withCompletionBlock:(CMCompletionBlock)completionBlock abortBlock:(CMAbortBlock)abortBlock {
	
	id context = (__bridge id)(dispatch_get_specific(&kCMResourceContextKey));
	if (context) {
		RCLog(@"Dispatching request with context: %@",context);
	}
	
	
	dispatch_semaphore_t launch_semaphore = dispatch_semaphore_create(0);
	
	CMPreflightBlock preflightBlock = self.preflightBlock;
	if (preflightBlock) {
		void(^dispatchPreflightBlock)(void) = ^{
			BOOL success = preflightBlock(request);
			if(success) {
				[self dispatchRequest:request withCompletionBlock:completionBlock launchSemaphore:launch_semaphore context:context];
			}
			else {
				[request abortWithBlock:abortBlock];
				dispatch_semaphore_signal(launch_semaphore);
			}
		};
		
		if ([NSThread isMainThread]) {
			dispatchPreflightBlock();
		}
		else {
			dispatch_async(dispatch_get_main_queue(), dispatchPreflightBlock);
		}
	}
	else {
		[self dispatchRequest:request withCompletionBlock:completionBlock launchSemaphore:launch_semaphore context:context];
	}
	dispatch_semaphore_wait(launch_semaphore, DISPATCH_TIME_FOREVER);
	dispatch_release(launch_semaphore);
	return request.identifier;
}

- (void) dispatchRequest:(CMRequest *)request withCompletionBlock:(CMCompletionBlock)completionBlock launchSemaphore:(dispatch_semaphore_t)launch_semaphore context:(id)context {
	[self addRequest:request context:context];
	dispatch_semaphore_signal(launch_semaphore);
	
	__weak id weakContext = context;
	dispatch_queue_t request_queue = [CMResource dispatchQueue];
	dispatch_async(request_queue, ^{
		[request startWithCompletionBlock:^(CMResponse *response){http://www.backblaze.com/pics/how-online-backup-works.jpg
			if (self.automaticallyTracksLastModified && response.lastModified) {
				self.lastModified = response.lastModified;
			}
			if (completionBlock) {
				completionBlock(response);
			}
			dispatch_async(request_queue, ^{
				[self removeResponse:response context:weakContext];
			});
		}];
	});
}

- (void) addRequest:(CMRequest *)request context:(id)context {
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	[self.requestsInternal addObject:request];
	if ([context isKindOfClass:[CMResourceContextGroup class]]) {
		[context enterWithRequest:request];
	}
	else if ([context isKindOfClass:[CMResourceContextScope class]]) {
		CMResourceContextScope *scope = context;
		request.scope = scope;
		__weak CMRequest *weakRequest = request;
		scope.shutdownHook = ^{
			if (weakRequest) {
				[weakRequest cancel];
			}
		};
	}
	dispatch_semaphore_signal(_requests_semaphore);
}

- (void) removeResponse:(CMResponse *)response context:(id)context {
	CMRequest *request = response.request;
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	if (request) {
		[self.requestsInternal removeObject:request];
	}
	if (context && [context isKindOfClass:[CMResourceContextGroup class]]) {
		[context leaveWithResponse:response];
	}
	dispatch_semaphore_signal(_requests_semaphore);
}


@end
