//
//  RCXMLCoder.m
//  RESTClient
//
//  Created by John Clayton on 9/7/11.
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

#import "RCXMLCoder.h"

#import "RESTClient.h"

@implementation RCXMLCoder

+ (void) load {
	@autoreleasepool {
		NSRegularExpression *mimeExpression = [NSRegularExpression regularExpressionWithPattern:@"xml" options:0 error:NULL];
		[RCCoder registerCoder:self objectType:nil mimeTypes:[NSArray arrayWithObject:mimeExpression]];
	}
}

- (NSData *) encodeObject:(id)payload {	
	NSData *data = nil;
	@try {
		NSError *error = nil;
		data = [NSPropertyListSerialization dataWithPropertyList:payload format:NSPropertyListXMLFormat_v1_0 options:0 error:&error];
		if (error) {
			RCLog(@"XML coding error: %@ (%@)",[error localizedDescription],[error userInfo]);
		}
	}
	@catch (NSException *exception) {
		RCLog(@"XML coding error: %@",[exception reason]);
	}
    return data;
}

- (id) decodeData:(NSData *)data {
	id object = nil;
	NSError *error = nil;
	@try {
		object = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:&error];
	}
	@catch (NSException *exception) {
		RCLog(@"XML coding error: %@",[exception reason]);
	}
    return object;
}

@end
