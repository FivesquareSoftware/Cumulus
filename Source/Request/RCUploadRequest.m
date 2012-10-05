//
//  RCUploadRequest.m
//  RESTClient
//
//  Created by John Clayton on 11/24/11.
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

#import "RCUploadRequest.h"
#import "RCRequest+Protected.h"

#import "RESTClient.h"


@implementation RCUploadRequest

@synthesize fileToUploadURL=_fileToUploadURL;

- (void) configureURLRequest:(NSMutableURLRequest *)URLRequest {
	[super configureURLRequest:URLRequest];
	
	NSFileManager *fm = [[NSFileManager alloc] init];
	
	if (NO == [fm fileExistsAtPath:[self.fileToUploadURL  path]]) {
		NSDictionary *info = [NSDictionary dictionaryWithObject:[self.fileToUploadURL path] forKey:NSFilePathErrorKey];
		NSError *missingFileError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileNoSuchFileError userInfo:info];
		self.error = missingFileError;
		[self abort];
		return;
	}
	
	NSError *readError = nil;
	NSDictionary *attributes = [fm attributesOfItemAtPath:[self.fileToUploadURL path] error:&readError];
	if (nil == attributes) {
		self.error = readError;
		[self abort];
	}
	
	// Set up body stream and content length
	
	self.bodyContentLength = [attributes fileSize]; 	
	URLRequest.HTTPBodyStream = [NSInputStream inputStreamWithURL:self.fileToUploadURL];
	[URLRequest setValue:[[NSNumber numberWithUnsignedLongLong:[attributes fileSize]] stringValue] forHTTPHeaderField:@"Content-Length"];
	
	// Get the mime-type from UTI
	NSString *MIMEType = [self mimeTypeForFileAtPath:[self.fileToUploadURL path]];
	[URLRequest setValue:MIMEType forHTTPHeaderField:kRESTClientHTTPHeaderContentType];
}

// ========================================================================== //

#pragma mark - NSURLConnectionDataDelegate



- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request {
	return [NSInputStream inputStreamWithURL:self.fileToUploadURL];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite {
	self.sentContentLength = totalBytesWritten;
	
	[self handleConnectionDidSendData];
}


@end
