//
//  CMFormCoder.m
//  Cumulus
//
//  Created by Carlos McEvilly on 6/19/14.
//  Copyright 2014 Fivesquare Software, LLC. All rights reserved.
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


#import "CMFormCoder.h"

@implementation CMFormCoder

+ (void) load {
	@autoreleasepool {
		NSRegularExpression *mimeExpression = [NSRegularExpression regularExpressionWithPattern:@"www-form" options:0 error:NULL];
		NSArray *fileExtensions = @[];
		[CMCoder registerCoder:self objectType:[NSString class] mimeTypes:[NSArray arrayWithObject:mimeExpression] fileExtensions:fileExtensions];
	}
}

- (NSData *)encodeObject:(id)object {

	NSMutableArray *pairs = [NSMutableArray new];
	
	if (NO == [object isKindOfClass:[NSDictionary class]]) {
		return nil;
	}
	
	for (NSString *key in [object allKeys]) {
		id value = [object valueForKey:key];
		if (NO == [value isKindOfClass:[NSString class]]) {
			if ([value respondsToSelector:@selector(description)]) {
				value = [value description];
			}
		}
		value = [self urlencodeString:value];
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
	}
	NSString *payloadString = [pairs componentsJoinedByString:@"&"];
	return [payloadString dataUsingEncoding:NSUTF8StringEncoding];
}


- (id) decodeData:(NSData *)data {
	
	NSStringEncoding encoding = NSUTF8StringEncoding;

	NSString *payloadString = nil;
	if (data) {
		payloadString = [[NSString alloc] initWithData:data
											  encoding:encoding];
	}

	NSMutableDictionary *dataDict = nil;
	if (payloadString) {
		dataDict = [NSMutableDictionary new];
		NSArray *pairs = [payloadString componentsSeparatedByString:@"&"];
		for (NSString *pairString in pairs) {
			NSArray *pairItems = [pairString componentsSeparatedByString:@"="];
			// Process only well-formed actual pairs
			if ([pairItems count]==2) {
				NSString *pairKey = [pairItems firstObject];
				NSString *pairValue = [pairItems lastObject];
				NSString *urlencodedValue = [self urldecodeString:pairValue withEncoding:encoding];
				[dataDict setObject:urlencodedValue forKey:pairKey];
			}
		}
	}
	if ([dataDict count]) {
		return [dataDict copy];
	}
	return nil;
}



/* Replace vulnerable characters with corresponding %XX hex values, e.g. "+" -> "%2b"
 * @param inputString - an NSString to be urlencoded
 * @param encoding - an enum identifying the character encoding of the inputString
 * returns the encoded result as an NSString*
 */
- (NSString *)urlencodeString:(NSString *)inputString {
	NSString *outputString = [inputString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
	return outputString;
}


/* Recover the original non-encoded string from a previously urlencoded NSString*
 * @param inputString - an NSString to be decoded
 * @param encoding - an enum identifying the character encoding of the inputString
 * returns the decoded result as an NSString*
 */
- (NSString *)urldecodeString:(NSString *)inputString withEncoding:(NSStringEncoding)encoding {
	NSString *decodedString = [inputString stringByRemovingPercentEncoding];
	return decodedString;
}


@end



