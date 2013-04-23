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

/// All headers from all ancestors and the receiver merged into one dictionary
@property (nonatomic, readonly) NSMutableDictionary *mergedHeaders;
/// All #authProviders from all ancestors and the receiver merged into one array
@property (nonatomic, readonly) NSMutableArray *mergedAuthProviders;
/// The internal property for directly accessing request objects
@property (nonatomic, strong) NSMutableSet *requestsInternal;
@property (nonatomic, strong) NSMutableDictionary *fixtures;


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
	NSMutableSet *requests = [NSMutableSet setWithSet:self.requestsInternal];
	dispatch_semaphore_signal(_requests_semaphore);
	return requests;
}


// Private

@synthesize requestsInternal=_requestsInternal;
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
		_requestsInternal = [NSMutableSet new];
		
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

- (CMResponse *) getWithQuery:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodGET query:query];
    return [self runBlockingRequest:request];	
}

- (id) getWithCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	return [self getWithProgressBlock:nil completionBlock:completionBlock query:query];
}

- (id) getWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock query:(id)query {
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

- (CMResponse *) headWithQuery:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodHEAD query:query];
    return [self runBlockingRequest:request];	
}

- (id) headWithCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
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

- (CMResponse *) deleteWithQuery:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodDELETE query:query];
    return [self runBlockingRequest:request];	
}

- (id) deleteWithCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodDELETE query:query];
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

- (CMResponse *) post:(id)payload withQuery:(id)query {
    CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPOST query:query];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (id) post:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	return [self post:payload withProgressBlock:nil completionBlock:completionBlock query:query];
}

- (id) post:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPOST query:query];
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

- (CMResponse *) put:(id)payload withQuery:(id)query {
    CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPUT query:query];
    request.payload = payload;
    return [self runBlockingRequest:request];	
}

- (id) put:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	return [self post:payload withProgressBlock:nil completionBlock:completionBlock query:query];
}

- (id) put:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock query:(id)query {
	CMRequest *request = [self requestForHTTPMethod:kCumulusHTTPMethodPUT query:query];
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

	if ([NSThread currentThread] == [NSThread mainThread]) {
		do {
			[[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate dateWithTimeIntervalSinceNow:.01]];
		} while (dispatch_semaphore_wait(request_sema, 0.01) != 0);
//		while() {
//		}
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

	CMResourceGroup *resourceGroup = (__bridge CMResourceGroup *)(dispatch_get_context(dispatch_get_current_queue()));
	if (resourceGroup) {
		RCLog(@"Dispatching request to resource group: %@",resourceGroup);
	}

	dispatch_semaphore_t launch_sema = dispatch_semaphore_create(0);
	
	CMPreflightBlock preflightBlock = self.preflightBlock;
	if (preflightBlock) {
		dispatch_async(dispatch_get_main_queue(), ^{
			BOOL success = preflightBlock(request);
			if(success) {
				[self dispatchRequest:request withCompletionBlock:completionBlock launchSemaphore:launch_sema resourceGroup:resourceGroup];
			}
			else {
				[request abortWithBlock:abortBlock];
				dispatch_semaphore_signal(launch_sema);
			}
		});
	}
	else {
		[self dispatchRequest:request withCompletionBlock:completionBlock launchSemaphore:launch_sema resourceGroup:resourceGroup];
	}
	
	dispatch_semaphore_wait(launch_sema, DISPATCH_TIME_FOREVER);
	dispatch_release(launch_sema);
	return request.identifier;
}

- (void) dispatchRequest:(CMRequest *)request withCompletionBlock:(CMCompletionBlock)completionBlock launchSemaphore:(dispatch_semaphore_t)launch_semaphore resourceGroup:(CMResourceGroup *)resourceGroup {
	dispatch_queue_t request_queue = [CMResource dispatchQueue];
	dispatch_async(request_queue, ^{
		[self addRequest:request resourceGroup:resourceGroup];
		[request startWithCompletionBlock:^(CMResponse *response){
			if (completionBlock) {
				completionBlock(response);
			}
			dispatch_async(request_queue, ^{
				[self removeResponse:response resourceGroup:resourceGroup];
			});
		}];
		dispatch_semaphore_signal(launch_semaphore);
	});
}

- (void) addRequest:(CMRequest *)request resourceGroup:(CMResourceGroup *)resourceGroup {
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	[self.requestsInternal addObject:request];
	if (resourceGroup) {
		[resourceGroup enter];
	}
	dispatch_semaphore_signal(_requests_semaphore);
}

- (void) removeResponse:(CMResponse *)response resourceGroup:(CMResourceGroup *)resourceGroup {
	CMRequest *request = response.request;
	dispatch_semaphore_wait(_requests_semaphore, DISPATCH_TIME_FOREVER);
	[self.requestsInternal removeObject:request];
	if (resourceGroup) {
		[resourceGroup leaveWithResponse:response];
	}
	dispatch_semaphore_signal(_requests_semaphore);
}


@end
