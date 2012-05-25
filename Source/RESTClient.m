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
+ (RCResource *) configuredResourceForURL:(id)URL method:(NSString *)HTTPMethod;
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

static NSMutableDictionary *fixtures_ = nil;

+ (NSMutableDictionary *) fixtures {
	@synchronized(@"RESTClient.fixtures") {
		if (fixtures_ == nil) {
			fixtures_ = [NSMutableDictionary new];
		}
	}
	return fixtures_;
}

+ (void) setFixtures:(NSMutableDictionary *)fixtures {
	@synchronized(@"RESTClient.fixtures") {
		if (fixtures_ != fixtures) {
			fixtures_ = fixtures;
		}
	}
}

+ (void) loadFixturesNamed:(NSString *)plistName {
	NSString *path = [[NSBundle mainBundle] pathForResource:plistName ofType:@"plist"];
	NSDictionary *fixtures = [NSDictionary dictionaryWithContentsOfFile:path];
	[[self fixtures] addEntriesFromDictionary:fixtures];
}

+ (void) addFixture:(id)fixture forRequestSignature:(NSString *)requestSignature {
	[[self fixtures] setObject:fixture forKey:requestSignature];
}

static BOOL usingFixtures_ = NO;

+ (BOOL) usingFixtures {
	return usingFixtures_;
}

+ (void) useFixtures:(BOOL)useFixtures {
	usingFixtures_ = useFixtures;
}


// ========================================================================== //

#pragma mark - Requests


#pragma mark -GET

+ (RCResponse *) get:(id)URL {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodGET];
	return [resource get];
}

+ (void) get:(id)URL withCompletionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodGET];
	[resource getWithCompletionBlock:completionBlock];
}

+ (void) get:(id)URL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodGET];
	[resource getWithProgressBlock:progressBlock completionBlock:completionBlock];
}


#pragma mark -HEAD

+ (RCResponse *) head:(id)URL {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodHEAD];
	return [resource head];
}

+ (void) head:(id)URL withCompletionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodHEAD];
	[resource headWithCompletionBlock:completionBlock];
}

#pragma mark -DELETE

+ (RCResponse *) delete:(id)URL {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodDELETE];
	return [resource delete];
}

+ (void) delete:(id)URL withCompletionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodDELETE];
	[resource deleteWithCompletionBlock:completionBlock];
}

#pragma mark -POST

+ (RCResponse *) post:(id)URL payload:(id)payload {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodPOST];
	return [resource post:payload];
}

+ (void) post:(id)URL payload:(id)payload withCompletionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodPOST];
	[resource post:payload withCompletionBlock:completionBlock];
}

+ (void) post:(id)URL payload:(id)payload withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodPOST];
	[resource post:payload withProgressBlock:progressBlock completionBlock:completionBlock];
}

#pragma mark -PUT

+ (RCResponse *) put:(id)URL payload:(id)payload {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodPUT];
	return [resource put:payload];
}

+ (void) put:(id)URL payload:(id)payload withCompletionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodPUT];
	[resource put:payload withCompletionBlock:completionBlock];
}

+ (void) put:(id)URL payload:(id)payload withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodPUT];
	[resource put:payload withProgressBlock:progressBlock completionBlock:completionBlock];
}


#pragma mark -Files

+ (void) download:(id)URL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodGET];
	[resource downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
}

+ (void) uploadFile:(NSURL *)fileURL to:(id)URL withProgressBlock:(RCProgressBlock)progressBlock completionBlock:(RCCompletionBlock)completionBlock {
	RCResource *resource = [self configuredResourceForURL:URL method:kRESTClientHTTPMethodPUT];
	[resource uploadFile:fileURL withProgressBlock:progressBlock completionBlock:completionBlock];
}



// ========================================================================== //

#pragma mark - Helpers

+ (RCResource *) configuredResourceForURL:(id)URL method:(NSString *)method {
	RCResource *resource = [RCResource withURL:URL];

	resource.timeout = [self timeout];
	resource.headers = [self headers];
	resource.authProviders = [self authProviders];
	
	if (usingFixtures_) {
		id fixture = nil;
		if ( (fixture = [fixtures_ objectForKey:[NSString stringWithFormat:@"%@ %@",method,[resource.URL absoluteString]]]) ) {
			[resource setFixture:fixture forHTTPMethod:method];
		}
	}
	
	return resource;
}





@end
