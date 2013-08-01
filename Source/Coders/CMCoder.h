//
//  CMCoder.h
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

/** The \<CMCoder\> protocol is implemented in order to provide two-way encoding/decoding of response/request data to and from native objects and raw bytes. In this way, they are very similar to NSValueTransformer with some additional services layered on top. Which \<CMCoder\> implementation is employed for any given request/response cycle is determined by examining the criteria (payload object type, file extension, mime type) that each implementation has registered to handle, and using metadata about the payload, request and/or response type to match to those criteria. Cumulus includes coder implementations for [NSData](CMIdentityCoder), [NSString](CMTextCoder), [JSON](CMJSONCoder), [XML Plists](CMXMLCoder), and [PNGs](CMImageCoder). Writing a new coder is trivial.  */
@protocol CMCoder <NSObject>

/** Accepts payload (or fixture) objects and encodes them for transport in the body of an HTTP request.
 *  @param object The payload object to encode for transport
 */
- (NSData *) encodeObject:(id)object;

/** Accepts raw response (or fixture) data and decodes it to native object types.
 *  @param data The response data to decode to native objects
 */
- (id) decodeData:(NSData *)data;

@end


/** CMCoder is a partially abstract base class that implements the CMCoder protocol and provides a common registration mechanism for subclasses or other CMCoder implementations to register their coding criteria. 
 *  @see [CMCoder](CMCoder)
 */
@interface CMCoder : NSObject {
	
}

/** Collection of coders registered by object types. */
+ (NSMutableDictionary *) codersByObject;
/** Collection of coders registered by mime types. */
+ (NSMutableDictionary *) codersByMimeType;
/** Collection of coders registered by file extensions. */
+ (NSMutableDictionary *) codersByFileExtension;

/**
 * Register a coder class to handle a particular object type (like NSString) or a collection of mime-types (like text/plain).
 * @param mimeTypes An Array of either NSString or NSRegularExpression objects to match against header values. Strings must match exactly.
 */
+ (void) registerCoder:(Class)coder objectType:(Class)type mimeTypes:(NSArray *)mimeTypes fileExtensions:(NSArray *)fileExtensions;

/** @returns a CMCoder instance that can handle the given object type. */
+ (id<CMCoder>) coderForObject:(id)obj;
/** @returns a CMCoder instance that can handle the given mime-type. */
+ (id<CMCoder>) coderForMimeType:(NSString *)mimeType;
/** @returns a CMCoder instance that can handle the given file extension. */
+ (id<CMCoder>) coderForFileExtension:(NSString *)fileExtension;

@end


// import known coders

#import "CMIdentityCoder.h"
#import "CMTextCoder.h"
#import "CMJSONCoder.h"
#import "CMXMLCoder.h"
#import "CMImageCoder.h"

/** @todo add coders for other common types, image, etc. */
