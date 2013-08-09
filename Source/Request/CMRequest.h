//
//  CMRequest.h
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
#import "CMCoder.h"
#import "CMProgressInfo.h"


@class CMResponse;
@class CMRequest;

/** CMRequest wraps an NSURLRequest and executes it using an NSURLConnection, running blocks along various points in the lifecycle and serializing/deserialzing the results using various implementations of <CMCoder>. The end result of each request is stored in #result and reflects any transformations of the raw response data that have occurred. If there has been an error, this is reflected in #error. However, to interrogate the state of the request after completion, it is generally easier to use the CMResponse object stored in #response, as this provides a number of conveniences to make inspection easier.
 *
 *  CMRequest is meant as a lovel-level class. Generally you will want to use CMResource rather than CMRequest directly unless you need more control than CMResource allows.
 *
 *  ### Lifecycle
 *
 *  There are five blocks that are run, if defined, at various points in a request's lifecycle:
 *
 *  - didSendData, which is passed a progress dictionary
 *  - didreceiveData, which is also passed a progress dictionary
 *  - postprocess, which is passed the existing result as an argument and whose return value then replaces the request's result in turn
 *  - completion, which runs when a request completes, regardless of success or failure
 *  - abort, which runs when a request is canceled before its url connection is started
 *
 *  ### Authentication
 *
 *  Each request can have a collection of authentication providers, which implement <CMAuthProvider> and can do any kind of authentication that is supported by the protocol. Several common auth providers are included with Cumulus.
 *
 *  ### Encoding/Decoding
 *
 *  Payloads and results are serialized/deserialized automatically if a coder for the particular object type or content-type can be found. Custom coders can be added to the system by simply implementing <CMCoder> and registering the new coder with the system by calling CMCoder+registerCoder:objectType:mimeTypes:. Only one coder per object or content-type is allowed, with the last one added winning if there are more than one. It is also possible to simply set an instance of <CMCoder> on any instance of a request as either an encoder or decoder, though if the coder is registered with the system properly this generally shouldn't be necessary.
 */
@interface CMRequest : NSObject <NSURLConnectionDelegate,NSURLConnectionDataDelegate>  


/** Returns the total number of requests running via Cumulus. 
 *  The value returned by this method is global; it accounts for all requests launched via either tne static Cumulus interface or through instances of CMResource.
 */
+ (NSUInteger) requestCount;

// ========================================================================== //
/** @name Request State */
// ========================================================================== //

@property (readonly, getter = isStarted) BOOL started;
@property (readonly, getter = isFinished) BOOL finished;
@property (readonly, getter = wasCanceled) BOOL canceled;
@property (readonly, strong) NSDate *startedAt;
@property (readonly, strong) NSDate *endedAt;
@property (nonatomic, readonly) NSTimeInterval elapsed;
@property (nonatomic, readonly) NSUInteger bytesPerSecond;


// ========================================================================== //
/** @name Configuration */
// ========================================================================== //


/** The URL associated with the URL request the receiver was created with. */
@property (nonatomic, readonly) NSURL *URL;

/** An arbitrary identifier assigned to the receiver, typically by a resource dispatching many requests. */
@property (nonatomic, strong) id identifier;

/** Values added to this collection before the request is constructed (prior to calling [CMRequest start]) will become a part of the underlying HTTP request's (#URLRequest) headers. Once the HTTP request has started, the return value of this property reflects the current request's actual headers, which may have mutated in the process of responding to lifecycle events.
 *  @note Adding values to this collection after calling start has no effect.
 *  @returns The headers associated with URLRequest at a given point in time.
 */
@property (nonatomic, readonly, strong) NSMutableDictionary *headers;

/// Convenience that returns the Accept header from headers if there is one
@property (nonatomic, readonly) NSString *acceptHeader;

/// Convenience that returns the Content-Type header from headers if there is one
@property (nonatomic, readonly) NSString *contentTypeHeader;

/// If this is non-zero and a response is not received by the time this interval has elapsed, the request is canceled. The underlying URL request also has this value set, which means that (except in the case of POST request which the system overrides) the request will quit if it has been idle for this length of time.
@property (nonatomic) NSTimeInterval timeout;

/// @see NSURLRequest#cachePolicy
@property (nonatomic) NSURLRequestCachePolicy cachePolicy;

/// Given the chance to authorize a request and respond to auth challenges, in order
@property (nonatomic, readonly, strong) NSMutableArray *authProviders;

/// Auth challenges will be canceled if they exceed this value. Defaults to 1.
@property (nonatomic) NSInteger maxAuthRetries;

/// When this is set, #payloadEncoder is used to turn the payload into data for the HTTPBody.
@property (nonatomic, strong) id payload;

/// The query string as a dictionary
@property (nonatomic, readonly) NSDictionary *queryDictionary;

/** When set, the request will include the appropriate 'Range' and 'if-Range' along with 'ETag' and/or 'Last-Modified' headers to request a range of the resource. */
@property (nonatomic) CMContentRange range;



// ========================================================================== //
/** @name Lifecycle  */
// ========================================================================== //

/** When this property is set, the receiver will observe teh value, and if it becomes zeroed out, the receiver cancels itself. */
@property (nonatomic,weak) id scope;

