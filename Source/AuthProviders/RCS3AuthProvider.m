//
//  RCS3AuthProvider.m
//  RESTClient
//
//  Created by John Clayton on 8/16/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
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
 * 3. Neither the name of Fivesquare Software, LLC nor the names of its contributors may
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

#import "RCS3AuthProvider.h"

@implementation RCS3AuthProvider


// ========================================================================== //

#pragma mark - RCAuthProvider

- (NSString *) providedAuthenticationMethod {
	return nil; // I dunno, basic?
}

- (void) authorizeRequest:(NSMutableURLRequest *)URLRequest {
//	NSDate *now = [NSDate date];
//	NSComparisonResult comparisonResult = [self.token.accessExpires compare:now];
//	if (self.token.accessExpires &&  comparisonResult != NSOrderedDescending) {
//		[self refreshAccessToken];
//	}
//	[self addAuthHeader:URLRequest];
}

- (NSURLCredential *) credentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	return nil;
	// wondering, could we build a credential that would properly set the Authorization header?
}


@end