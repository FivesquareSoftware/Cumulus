//
//  Cumulus.h
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

/*
 * Enlightenment is like the moon reflected on the water. The moon does not get 
 * wet, nor is the water broken. Although its light is wide and great, the moon 
 * is reflected even in a puddle an inch wide. The whole moon and the entire sky 
 * are reflected in dewdrops on the grass, or even in one drop of water.
 *
 * Enlightenment does not divide you, just as the moon does not break the water. 
 * You cannot hinder enlightenment, just as a drop of water does not hinder the 
 * moon in the sky.
 * 
 * The depth of the drop is the height of the moon. Each reflection, however long 
 * or short its duration, manifests the vastness of the dewdrop, and realizes the 
 * limitlessness of the moonlight in the sky.
 * 
 *   -Dogen
 */


#import <Foundation/Foundation.h>

#if TARGET_OS_IPHONE
	#import <MobileCoreServices/MobileCoreServices.h>
#else
	#import <CoreServices/CoreServices.h>
#endif

#ifndef NS_BLOCK_ASSERTIONS
	#define NS_BLOCK_ASSERTIONS 0
#endif


#import "CMTypes.h"
#import "CMConstants.h"

#import "CMResourceContext.h"
#import "CMResource.h"
#import "CMRequest.h"
#import "CMDownloadRequest.h"
#import "CMChunkedDownloadRequest.h"
#import "CMUploadRequest.h"
#import "CMResponse.h"
#import "CMCoder.h"
#import "CMDownloadInfo.h"
#import "NSObject+Cumulus.h"


/** Cumulus.h is the main header for the Cumulus HTTP client—include it in your project to use Cumulus. The Cumulus class interface provides global configuration options, some static methods for making one-off or non-conforming requests, and fixture configuration and usage. In general, however, the main point of usage for the Cumulus HTTP client is CMResource, which allows for simple configuration and resusability of response processing across any number of requests.
 *
 *  ### Static Request Interface
 *
 *  Static request methods simply create anonymous resources under the hood, delegating the request to that resource. They are useful if you have a non-conforming service, or you want to use Cumulus a a general purpose HTTP client (for which it is well suited).
 *
 *  - In all cases URL may be an NSURL or an NSString representing an URL
 *  - In general, the equivalent methods in CMResource should be preferred if you plan on using these more than once.
 *
 */
@interface Cumulus : NSObject {
	
}


/** Log a message to the console. 
 *
 * Whether or not this method actually logs a message is controlled by setting CumulusLoggingOn in the environment (Generally by setting it in the environment of the Run phase of your target's scheme). Setting it to YES|true|1 turns logging on, setting it to NO|false|0 to turns logging off (the default is off).
 * @warning If you are writing code for Cumulus or a Cumulus extension, you shouldn't be calling this method. Instead, call the CMLog() macro, which includes compile time checks to make sure logging doesn't make it into a release build of your application or framework.
*/
+ (void) log:(NSString *)format, ...;


// ========================================================================== //
/** @name Configuration for Static Requests */
// ========================================================================== //


/** The global default cache directory used by download requests and some state saving mechanisms. Can be overridden by individual requests. */
+ (NSString *) cachesDir;

/** @see [CMResource timeout] */
+ (NSTimeInterval) timeout;
/** @see [CMResource setTimeout:] */
+ (void) setTimeout:(NSTimeInterval)timeout;

/** @see [CMResource authProviders] */
+ (NSMutableArray *)authProviders;
/** @see [CMResource setAuthProviders:] */
+ (void) setAuthProviders:(NSMutableArray *)authProviders;

/** @see [CMResource headers] */
+ (NSMutableDictionary *) headers;
/** @see [CMResource setHeaders:] */
+ (void) setHeaders:(NSMutableDictionary *)headers;

/** Sets the maximum number of asynchronous requests that can be launched via the static interface in this Class. 
 *  @see [CMResource maxConcurrentRequests] for more information on what various values mean.
 */
+ (NSUInteger) maxConcurrentRequests;
/** @see [CMResource setMaxConcurrentRequests:] */
+ (void) setMaxConcurrentRequests:(NSUInteger)maxConcurrentRequests;


// ========================================================================== //
/** @name Global Fixture Configuration */
// ========================================================================== //


/** Returns the current fixture data, which is a dictionary whose keys are request signatures (<Method URL>, e.g."GET http:///wwww.foo.com") and values are any valid payload object type. */
+ (NSMutableDictionary *) fixtures;

/** Loads a set of fake data to return for a request. The data should have request signatures (<Method URL>, e.g."GET http:///wwww.foo.com") as keys and any valid payload object type as a value. */
+ (void) setFixtures:(NSMutableDictionary *)fixtures;

/** Loads fixtures from a plist and appends them to the currrent fixtures, overwriting any entries for the same request signature. */
+ (void) loadFixturesNamed:(NSString *)plistName;

/** Will add the supplied fixture to any existing fixtures, overwriting an existing entry for the same request signature. */
+ (void) addFixture:(id)fixture forRequestSignature:(NSString *)requestSignature;

/** Whether or not fixture data will be returned for requests. */
+ (BOOL) usingFixtures;
+ (void) useFixtures:(BOOL)useFixtures;


// ========================================================================== //
/** @name Static Requests */
// ========================================================================== //


/** @see [CMResource get]. */
+ (CMResponse *) get:(id)URL;

/** @see [CMResource getWithCompletionBlock:]. */
+ (id) get:(id)URL withCompletionBlock:(CMCompletionBlock)completionBlock;

/** @see [CMResource getWithProgressBlock:completionBlock:]. */
+ (id) get:(id)URL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;


/** @see [CMResource head]. */
+ (CMResponse *) head:(id)URL;

/** @see [CMResource deleteWithCompletionBlock:]. */
+ (id) head:(id)URL withCompletionBlock:(CMCompletionBlock)completionBlock;


/** @see [CMResource delete]. */
+ (CMResponse *) delete:(id)URL;

/** @see [CMResource deleteWithCompletionBlock:]. */
+ (id) delete:(id)URL withCompletionBlock:(CMCompletionBlock)completionBlock;


/** @see [CMResource post:]. */
+ (CMResponse *) post:(id)URL payload:(id)payload;

/** @see [CMResource post:completionBlock:]. */
+ (id) post:(id)URL payload:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock;

/** @see [CMResource post:progressBlock:completionBlock:]. */
+ (id) post:(id)URL payload:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;


/** @see [CMResource put:]. */
+ (CMResponse *) put:(id)URL payload:(id)payload;

/** @see [CMResource put:completionBlock:]. */
+ (id) put:(id)URL payload:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock;

/** @see [CMResource put:progressBlock:completionBlock:]. */
+ (id) put:(id)URL payload:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;


/** @see [CMResource downloadWithProgressBlock:completionBlock:]. */
+ (id) download:(id)URL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

/** @see [CMResource downloadInChunksWithProgressBlock:completionBlock:]. */
+ (id) downloadInChunks:(id)URL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

/** @see [CMResource resumeOrBeginDownloadWithProgressBlock:completionBlock:]. */
+ (id) resumeOrBeginDownload:(id)URL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

/** @see [CMResource downloadRange:progressBlock::completionBlock:]. */
+ (id) download:(id)URL range:(CMContentRange)range progressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;

/** @see [CMResource uploadFile:withProgressBlock:completionBlock:]. */
+ (id) uploadFile:(NSURL *)fileURL to:(id)URL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock;


@end