/** This block gets called every time the connection:didSendBodyData:totalBytesWritten:totalBytesExpectedToWrite: delegate method is invoked. */
@property (copy) CMProgressBlock didSendDataBlock;
/** This block gets called every time connection:didReceiveData: delegate method is invoked. */
@property (copy) CMProgressBlock didReceiveDataBlock;
/** This block gets a chance to modify the value of #result before the response is passed to the completion block. */
@property (copy) CMPostProcessorBlock postProcessorBlock;
/** Runs when a request is aborted or when the receiver fails before starting to make the request. */
@property (copy) CMAbortBlock abortBlock;
/** Gets a chance to handle the value of #response when the entire request is complete. Should not raise an exception as a mechanism for controlling execution, since it won't be seen outside the block. */
@property (copy) CMCompletionBlock completionBlock;



// ========================================================================== //
/** @name Content Encoding/Decoding */
// ========================================================================== //


/** @returns either a manually set payloadEncoder or one that is created from inferences based on request headers.
 *  @see CMCoder for details about how this is created by inference.
 */
@property (nonatomic, strong) id<CMCoder> payloadEncoder;
/** @returns either a manually set responseDecoder or one that is created from inferences based on response headers.
 *  @see CMCoder for details about how this is created by inference.
 */
@property (nonatomic, strong) id<CMCoder> responseDecoder;



// ========================================================================== //
/** @name Request/Response Handling */
// ========================================================================== //


/** When called creates an NSMutableURLRequest from the URL request used in initWithURLRequest: and any headers set on the receiver. Cannot be set externally, but since it's mutable, can be manipulated to achieve various custom configurations as needed. */
@property (readonly, strong) NSMutableURLRequest *URLRequest;
@property (readonly, strong) NSHTTPURLResponse *URLResponse;
@property long long bodyContentLength;
@property long long sentContentLength;

/** The length of the content expected by the receiver, including ranges of content. 
 *  @note Returns NSURLResponseUnknownLength when the content length cannot be determined, which is typically the case for streamed files. 
 */
@property long long expectedContentLength;
@property long long receivedContentLength;

/** Stores any data returned in the body of the response. */
@property (readonly, strong) NSMutableData *data;
/** @returns a progress info object representing the current progress of receiving all the expected data. */
@property (readonly) CMProgressInfo *progressReceivedInfo;
/** @returns a progress info object representing the current progress of sending all of the local data. */
@property (readonly) CMProgressInfo *progressSentInfo;
/** A weak pointer to the response object (reponses own their requests). */
@property (readonly, weak) CMResponse *response;
/** The results of processing any response data with and instance of <CMCoder> and/or post-processing blocks are stored here. */
@property (readonly, strong) id result;
/** If the response data can be represented as a string, this property reflects the value. */
@property (readonly, strong) NSString *responseBody;
@property (strong) NSError *error;



// ========================================================================== //
/** @name Creating Requests */
// ========================================================================== //


- (id) initWithURLRequest:(NSURLRequest *)URLRequest;
//+ (id) startRequestWithURLRequest:(NSURLRequest*)aURLRequest queue:(NSOperationQueue *)queue completionBlock:(CMCompletionBlock)block;



// ========================================================================== //
/** @name Controlling Requests */
// ========================================================================== //

/** Passed to the internal NSURLConnection via setDelegateQueue. Controls how the connection's delegate messages are delivered. */
@property (nonatomic, strong) NSOperationQueue *connectionDelegateQueue;

/** Starts the NSURLRequest.
 *  @returns YES if the request was started, NO otherwise.
 */
- (BOOL) start;

/** Sets the receiver's completion block and starts the NSURLRequest.
 *  @returns YES if the request was started, NO otherwise (such as when start is called more than once or after the receiver has been canceled).
 */
- (BOOL) startWithCompletionBlock:(CMCompletionBlock)completionBlock;

/** Sets the receiver's connectionDelegateQueue and starts the NSURLRequest.
 *  @returns YES if the request was started, NO otherwise.
 */
- (BOOL) startOnQueue:(NSOperationQueue *)delegateQueue withCompletionBlock:(CMCompletionBlock)completionBlock;
   

/** Will cancel a connection if it has not finished. Creates the response object, sets the request to finished and runs #completionBlock if it was set. 
 *  @returns YES if the receiver was canceled, NO otherwise (such as when cancel is called more than once).
 */
- (BOOL) cancel;

/** Aborts a request if it has not been started, canceled or completed. Sets the request to finished but does not create a response object nor run #completionBlock. 
 *  @note If you want to stop a request that has already started, you must call cancel, which dispatches the completion block.
 *  @returns YES if the receiver was aborted, NO otherwise (such as when the receiver has already started).
 */
- (BOOL) abort;

/** Invokes #abort and dispatches the supplied block. 
 *  @returns YES if the receiver was aborted, NO otherwise (such as when the receiver has already started).
 *  @note if NO is returned the supplied block is not dispatched.
 */
- (BOOL) abortWithBlock:(CMAbortBlock)abortBlock;




// ========================================================================== //
/** @name Request Helpers */
// ========================================================================== //

- (NSString *) mimeTypeForFileAtPath:(NSString *)filePath;


@end
