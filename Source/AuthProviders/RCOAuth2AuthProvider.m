//
//  RCOAuth2AuthProvider.m
//  RESTClient
//
//  Created by John Clayton on 12/12/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCOAuth2AuthProvider.h"

#import "RESTClient.h"


@interface RCOAuth2AuthProvider()
- (void) refreshAccessToken;
- (void) addAuthHeader:(NSMutableURLRequest *)URLRequest;
@end


@implementation RCOAuth2AuthProvider

@synthesize authorizationURL=authorizationURL_;
@synthesize tokenService=tokenService_;
@synthesize token=token_;

+ (id) withAuthorizationURL:(NSURL *)authorizationURL tokenService:(RCResource *)tokenService {
    RCOAuth2AuthProvider *provider = [self new];
	provider.authorizationURL = authorizationURL;
	provider.tokenService = tokenService;
    return provider;
}

// ========================================================================== //

#pragma mark - Token Generation



- (void) requestAccessTokenWithUsername:(NSString *)username password:(NSString *)password completionBlock:(RCCompletionBlock)passedBlock {
	if (username && password) {
		NSDictionary *tokenPayload = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"password", @"grant_type"
									  , username, @"username"
									  , password, @"password"
									  , nil];
		
		RCCompletionBlock completionBlock = ^(RCResponse *response) {
			if (response.success) {		
				self.token = [RCOAuthToken new];
				self.token.accessToken = [response.result valueForKey:@"access_token"];
				self.token.refreshToken = [response.result valueForKey:@"refresh_token"];
				self.token.tokenExpiration = [response.result valueForKey:@"expiration_date"];
			}
			if (passedBlock) {
				passedBlock(response);
			}
		};
		
		[self.tokenService post:tokenPayload completionBlock:completionBlock];
	}	
}

- (void) requestAccessTokenUsingWebView:(UIWebView *)webView {
	//TODO
}



// ========================================================================== //

#pragma mark - RCAuthProvider

- (NSString *) providedAuthenticationMethod {
	return nil; // I dunno, basic?
}

- (void) authorizeRequest:(NSMutableURLRequest *)URLRequest {
	if (self.token.tokenExpiration && [self.token.tokenExpiration compare:[NSDate date]] != NSOrderedAscending
		&& self.token.refreshToken.length) {
		[self refreshAccessToken];
	}
	[self addAuthHeader:URLRequest];
}

- (NSURLCredential *) credentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
	return nil;
	// wondering, could we build a credential that would properly set the Authorization header?
}


// ========================================================================== //

#pragma mark - Helpers



- (void) addAuthHeader:(NSMutableURLRequest *)URLRequest {
	if(self.token.accessToken.length) {
		NSString *authHeader = [NSString stringWithFormat:@"OAuth %@",self.token.accessToken];
		[URLRequest setValue:authHeader forHTTPHeaderField:@"Authorization"];
	}
}

- (void) refreshAccessToken {
	NSDictionary *tokenPayload = [NSDictionary dictionaryWithObjectsAndKeys:
								  @"refresh_token", @"grant_type"
								  , self.token.refreshToken, @"refresh_token"
								  , nil];
		
	RCResponse *response = [self.tokenService post:tokenPayload];
	if (response.success) {		
		self.token.accessToken = [response.result valueForKey:@"access_token"];
		self.token.refreshToken = [response.result valueForKey:@"refresh_token"];
		self.token.tokenExpiration = [response.result valueForKey:@"expiration_date"];
	} else {
		RCLog(@"Could not refresh token: %@ (%@)",[response.error localizedDescription],[response.error userInfo]);
	}
}



@end
