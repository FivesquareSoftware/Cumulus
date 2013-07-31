//
//  CMResource.h
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
 * DISCLAIMED. IN NO EVENT SHALL FIVESQUARE SOFTWARE BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

#import "CMTypes.h"
#import "CMAuthProvider.h"


@class CMResponse;
@class CMResourceContext;

/**
 * CMResource is the primary public interface for Cumulus, and each instance is meant to reflect an actual resource residing on the Internet, generally accessed via a REST web service. 
 *
 * ### Configuration
 *
 * Child resources can be constructed from parents, and will inherit all the configuration information of their ancestors. Their URLs are constructed as sub-URLs relative to their parents', and children retain their parents to allow dynamic lookup of an ancestor's configuration information at runtime. With the exception of headers and auth providers, configuration is an either/or prospect—it comes from only one resource in the chain, whether that is the receiver or one of the ancestors. Headers, being a mutable dictionary are merged down the whole tree.
 *
 * ### Lifecycle
 *
 * A resource has a lifecycle that is defined by the blocks you can run at various points in the execution of a request for the resource. These points are:
 *
 *  - preflight, which can abort a request
 *  - progress, which can be either up or down depending on the type of request
 *  - postprocess, which can perform transformations and other work based on the results of the request
 *  - completion, which runs when a request completes, regardless of success or failure
 *
 *  The posprocess block is unique because it runs on the high-priority concurrent global queue, whereas all the other blocks run on the main queue to allow UI code to safely run.
 *
 * ### Authentication
 *
 * Each resource can have an instance of an authentication provider, which implements <CMAuthProvider> and can do any kind of authentication that is supported by the protocol. A BASIC auth provider is included with Cumulus, and if username and password are set on a resource, an instance of this provider will be created on demand.
 *
 * ### Encoding/Decoding
 *
 * Payloads and results are serialized/deserialized automatically using instances of CMCoder. (See CMRequest for more information about how these are used)
 *
 * ### Query Strings
 *
 * To make it easier to reuse resource objects, you can set a query dictionary that will be converted to a query string for every request. You may also pass a dictionary to to one of the HTTP request methods, like getWithQuery: and it will be expanded for you to a query string (after being merged with any persistent query object) for just that request. 
 *
 *  The expansion of values in the dictionary is performed by [NSObject queryStringEncodingForKey:], and roughly follows these rules:
 *
 *    - NSString - \<key\>=\<value\>
 *    - NSArray - \<key\>[]=\<value1\>&\<key\>[]=\<value2\>&...
 *    - NSObject - \<key\>=\<[value description]\>
 *    - NSDictionary - dictionary values are transformed recursively using the above rules.
 *
 *  For example, the following message:
 *
 *		[resource getWithQuery:@{ @"foo" : @"bar" } ]
 *
 *  would yield a query string of ?foo=bar.
 *
 * ### Fixtures
 *
 *  To make it easier to get coding on your app, you can use fixtures to simulate a working set of web services. Fixtures are objects that are converted to NSData using an instance of CMCoder and then used in processing the response as if this was the data that the server sent back. Using them is pretty simple:
 *  
 *		CMResource *posts = [site resource:@"posts"];
 *		posts.fixture = [NSArray arrayWithObjects:postOne,postTwo,nil];
 *		[posts getWithCompletionBlock:^(CMResponse *response) {
 *			postsController.posts = response.result;
 *		}];
 *
 *  If fixture is nil, a resource will check [Cumulus fixtures] to see if a global fixture exists for its signature (URL+Method) and use that before determining that there is no fixture for the request. This makes central management of fixtures possible.
 *
 *  One of the gotchas with fixtures is that there is no Content-type header to rely on from the server when it comes time to decode the fixture data, so it needs to be inferred. If it is obvious from the kind of object that #fixture is, then that value is used. For example:
 *
 *    - NSString - results in text/plain, regardless of the type of data being represented
 *    - UIImage - results in image/jpg, image/png, image/gif, image/tiff, or nothing, depending on the actual image type
 *
 *  Since there is no way to be 100% sure what the intended content type is—obviously a string could actually represent an object in any number of text based data encodings—the only way to fully control how the fixture is decoded is to make sure you have set an 'Accept' header on your resource, either directly or by setting the #contentType. The value there will be used to select a decoder if it is set.
 *
 *  At this time, upload requests do not support fixtures.
 *
 */
@interface CMResource : NSObject {
	
}


// ========================================================================== //
/** @name Resource Information */
// ========================================================================== //


@property (nonatomic, readonly, strong) CMResource *parent;
@property (nonatomic, readonly, strong) NSString *relativePath;
@property (nonatomic, readonly, strong) NSURL *URL;
@property (nonatomic, readonly, strong) NSString *queryString;


// ========================================================================== //
/** @name Lifecycle Handlers */
// ========================================================================== //


/// Runs before every request for the receiver, which is aborted if this block returns NO
@property (nonatomic, copy) CMPreflightBlock preflightBlock;
/// Runs on the result of a request for the receiver before any completion block is run. Runs on a non-main concurrent queue so is the ideal place to do any long-running processing of request results.
@property (nonatomic, copy) CMPostProcessorBlock postProcessorBlock;



