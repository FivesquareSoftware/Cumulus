//
//  RCOAuth2AuthProvider.h
//  RESTClient
//
//  Created by John Clayton on 12/12/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCAuthProvider.h"

#import "RCTypes.h"
#import "RCOAuthToken.h"


@class RCResource;
@class RCOAuthToken;

@interface RCOAuth2AuthProvider : NSObject <RCAuthProvider>

@property (strong, nonatomic) NSURL *authorizationURL; ///< Initiates an authorization request from the resource owner 
@property (strong, nonatomic) RCResource *tokenService; ///< Used to request an access token for both authorization
@property (strong, nonatomic) RCOAuthToken *token; // includes an access token and the refresh token + expiration date if they exist

+ (id) withAuthorizationURL:(NSURL *)authorizationURL tokenService:(RCResource *)tokenService;

/** Aysnchronously requests and stores an access token directly from the token service using a 'password' grant type. */
- (void) requestAccessTokenWithUsername:(NSString *)username password:(NSString *)password completionBlock:(RCCompletionBlock)passedBlock;

/** Will direct the user to the authorization service, collect the authorization code that results from the authorization flow presented there, then request an access token from the token service using the 'authorization' grant type. 
 *  @note - Unimplemented
 */
- (void) requestAccessTokenUsingWebView:(UIWebView *)webView;

@end
