//
//  RESTClient.h
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


#import "RCTypes.h"
#import "RCConstants.h"

#import "RCResourceGroup.h"
#import "RCResource.h"
#import "RCRequest.h"
#import "RCDownloadRequest.h"
#import "RCUploadRequest.h"
#import "RCProgressInfo.h"
#import "RCResponse.h"
#import "RCCoder.h"


/** 
 *  RESTClient is the main header for the RESTClient HTTP client and provides some static methods for making one-off or non-conforming requests. In general, however, the main point of usage for RESTClient is RCResource, which allows for simple configuration and resusability of requests.
 */
@interface RESTClient : NSObject {
	
}


+ (void) log:(NSString *)format, ...;
+ (NSString *) cachesDir;

/** @name Configuration for Static Requests
 *  @{
 *  @note In general, the equivalent methods in RCResource should be preferred if you plan on using these more than once. 
 */

+ (NSTimeInterval) timeout;
+ (void) setTimeout:(NSTimeInterval)timeout;

+ (NSMutableArray *)authProviders;
+ (void) setAuthProviders:(NSMutableArray *)authProviders;

+ (NSMutableDictionary *) headers;
+ (void) setHeaders:(NSMutableDictionary *)headers;

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

/** @} */



/** @name Static Requests
 *  @{
 *  @brief These methods simply create anonymous resources under the hood and delegate the request to them. They are useful if you have a non-conforming service, or just need to make the odd request.
 *  @param in all cases URL may be an NSURL or an NSString representing an URL
 *  @note In general, the equivalent methods in RCResource should be preferred if you plan on using these more than once. 
 */

/** @see RCResource#get. */
+ (RCResponse *) get:(id)URL;
/** @see RCResource#getWithCompletionBlock:. */
+ (void) get:(id)URL withCompletionBlock:(RCCompletionBlock)completionBlock;
/** @see RCResource#getWithProgressBlock:completionBlock:. */
+ (void) get:(id)URL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;

/** @see RCResource#head. */
+ (RCResponse *) head:(id)URL;
/** @see RCResource#deleteWithCompletionBlock:. */
+ (void) head:(id)URL withCompletionBlock:(RCCompletionBlock)completionBlock;

/** @see RCResource#delete. */
+ (RCResponse *) delete:(id)URL;
/** @see RCResource#deleteWithCompletionBlock:. */
+ (void) delete:(id)URL withCompletionBlock:(RCCompletionBlock)completionBlock;

/** @see RCResource#post:. */
+ (RCResponse *) post:(id)URL payload:(id)payload;
/** @see RCResource#post:completionBlock:. */
+ (void) post:(id)URL payload:(id)payload withCompletionBlock:(RCCompletionBlock)completionBlock;
/** @see RCResource#post:progressBlock:completionBlock:. */
+ (void) post:(id)URL payload:(id)payload withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;

/** @see RCResource#put:. */
+ (RCResponse *) put:(id)URL payload:(id)payload;
/** @see RCResource#put:completionBlock:. */
+ (void) put:(id)URL payload:(id)payload withCompletionBlock:(RCCompletionBlock)completionBlock;
/** @see RCResource#put:progressBlock:completionBlock:. */
+ (void) put:(id)URL payload:(id)payload withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;

/** @see RCResource#downloadWithProgressBlock:completionBlock:. */
+ (void) download:(id)URL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;
/** @see RCResource#uploadFile:withProgressBlock:completionBlock:. */
+ (void) uploadFile:(NSURL *)fileURL to:(id)URL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock;

/** @} */

@end