// ========================================================================== //
/** @name Creating Resources */
// ========================================================================== //


/** Convenience that creates a resource using initWithURL:. */
+ (id) withURL:(id)URL;

/** Constructs a base resource using an absolute URL string. 
 *  @param URL may be an NSURL or an NSString representing an URL
 *  @returns nil if a URL cannot be constructed from the provided string.
 */
- (id) initWithURL:(id)URL;

/** Constructs a child resource from the receiver using the passed object. If
 *  the object is not a string, the value returned by calling #description on
 *  the object is used to contruct the resource URL.
 *
 *  Examples
 *
 *  `[orders resource:[NSNumber numberWithInt:123]] => orders/123`
 *  `[users resource:@"joe"] => users/joe`
 *
 *  @param relativePathObject a string or any object that responds to #description
 */
- (CMResource *) resource:(id)relativePathObject;

/** Allows a child resource to be constructed from a format string and arguments,
 *  using the same rules as NSString#stringWithFormat:.
 *
 *  Examples
 *
 *  `[orders resourceWithFormat:@"users/%@/completed",@"joe"] => users/joe/completed`
 *
 *  @param relativePathFormat,... a format string and arguments
 */
- (CMResource *) resourceWithFormat:(NSString *)relativePathFormat,...;



// ========================================================================== //
// @name Configuration 
// ========================================================================== //


/** The headers specific to the receiver. 
 *  @note Headers can be set on each individual resource. However, while building a request for any resource, that resource's headers are merged with all of its ancestors' headers, with any conflicts resolved in favor of the resource farthest down the inheriticance chain. 
 */
@property (nonatomic, copy) NSDictionary *headers;

/** A query dictionary for the receiver that will be appended to every request as a query string. This attribute is best avoided avoided except to accomodate those circumstances where a non-conforming service requires data more correctly placed in headers (access keys, service versions, etc.) to be in a query string.
 *  @note When building a request, the receiver's query string will be merged with all of its ancestors' query strings with any conflicts resolved in favor of the resource farthest down the inheriticance chain. If one of the request methods that takes a query string was also used, the resulting dictionary will be merged again with the supplied query object.
 */
@property (nonatomic, copy) NSDictionary *query;


/** If non-zero will cancel a request for the receiver if no response has been received by the time #timeout elapses. The underlying URL request also has this value set for #timeoutInterval, which means that (except in the case of POST requests for which the system overrides #timeoutInterval) the request will quit if it has been idle for this length of time. */
@property (nonatomic) NSTimeInterval timeout;

/// The cache policy to pass on to request. By default uses the default for NSURLRequest.
@property (nonatomic) NSURLRequestCachePolicy cachePolicy;

/// The path to a subdirectory of NSCachesDirectory where direct to disk file downloads will be temporarily located. This directory is created on demand as needed. Defaults to Cumulus#cachesDir.
@property (nonatomic, strong) NSString *cachesDir;
/// The number of concurrent chunks allowed for chunked downloads. Default is 4.
@property NSUInteger maxConcurrentChunks;
/// The ideal chunk size when breaking a large download into parts. Default is 0, which means it is determined by maxConcurrentChunks.
@property (nonatomic) long long chunkSize;
/// The ideal read buffer when aggregating chunks. Default is 1K.
@property (nonatomic) NSUInteger readBufferLength;



/// If #authProviders is nil and #username and #password are not empty, an CMBasicAuthProvider is created on demand and added to #authProviders
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;

/** Auth providers, like headers, are set on each individual resource, but when a request is marshaled, a merged array from the receiver and all it's ancestors is used. Per resource, auth providers are given a chance to authorize requests in the order they were added. However child providers take precedence over ancestors' providers. */
@property (nonatomic, strong) NSMutableArray *authProviders;

/// When set, will set 'Content-Type' and 'Accept' headers appropriately
@property (nonatomic) CMContentType contentType;

/// When set will set the 'If-Modified-Since' header. If automaticallyTracksLastModified ise YES, then responses will automatically update this value.
@property (strong) NSDate *lastModified;
/// When set to YES, responses will automatically update lastModified, which will in turn cause future requests to send an 'If-Modified-Since' header. Defaults to NO.
@property (nonatomic) BOOL automaticallyTracksLastModified;


/** Convenience method for setting a single header.
 *  @param value A string or any object that responds to #description. May be nil.
 *  @param key The header field name.
 *  @note If value is nil, this will remove the header from the receive's headers. If value is not a string, it will have #description called on it before being set to the headers. (All headers are ultimately strings)
 */
- (void) setValue:(id)value forHeaderField:(NSString *)key;

/** Convenience method for returning the value of a single header. */
- (id) valueForHeaderField:(NSString *)key;

/** A convenience for setting query values and keys.
 *  @param value Any object that can be converted to a query string fragment using the logic in [NSObject queryEncodingWithKey:]. May be nil.
 *  @param key The query key name.
 *  @note If value is nil, this will remove the value from the receiver's query. The value will have queryEncodingWithKey: called on it when the query string is assembled for a request.
 */
