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
- (void) mapTokenFromResult:(id)result;
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
				[self mapTokenFromResult:response.result];
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
	NSDate *now = [NSDate date];
	NSComparisonResult comparisonResult = [self.token.accessExpires compare:now];
	if (self.token.accessExpires &&  comparisonResult != NSOrderedDescending) {
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
	if (self.token.refreshToken.length) {
		NSDictionary *tokenPayload = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"refresh_token", @"grant_type"
									  , self.token.refreshToken, @"refresh_token"
									  , nil];
		
		RCResponse *response = [self.tokenService post:tokenPayload];
		if (response.success) {
			[self mapTokenFromResult:response.result];
		} else {
			RCLog(@"Could not refresh token: %@ (%@)",[response.error localizedDescription],[response.error userInfo]);
		}
	}
}

- (void) mapTokenFromResult:(id)result {
	self.token.accessToken = [result valueForKey:@"access_token"];
	self.token.refreshToken = [result valueForKey:@"refresh_token"];
	NSTimeInterval expiresIn = [[result valueForKey:@"expires_in"] doubleValue];
	if (expiresIn > 0) {
		self.token.accessExpires = [NSDate dateWithTimeIntervalSinceNow:expiresIn];
	}
	self.token.scope = [result valueForKey:@"scope"];
}


@end
