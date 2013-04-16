//
//  Cumulus.m
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

#import "Cumulus.h"


@interface Cumulus()
+ (CMResource *) configuredResourceForURL:(id)URL method:(NSString *)HTTPMethod;
@end


@implementation Cumulus


// ========================================================================== //

#pragma mark - Class Methods

+ (void) load {
	@autoreleasepool {
		NSFileManager *fm = [NSFileManager new];
		if (NO == [fm fileExistsAtPath:[self cachesDir]]) {
			NSError *error = nil;
			if (NO == [fm createDirectoryAtPath:[self cachesDir] withIntermediateDirectories:YES attributes:nil error:&error]) {
				RCLog(@"Could not create Cumulus caches %@ (%@)", [error localizedDescription], [error userInfo]);
			}
		}
	}
}

+ (void) log:(NSString *)format, ... {
	static id CumulusLoggingOnEnvironment = nil;
	static BOOL isLoggingEnabled = NO;
	static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
		if (nil == CumulusLoggingOnEnvironment) {
			NSProcessInfo *processInfo = [NSProcessInfo processInfo];
			CumulusLoggingOnEnvironment = [[processInfo environment] objectForKey:@"CumulusLoggingOn"];
			if (nil == CumulusLoggingOnEnvironment) {
				CumulusLoggingOnEnvironment = [NSNumber numberWithBool:NO]; // don't check anymore
				isLoggingEnabled = NO;
			}
			else {
				isLoggingEnabled = [CumulusLoggingOnEnvironment boolValue];
			}
		}
    });

	if (isLoggingEnabled) {
        va_list args;
        va_start(args,format);
		NSLogv(format, args);
        va_end(args);    
	}
}

+ (NSString *) cachesDir {
	static NSString *cachesDir = nil;
	@synchronized(@"Cumulus.cachesDir") {
		if (nil == cachesDir) {
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
			NSString *systemCaches = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
			if (systemCaches) {
				cachesDir = [systemCaches stringByAppendingPathComponent:kCumulusCachesDirectoryName];
			}
		}
	}
	return cachesDir;
}


static NSTimeInterval _timeout = 0;

+ (NSTimeInterval) timeout {
	return _timeout;
}

+ (void) setTimeout:(NSTimeInterval)timeout {
	@synchronized(@"Cumulus.timeout") {
		if (_timeout != timeout) {
			_timeout = timeout;
		}
	}
}

static NSMutableArray *_authProviders = nil;

+ (NSMutableArray *)authProviders {
	return _authProviders;
}

+ (void) setAuthProviders:(NSMutableArray *)authProviders {
	@synchronized(@"Cumulus.authProviders") {
		if (_authProviders != authProviders) {
			_authProviders = authProviders;
		}
	}
}

static NSMutableDictionary *_headers = nil;

+ (NSMutableDictionary *) headers {
	@synchronized(@"Cumulus.headers") {
		if (nil == _headers) {
			_headers = [NSMutableDictionary new];
		}
	}
	return _headers;
}

+ (void) setHeaders:(NSMutableDictionary *)headers {
	@synchronized(@"Cumulus.headers") {
		if (_headers != headers) {
			_headers = headers;
		}
	}
}

static NSMutableDictionary *_fixtures = nil;

+ (NSMutableDictionary *) fixtures {
	@synchronized(@"Cumulus.fixtures") {
		if (_fixtures == nil) {
			_fixtures = [NSMutableDictionary new];
		}
	}
	return _fixtures;
}

+ (void) setFixtures:(NSMutableDictionary *)fixtures {
	@synchronized(@"Cumulus.fixtures") {
		if (_fixtures != fixtures) {
			_fixtures = fixtures;
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

static BOOL _usingFixtures = NO;

+ (BOOL) usingFixtures {
	return _usingFixtures;
}

+ (void) useFixtures:(BOOL)useFixtures {
	_usingFixtures = useFixtures;
}


// ========================================================================== //

#pragma mark - Requests


#pragma mark -GET

+ (CMResponse *) get:(id)URL {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodGET];
	return [resource get];
}

+ (void) get:(id)URL withCompletionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodGET];
	[resource getWithCompletionBlock:completionBlock];
}

+ (void) get:(id)URL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodGET];
	[resource getWithProgressBlock:progressBlock completionBlock:completionBlock];
}


#pragma mark -HEAD

+ (CMResponse *) head:(id)URL {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodHEAD];
	return [resource head];
}

+ (void) head:(id)URL withCompletionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodHEAD];
	[resource headWithCompletionBlock:completionBlock];
}

#pragma mark -DELETE

+ (CMResponse *) delete:(id)URL {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodDELETE];
	return [resource delete];
}

+ (void) delete:(id)URL withCompletionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodDELETE];
	[resource deleteWithCompletionBlock:completionBlock];
}

#pragma mark -POST

+ (CMResponse *) post:(id)URL payload:(id)payload {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodPOST];
	return [resource post:payload];
}

+ (void) post:(id)URL payload:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodPOST];
	[resource post:payload withCompletionBlock:completionBlock];
}

+ (void) post:(id)URL payload:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodPOST];
	[resource post:payload withProgressBlock:progressBlock completionBlock:completionBlock];
}

#pragma mark -PUT

+ (CMResponse *) put:(id)URL payload:(id)payload {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodPUT];
	return [resource put:payload];
}

+ (void) put:(id)URL payload:(id)payload withCompletionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodPUT];
	[resource put:payload withCompletionBlock:completionBlock];
}

+ (void) put:(id)URL payload:(id)payload withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodPUT];
	[resource put:payload withProgressBlock:progressBlock completionBlock:completionBlock];
}


#pragma mark -Files

+ (void) download:(id)URL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodGET];
	[resource downloadWithProgressBlock:progressBlock completionBlock:completionBlock];
}

+ (void) uploadFile:(NSURL *)fileURL to:(id)URL withProgressBlock:(CMProgressBlock)progressBlock completionBlock:(CMCompletionBlock)completionBlock {
	CMResource *resource = [self configuredResourceForURL:URL method:kCumulusHTTPMethodPUT];
	[resource uploadFile:fileURL withProgressBlock:progressBlock completionBlock:completionBlock];
}



// ========================================================================== //

#pragma mark - Helpers

+ (CMResource *) configuredResourceForURL:(id)URL method:(NSString *)method {
	CMResource *resource = [CMResource withURL:URL];

	resource.timeout = [self timeout];
	resource.headers = [self headers];
	resource.authProviders = [self authProviders];
	
	if (_usingFixtures) {
		id fixture = nil;
		if ( (fixture = [_fixtures objectForKey:[NSString stringWithFormat:@"%@ %@",method,[resource.URL absoluteString]]]) ) {
			[resource setFixture:fixture forHTTPMethod:method];
		}
	}
	
	return resource;
}





@end
