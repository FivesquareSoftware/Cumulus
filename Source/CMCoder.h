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
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

@protocol CMCoder <NSObject>
- (NSData *) encodeObject:(id)object;
- (id) decodeData:(NSData *)data;
@end


@interface CMCoder : NSObject {
	
}

+ (NSMutableDictionary *) codersByObject;
+ (NSMutableDictionary *) codersByMimeType;
+ (NSMutableDictionary *) codersByFileExtension;

/**
 * Register a coder class to handle a particular object type (like NSString) or a collection of mime-types (like text/plain).
 * @param mimeTypes - an Array of either NSString or NSRegularExpression objects to match against header values. Strings must match exactly.
 */
+ (void) registerCoder:(Class)coder objectType:(Class)type mimeTypes:(NSArray *)mimeTypes fileExtensions:(NSArray *)fileExtensions;

+ (id<CMCoder>) coderForObject:(id)obj;
+ (id<CMCoder>) coderForMimeType:(NSString *)mimeType;
+ (id<CMCoder>) coderForFileExtension:(NSString *)fileExtension;

@end


// import known coders

#import "CMIdentityCoder.h"
#import "CMTextCoder.h"
#import "CMJSONCoder.h"
#import "CMXMLCoder.h"
#import "CMImageCoder.h"

/** @todo add coders for other common types, image, etc. */