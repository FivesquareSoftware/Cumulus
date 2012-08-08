//
//  RCRequest.h
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
#import "RCCoder.h"



@class RCResponse;
@class RCRequest;

/**
 * RCRequest wraps an NSURLRequest and executes it using and NSURLConnection, running blocks along various points in the lifecycle and serializing/deserialzing the results using various implementations of <RCCoder>. The end result of each request is stored in #result and reflects any transformations of the raw response data that have occurred. If there has been an error, this is reflected in #error. However, to interrogate the state of the request after completion, it is generally easier to use the RCResponse object stored in #response, as this provides a number of conveniences to make inspection easier.
 *
 * RCRequest is meant as a lovel-level class. Generally you will want to use RCResource directly unless you need more control than RCResource allows.
 *
 * = Lifecycle
 *
 * There are five blocks that are run, if defined, at various points in a request's lifecycle:
 *  - didSendData, which is passed a progress dictionary
 *  - didreceiveData, which is also passed a progress dictionary
 *  - postprocess, which sets the request's results to the return value of the block, which is passed the existing results as an argument
 *  - completion, which runs when a request completes, regardless of success or failure
 *  - abort, which runs when a request is canceled before its url connection is started
 *
 * = Authentication
 *
 * Each request can have a collection of authentication providers, which implement <RCAuthProvider> and can do any kind of authentication that is supported by the protocol. Several common auth providers are included with RESTClient.
 *
 * = Encoding/Decoding
 *
 * Payloads and results are serialized/deserialized automatically if a coder for the particular object type or content-type can be found. Custom coders can be added to the system by simply implementing <RCCoder> and registering the new coder with the system by calling RCCoder+registerCoder:objectType:mimeTypes:. Only one coder per object or content-type is allowed, with the last one added winning if there are more than one. It is also possible to simply set an instance of <RCCoder> on any instance of a request as either an encoder or decoder, though if the coder is registered with the system properly this generally shouldn't be necessary.
 */
@interface RCRequest : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate>  


/** @name Request State
 *  @{
 */

@property (readonly, getter = isStarted) BOOL started;
@property (readonly, getter = isFinished) BOOL finished;
@property (readonly, getter = wasCanceled) BOOL canceled;


/** @} */


/** @name Lifecycle Blocks
 *  @{
 */


/** This block gets called every time the connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite: delegate method is invoked. */
@property (copy) RCProgressBlock didSendDataBlock;
/** This block gets called every time connection:didReceiveData: delegate method is invoked. */
@property (copy) RCProgressBlock didReceiveDataBlock;
/** This block gets a chance to modify the value of #result before the response is passed to the completion block. */
@property (strong) RCPostProcessorBlock postProcessorBlock;
/** Runs when a request is aborted or when the receiver fails before starting to make the request. */
@property (copy) RCAbortBlock abortBlock;
/** Gets a chance to handle the value of #response when the entire request is complete. Should not raise an exception as a mechanism for controlling execution, since it won't be seen outside the block. */
@property (copy) RCCompletionBlock completionBlock;

/** @} */


/** @name Content Encoding/Decoding
 *  @{
 */


/** @returns either a manually set payloadEncoder or one that is created from inferences based on request headers. 
 *  @see RCCoder for details about how this is created by inference. 
 */
@property (nonatomic, strong) id<RCCoder> payloadEncoder;
/** @returns either a manually set responseDecoder or one that is created from inferences based on response headers.  
 *  @see RCCoder for details about how this is created by inference. 
 */
@property (nonatomic, strong) id<RCCoder> responseDecoder;

/** @} */


/** @name Configuration
 *  @{
 */


@property (nonatomic, readonly, strong) NSMutableDictionary *headers;
@property (nonatomic, readonly) NSString *acceptHeader; ///< Convenience that returns the Accept header from headers if there is one
@property (nonatomic, readonly) NSString *contentTypeHeader; ///< Convenience that returns the Content-Type header from headers if there is one
@property (nonatomic) NSTimeInterval timeout; ///< If this is non-zero and a response is not received by the time this interval has elapsed, the request is canceled.
@property (nonatomic) NSURLRequestCachePolicy cachePolicy; ///< @see NSURLRequest#cachePolicy
@property (nonatomic, readonly, strong) NSMutableArray *authProviders; ///< Given the chance to authorize a request and respond to auth challenges, in order
@property (nonatomic) NSInteger maxAuthRetries; ///< Auth challenges will be canceled if they exceed this value. Defaults to 1.

@property (nonatomic, strong) id payload; ///< If this is set, #payloadEncoder is used to turn the payload into data for the HTTPBody.


/** @} */


/** @name Execution Context
 *  @{
 */


/** Constructed dynamically from the URL request used in the contructor and any headers that exist in #headers. Cannot be set externally, but since it's mutable, can be manipulated to achieve various custom configurations as needed. */
@property (readonly, strong) NSMutableURLRequest *URLRequest;
@property (readonly, strong) NSHTTPURLResponse *URLResponse;
@property long long bodyContentLength;
@property long long sentContentLength;
@property long long expectedContentLength;
@property long long receivedContentLength;
/** Stores any data returned in the body of the response. */
@property (readonly, strong) NSMutableData *data;
/** The results of processing any response data with and instance of <RCCoder> and/or post-processing blocks are stored here. */
@property (readonly, strong) id result;
/** If the response data can be represented as a string, this property reflects the value. */
@property (readonly, strong) NSString *responseBody;
@property (strong) NSError *error;


/** @} */


/** @name Creating Requests
 *  @{
 */


- (id) initWithURLRequest:(NSURLRequest *)URLRequest;
//+ (id) startRequestWithURLRequest:(NSURLRequest*)aURLRequest queue:(NSOperationQueue *)queue completionBlock:(RCCompletionBlock)block;

/** @} */


/** @name Controlling Requests
 *  @{
 */

- (void) start;
- (void) startWithCompletionBlock:(RCCompletionBlock)completionBlock;
   

/** Will cancel a connection if it has not finished. Creates the response object, sets the request to finished and runs #completionBlock if it was set. */
- (void) cancel;

/** Aborts a request if it has not been started, canceled or completed. Sets the request to finished but does not create a response object nor run #completionBlock. */
- (void) abort;
- (void) abortWithBlock:(RCAbortBlock)abortBlock;


/** @} */


/** @name Request Helpers
 *  @{
 */

- (NSString *) mimeTypeForFileAtPath:(NSString *)filePath;

/** @} */


@end
