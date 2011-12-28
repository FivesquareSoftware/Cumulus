//
//  RESTClient.m
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

#import "RESTClient.h"

@interface RESTClient()
+ (RCResource *) configuredResourceForURLString:(NSString *)URLString;
@end


@implementation RESTClient


// ========================================================================== //

#pragma mark - Class Methods

+ (void) load {
	@autoreleasepool {
		NSFileManager *fm = [NSFileManager new];
		if (NO == [fm fileExistsAtPath:[self cachesDir]]) {
			NSError *error = nil;
			if (NO == [fm createDirectoryAtPath:[self cachesDir] withIntermediateDirectories:YES attributes:nil error:&error]) {
				RCLog(@"Could not create RESTClient caches %@ (%@)", [error localizedDescription], [error userInfo]);
			}
		}
	}
}

+ (void) log:(NSString *)format, ... {
	static id RESTClientLoggingOnEnvironment = nil;
	static BOOL isLoggingEnabled = NO;
	@synchronized(@"RESTClientLoggingOn") {
		if (nil == RESTClientLoggingOnEnvironment) {
			NSProcessInfo *processInfo = [NSProcessInfo processInfo];
			RESTClientLoggingOnEnvironment = [[processInfo environment] objectForKey:@"RESTClientLoggingOn"];
			if (nil == RESTClientLoggingOnEnvironment) {
				RESTClientLoggingOnEnvironment = [NSNumber numberWithBool:NO]; // don't check anymore
				isLoggingEnabled = NO;
			} else {
				isLoggingEnabled = [RESTClientLoggingOnEnvironment boolValue];
			}
		}
	}
	if (isLoggingEnabled) {
        va_list args;
        va_start(args,format);
		NSLogv(format, args);
        va_end(args);    
	}
}

+ (NSString *) cachesDir {
	static NSString *cachesDir = nil;
	@synchronized(@"RESTClient.cachesDir") {
		if (nil == cachesDir) {
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
			NSString *systemCaches = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
			if (systemCaches) {
				cachesDir = [systemCaches stringByAppendingPathComponent:kRESTClientCachesDirectoryName];
			}
		}
	}
	return cachesDir;
}


static NSTimeInterval timeout_ = 0;

+ (NSTimeInterval) timeout {
	return timeout_;
}

+ (void) setTimeout:(NSTimeInterval)timeout {
	@synchronized(@"RESTClient.timeout") {
		if (timeout_ != timeout) {
			timeout_ = timeout;
		}
	}
}

static NSMutableArray *authProviders_ = nil;

+ (NSMutableArray *)authProviders {
	return authProviders_;
}

+ (void) setAuthProviders:(NSMutableArray *)authProviders {
	@synchronized(@"RESTClient.authProviders") {
		if (authProviders_ != authProviders) {
			authProviders_ = authProviders;
		}
	}
}

static NSMutableDictionary *headers_ = nil;

+ (NSMutableDictionary *) headers {
	@synchronized(@"RESTClient.headers") {
		if (nil == headers_) {
			headers_ = [NSMutableDictionary new];
		}
	}
	return headers_;
}

+ (void) setHeaders:(NSMutableDictionary *)headers {
	@synchronized(@"RESTClient.headers") {
		if (headers_ != headers) {
			headers_ = headers;
		}
	}
}


// ========================================================================== //

#pragma mark - Requests


#pragma mark -GET

+ (RCResponse *) get:(NSString *)URLString {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	return [resource get];
}

+ (void) get:(NSString *)URLString completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource getWithCompletionBlock:completionBlock];
}

+ (void) get:(NSString *)URLString progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource getWithProgressBlock:progressBlock completionBlock:completionBlock];
}


#pragma mark -HEAD

+ (RCResponse *) head:(NSString *)URLString {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	return [resource head];
}

+ (void) head:(NSString *)URLString completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource headWithCompletionBlock:completionBlock];
}

#pragma mark -DELETE

+ (RCResponse *) delete:(NSString *)URLString {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	return [resource delete];
}

+ (void) delete:(NSString *)URLString completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource deleteWithCompletionBlock:completionBlock];
}

#pragma mark -POST

+ (RCResponse *) post:(NSString *)URLString payload:(id)payload {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	return [resource post:payload];
}

+ (void) post:(NSString *)URLString payload:(id)payload completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource post:payload completionBlock:completionBlock];
}

+ (void) post:(NSString *)URLString payload:(id)payload progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource post:payload progressBlock:progressBlock completionBlock:completionBlock];
}

#pragma mark -PUT

+ (RCResponse *) put:(NSString *)URLString payload:(id)payload {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	return [resource put:payload];
}

+ (void) put:(NSString *)URLString payload:(id)payload completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource put:payload completionBlock:completionBlock];
}

+ (void) put:(NSString *)URLString payload:(id)payload progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource put:payload progressBlock:progressBlock completionBlock:completionBlock];
}


#pragma mark -Files

+ (void) download:(NSString  *)URLString progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
}

+ (void) uploadFile:(NSURL *)fileURL to:(NSString *)URLString progressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURLString:URLString];
	[resource uploadFile:fileURL withProgressBlock:progressBlock completionBlock:completionBlock];
}



// ========================================================================== //

#pragma mark - Helpers

+ (RCResource *) configuredResourceForURLString:(NSString *)URLString {
	RCResource *resource = [RCResource withURL:URLString];

	resource.timeout = [self timeout];
	resource.headers = [self headers];
	resource.authProviders = [self authProviders];
	
	return resource;
}





@end
