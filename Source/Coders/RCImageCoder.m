//
//  RCImageCoder.m
//  RESTClient
//
//  Created by John Clayton on 10/15/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
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

#import "RCImageCoder.h"

@implementation RCImageCoder

+ (void) load {
	@autoreleasepool {
		NSRegularExpression *mimeExpression = [NSRegularExpression regularExpressionWithPattern:@"image" options:0 error:NULL];
#if TARGET_OS_IPHONE
		[RCCoder registerCoder:self objectType:[UIImage class] mimeTypes:[NSArray arrayWithObject:mimeExpression] fileExtensions:[NSArray arrayWithObject:@"png"]];
#else
		[RCCoder registerCoder:self objectType:[NSImage class] mimeTypes:[NSArray arrayWithObject:mimeExpression] fileExtensions:[NSArray arrayWithObject:@"png"]];
#endif
	}
}

- (NSData *) encodeObject:(id)object {
#if TARGET_OS_IPHONE
	if ([object isKindOfClass:[UIImage class]]) {
		return UIImagePNGRepresentation(object);
		//TODO: encode the data to the correct kind of image based on data
	}
#else
	//TODO: handle NSImage
#endif
	return nil;
}

- (id) decodeData:(NSData *)data {
#if TARGET_OS_IPHONE
	return [[UIImage alloc] initWithData:data];
#else
	//TODO: handle NSImage
#endif
	return data;
}

@end
