//
//  RCResource.h
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

#import <Foundation/Foundation.h>

#import "RCTypes.h"
#import "RCAuthProvider.h"


@class RCResponse;

/**
 * @mainpage
 * RCResource is the primary public interface for RESTKit, and each instance is meant to reflect an actual resource residing on the WWW, generally accessed via a REST web service. 
 *
 * Configuration
 *
 * Child resources can be constructed from parents, and will inherit all the configuration information of their ancestors. Their URLs are constructed as sub-URLs to their parents, and they retain their parents, to allow dynamic lookup of an ancestor's configuration information. With the exception of headers, configuration is an either/or prospect—it comes from only one resource in the chain, whether that is the receiver or one of the ancestors. Headers, being a mutable dictionary are merged down the whole tree.
 *
 * Lifecycle
 *
 * A resource has a lifecycle that is defined by the blocks you can run at various points in the execution of a request for the resource. These points are:
 *  - preflight, which can abort a request
 *  - progress, which can be either up or down depending on the type of request
 *  - postprocess, which can perform transformations and other work based on the results of the request
 *  - completion, which runs when a request completes, regardless of success or failure
 *  The posprocess block is unique because it runs on the high-priority concurrent global queue, whereas all the other blocks run on the main queue to allow UI code to safely run.
 *
 * Authentication
 *
 * Each resource can have an instance of an authentication provider, which implements <RCAuthProvider> and can do any kind of authentication that is supported by the protocol. A BASIC auth provider is included with RESTClient, and if username and password are set on a resource, an instance of this provider will be created on demand.
 *
 * Encoding/Decoding
 *
 * Payloads and results are serialized/deserialized automatically using instances of <RCCoder>.
 *  @see RCRequest for more information
 */
@interface RCResource : NSObject {
	
}

@property (nonatomic, readonly, strong) RCResource *parent;
@property (nonatomic, readonly, strong) NSString *relativePath;
@property (nonatomic, readonly, strong) NSURL *URL;

/** Headers can be set on each individual resource. However, while building a request for any resource, that resource's headers are merged with all of its ancestors headers, with any conflicts resolved in favor of the resource farthest down the inheriticance chain. */
@property (nonatomic, strong) NSMutableDictionary *headers;


@property (nonatomic) NSTimeInterval timeout; ///< If non-zero will cancel a request for the receiver if no response has been received by the time #timeout elapses

@property (nonatomic) NSURLRequestCachePolicy cachePolicy; ///< The cache policy to pass on to request. By default uses the default for NSURLRequest.

@property (nonatomic, strong) NSString *username; ///< If #authProviders is nil and #username and #password are not empty, an RCBasicAuthProvider is created on demand and added to #authProviders

@property (nonatomic, strong) NSString *password;

/** Auth providers, like headers, are set on each individual resource, but when a request is marshaled, a merged array from the receiver and all it's ancestors is used. Per resource, auth providers are given a chance to authorize requests in the order they were added. However child providers take precedence over ancestors' providers. */
@property (nonatomic, strong) NSMutableArray *authProviders;

@property (nonatomic, assign) RESTClientContentType contentType; ///< When set, will set 'Content-Type' and 'Accept' headers appropriately
@property (nonatomic, copy) RCPreflightBlock preflightBlock; ///< Runs before every request for the receiver, which is aborted if this block returns NO
@property (nonatomic, copy) RCPostProcessorBlock postProcessorBlock; ///< Runs on the result of a request for the receiver before any completion block is run. Runs on a non-main concurrent queue so is the ideal place to do any long-running processing of request results.
@property (readonly) NSMutableSet *requests; ///< The array of non-blocking RCRequest objects that are currently running. Since these requests may be running, the returned set only reflects a snapshot in time of the receiver's requests.
	


/** @name Creating Resources
 *  @{
 */


+ (id) withURL:(NSString *)URLString;

/** Constructs a base resource using an absolute URL string. 
 *  @returns nil if a URL cannot be constructed from the provided string.
 */
- (id) initWithURL:(NSString *)URLString;

/** Constructs a child resource from the receiver using the passed object. If
 *  the object is not a string, the value returned by calling #description on
 *  the object is used to contruct the resource URL.
 *
 *  Examples
 *
 *  [orders resource:[NSNumber numberWithInt:123]]
 *  [users resource:@"joe"]
 */
- (RCResource *) resource:(id)relativePathObject;

/** Allows a child resource to be constructed from a format string and arguments,
 *  using the same rules as NSString#stringWithFormat:.
 *
 *  Examples
 *
 *  [orders resourceWithFormat:@"users/%@/completed",@"joe"]
 */
- (RCResource *) resourceWithFormat:(NSString *)relativePathFormat,...;

/** @} */



/** @name Configuration
 *  @{
 */

/** Convenience method for setting a single header. If @param value is nil, will remove the header from the receiver. */
- (void) setValue:(id)value forHeaderField:(NSString *)key;

/** Adds authProvider to the end of the provider list. */
- (void) addAuthProvider:(id<RCAuthProvider>)authProvider;

/** @} */


/** @name Request Control
 *  @{
 */


/** Cancels all non-blocking requests started by the receiver. Blocking requests, once begun, cannot be canceled. 
 *  @note Returns immediately (Does not wait for requests to actually shut down)
 */
- (void) cancelRequests;
/** Calls #cancelRequests and executes block on the main queue when all calls are made
 *  @note When the block is called, there is no guarantee that the underlying NSURLConnection objects have fully canceled.
 */
- (void) cancelRequestsWithBlock:(void (^)(void))block; 

/** @} */



/** @name HTTP Methods
 *  @{
 */

- (RCResponse *) get;
- (void) getWithCompletionBlock:(RCCompletionBlock)completionBlock;
- (void) getWithProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;

- (RCResponse *) head;
- (void) headWithCompletionBlock:(RCCompletionBlock)completionBlock;

- (RCResponse *) delete;
- (void) deleteWithCompletionBlock:(RCCompletionBlock)completionBlock;


- (RCResponse *) post:(id)payload;
- (void) post:(id)payload completionBlock:(RCCompletionBlock)completionBlock;
- (void) post:(id)payload progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;

- (RCResponse *) put:(id)payload;
- (void) put:(id)payload completionBlock:(RCCompletionBlock)completionBlock;
- (void) put:(id)payload progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;


/** @} */


/** @name Handling Files
 *  @{
 */


/** Downloads the data represented by the receiver directly to disk instead of holding it in memory. When the request is complete #result holds a dictionary with information about the downloaded file, including a string representing the filename as it came from the server (if it was sent), and an NSURL pointing to the temporary location of the downloaded file. You should move it immediately to a location of your own choosing if you wish to preserve it. 
 *
 * The keys in the result dictionary include:
 *   - kRESTClientProgressInfoKeyURL
 *   - kRESTClientProgressInfoKeyTempFileURL
 *   - kRESTClientProgressInfoKeyFilename
 *   - kRESTClientProgressInfoKeyProgress
 */
- (void) downloadWithProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;

/** Allows for uploading files directly from disk rather than keeping them in memory, which is particularly useful for large files. The progress block is called each time a chunk of data is sent to the server. The content type sent to the server is inferred from the UTI of the file on disk and overrides any content type set on the receiver.
 *  
 *  @note Currently implemented using HTTP PUT rather than Multipart POST, which may not be supported by your server. 
 */
- (void) uploadFile:(NSURL *)fileURL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;


/** @} */



@end




