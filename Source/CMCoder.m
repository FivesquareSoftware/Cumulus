//
//  CMCoder.m
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

#import "CMCoder.h"


@implementation CMCoder

+ (NSMutableDictionary *) codersByObject {
	static NSMutableDictionary *codersByObject = nil;
	@synchronized(@"CMCoder.codersByObject") {
		if (nil == codersByObject) {
			codersByObject = [NSMutableDictionary dictionary];
		}
	}
	return codersByObject;
}

+ (NSMutableDictionary *) codersByMimeType {
	static NSMutableDictionary *codersByMimeType = nil;
	@synchronized(@"CMCoder.codersByMimeType") {
		if (nil == codersByMimeType) {
			codersByMimeType = [NSMutableDictionary dictionary];
		}
	}
	return codersByMimeType;
}

+ (NSMutableDictionary *) codersByFileExtension {
	static NSMutableDictionary *codersByFileExtension = nil;
	@synchronized(@"CMCoder.codersByFileExtension") {
		if (nil == codersByFileExtension) {
			codersByFileExtension = [NSMutableDictionary dictionary];
		}
	}
	return codersByFileExtension;
}

+ (void) registerCoder:(Class)coder objectType:(Class)type mimeTypes:(NSArray *)mimeTypes fileExtensions:(NSArray *)fileExtensions {
	if (type) {
		[[self codersByObject] setObject:coder forKey:NSStringFromClass(type)];
	}
	for (NSString *mimeType in mimeTypes) {
		[[self codersByMimeType] setObject:coder forKey:mimeType];
	}
	for (NSString *fileExtension in fileExtensions) {
		[[self codersByFileExtension] setObject:coder forKey:fileExtension];
	}
}


+ (id<CMCoder>) coderForObject:(id)obj {
	id<CMCoder> coder = nil;
	for (NSString *objectClassName in [self codersByObject]) {
		Class objectClass = NSClassFromString(objectClassName);
		if ([obj isKindOfClass:objectClass]) {
			Class coderClass = [[self codersByObject] objectForKey:objectClassName];
			coder = [coderClass new];
			break;
		}
	}
	return coder;
}


+ (id<CMCoder>) coderForMimeType:(NSString *)mimeType {
	id<CMCoder> coder = nil;
	for (id matcher in [self codersByMimeType]) {
		Class coderClass = [[self codersByMimeType] objectForKey:matcher];

		if ([matcher isKindOfClass:[NSRegularExpression class]]) {
			if ([matcher numberOfMatchesInString:mimeType options:0 range:NSMakeRange(0, mimeType.length)] > 0) {
				coder = [coderClass new];
				break;
			}
		} 
		else if ([matcher isKindOfClass:[NSString class]]) {
			if ([matcher isEqualToString:mimeType]) {
				coder = [coderClass new];
				break;
			}
			
		}
	}
	return coder;
}

+ (id<CMCoder>) coderForFileExtension:(NSString *)fileExtension {
	id<CMCoder> coder = nil;
	for (id matcher in [self codersByFileExtension]) {
		Class coderClass = [[self codersByFileExtension] objectForKey:matcher];
		
		if ([matcher isKindOfClass:[NSRegularExpression class]]) {
			if ([matcher numberOfMatchesInString:fileExtension options:0 range:NSMakeRange(0, fileExtension.length)] > 0) {
				coder = [coderClass new];
				break;
			}
		}
		else if ([matcher isKindOfClass:[NSString class]]) {
			if ([matcher isEqualToString:fileExtension]) {
				coder = [coderClass new];
				break;
			}
			
		}
	}
	return coder;
}


@end