- (void) setValue:(id)value forQueryKey:(NSString *)key;

/** Adds authProvider to the end of the provider list. */
- (void) addAuthProvider:(id<CMAuthProvider>)authProvider;



// ========================================================================== //
/** @name Fixtures */
// ========================================================================== //

/** Sets the fixture the receiver will use when issuing a request using the supplied HTTP method. */
- (void) setFixture:(id)value forHTTPMethod:(NSString *)method;

/** Returns the receiver's stored fixture for the supplied HTTP method if it exists or, if Cumulus#usingFixtures is YES, will attempt to return a global fixture for the request signature. */
- (id) fixtureForHTTPMethod:(NSString *)method;



// ========================================================================== //
/** @name Request Control */
// ========================================================================== //

/// The array of CMRequest objects that are currently running. Since these requests may quit at any point, the returned set only reflects a snapshot in time of the receiver's requests.
@property (readonly) NSMutableSet *requests;

/** A request from the running requests that has the supplied identifier. */
- (CMRequest *) requestForIdentifier:(id)identifier;

/** Cancels all requests started by the receiver. 
 *  @note Returns immediately (Does not wait for HTTP requests to actually shut down)
 */
- (void) cancelRequests;

/** Cancels all requests started by the receiver and executes block on the main queue when all calls are made.
 *  @note When the block is called there is no guarantee that the underlying NSURLConnection objects have fully canceled.
 */
- (void) cancelRequestsWithBlock:(void (^)(void))block;

/** Calls [CMRequest cancel] on a request with identifier matching the supplied identifier and waits for it to cancel before returning. 
 *  @note When this method returns there is no guarantee that the underlying NSURLConnection object associated with the request has fully canceled.
 */
- (void) cancelRequestForIdentifier:(id)identifier;



// ========================================================================== //
/** @name HTTP Methods */
// ========================================================================== //

// GET

- (CMResponse *) get;
- (id) getWithCompletionBlock:(CMCompletionBlock)completionBlock;
- (id) getWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

/** Make a request with additional query data used for just this request. Does not affect the receiver's #query dictionary.
 *  @note the supplied query object is merged with the receiver's (already) merged query if there is one.
 *  @param query A dictionary of keys and values. 
 */
- (CMResponse *) getWithQuery:(NSDictionary *)query;
/** @see getWithQuery: */
- (id) getWithQuery:(NSDictionary *)query completionBlock:(CMCompletionBlock)completionBlock;
/** @see getWithQuery: */
- (id) getWithQuery:(NSDictionary *)query progressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;



// HEAD

- (CMResponse *) head;
- (id) headWithCompletionBlock:(CMCompletionBlock)completionBlock;

/** Make a request with additional query data used for just this request. Does not affect the receiver's #query dictionary.
 *  @note the supplied query object is merged with the receiver's (already) merged query if there is one.
 *  @param query A dictionary of keys and values.
 */
- (CMResponse *) headWithQuery:(NSDictionary *)query;
/** @see headWithQuery: */
- (id) headWithQuery:(NSDictionary *)query completionBlock:(CMCompletionBlock)completionBlock;


// DELETE

- (CMResponse *) delete;
- (id) deleteWithCompletionBlock:(CMCompletionBlock)completionBlock;


// POST

- (CMResponse *) post:(id)payload;
- (id) post:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock;
- (id) post:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;



// PUT

- (CMResponse *) put:(id)payload;
- (id) put:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock;
- (id) put:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;



// ========================================================================== //
/** @name Handling Files */
// ========================================================================== //


/** Downloads the data represented by the receiver directly to disk instead of appending it in memory. When the request is complete [CMResponse result] holds an instance of CMProgressInfo with information about the downloaded file, including a string representing the filename as it came from the server (if it was sent), and an NSURL pointing to the temporary location of the downloaded file. You should move it immediately to a location of your own choosing if you wish to preserve it.
 */
- (id) downloadWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

- (id) downloadInChunksWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

/** Behaves like downloadWithProgressBlock:completionBlock: with the exception that it will resume the download if the temp download file already existes on disk.
 *  @see downloadWithProgressBlock:completionBlock:. 
 */
- (id) resumeOrBeginDownloadWithProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

/** Downloads a range of the resource directly to disk.
 *  @param range a CMContentRange with location and length representing the start and end (location+length) of range to be downloaded. 
 *  @see downloadWithProgressBlock:completionBlock:
 */
- (id) downloadRange:(CMContentRange)range progressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

/** Allows for uploading files directly from disk rather than keeping them in memory, which is particularly useful for large files. The progress block is called each time a chunk of data is sent to the server. The content type sent to the server is inferred from the UTI of the file on disk and overrides any content type set on the receiver.
 *  
 *  @note Currently implemented using HTTP PUT rather than Multipart POST, which may not be supported by your server. 
 *  @todo support multipart POST for uploads.
 */
- (id) uploadFile:(NSURL *)fileURL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;




@end




