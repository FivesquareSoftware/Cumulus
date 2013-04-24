//
//  CMOAuth2AuthProvider.h
//  Cumulus
//
//  Created by John Clayton on 12/12/11.
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

#import <Foundation/Foundation.h>
#if TARGET_OS_IPHONE == 0
#import <WebKit/WebKit.h>
#endif


#import "CMAuthProvider.h"

#import "CMTypes.h"
#import "CMOAuthToken.h"


@class CMResource;
@class CMOAuthToken;

/** Provides OAuth2 authentication to CMResources. */
@interface CMOAuth2AuthProvider : NSObject <CMAuthProvider>

/// Initiates an authorization request from the resource owner 
@property (strong, nonatomic) NSURL *authorizationURL;
/// Used to request an access token for both authorization
@property (strong, nonatomic) CMResource *tokenService;
/// includes an access token and the refresh token + expiration date if they exist
@property (strong, nonatomic) CMOAuthToken *token;

/** Creates a new auth provider using the authorization URL and token service requested. 
 *  @param authorizationURL A URL for an OAuth auth page. (Currently unused)
 *  @param tokenService an instance of CMResource that knows how to request, return and map a token response to an instance of CMOAuthToken.
 */
+ (id) withAuthorizationURL:(NSURL *)authorizationURL tokenService:(CMResource *)tokenService;

/** Aysnchronously requests and stores an access token directly from the token service using a 'password' grant type. */
- (void) requestAccessTokenWithUsername:(NSString *)username password:(NSString *)password completionBlock:(CMCompletionBlock)passedBlock;

/** Will direct the user to the authorization service, collect the authorization code that results from the authorization flow presented there, then request an access token from the token service using the 'authorization' grant type. 
 *  @note Unimplemented
 */
#if TARGET_OS_IPHONE
- (void) requestAccessTokenUsingWebView:(UIWebView *)webView;
#else 
- (void) requestAccessTokenUsingWebView:(WebView *)webView;
#endif

@end
