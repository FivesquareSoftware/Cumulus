//
//	CMOAuth2AuthProvider.m
//	Cumulus
//
//	Created by John Clayton on 12/12/11.
//	Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

/*
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *	  notice, this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 *	  this list of conditions and the following disclaimer in the documentation
 *	  and/or other materials provided with the distribution.
 *
 * 3. Neither the name of Fivesquare Software, LLC nor the names of its contributors may
 *	  be used to endorse or promote products derived from this software without
 *	  specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL FIVESQUARE SOFTWARE BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "CMOAuth2AuthProvider.h"

#import "Cumulus.h"


@interface CMOAuth2AuthProvider()
- (void) refreshAccessToken;
- (void) addAuthHeader:(NSMutableURLRequest *)URLRequest;
- (void) mapTokenFromResult:(id)result;
@end


@implementation CMOAuth2AuthProvider


+ (id) withAuthorizationURL:(NSURL *)authorizationURL tokenService:(CMResource *)tokenService {
	CMOAuth2AuthProvider *provider = [self new];
	provider.authorizationURL = authorizationURL;
	provider.tokenService = tokenService;
	return provider;
}


+ (id) withTokenService:(CMResource *)tokenService {
	return [self withAuthorizationURL:nil tokenService:tokenService];
}


// ========================================================================== //

#pragma mark - Token Generation



- (void) requestAccessTokenWithUsername:(NSString *)username password:(NSString *)password completionBlock:(CMCompletionBlock)passedBlock {

	NSParameterAssert(username);
	NSParameterAssert(password);

	if (username && password) {
		
		NSMutableDictionary *tokenPayload = [NSMutableDictionary new];
		
		// add optional arguments
		if (self.client_id ) {
			[tokenPayload setObject:self.client_id forKey:@"client_id"];
		}
		if (self.client_secret) {
			[tokenPayload setObject:self.client_secret forKey:@"client_secret"];
		}
		if (self.scope) {
			[tokenPayload setObject:self.scope forKey:@"scope"];
		}

		// required arguments - already checked for non-nil above
		[tokenPayload setObject:username forKey:@"username"];
		[tokenPayload setObject:password forKey:@"password"];
		[tokenPayload setObject:@"password" forKey:@"grant_type"];
		
		CMCompletionBlock completionBlock = ^(CMResponse *response) {
			if (response.wasSuccessful) {
				self.token = [CMOAuthToken new];
				[self mapTokenFromResult:response.result];
			}
			if (passedBlock) {
				passedBlock(response);
			}
		};
		
		[self.tokenService post:[tokenPayload copy] withCompletionBlock:completionBlock];
	}
}

#if TARGET_OS_IPHONE
- (void) requestAccessTokenUsingWebView:(UIWebView *)webView
#else
- (void) requestAccessTokenUsingWebView:(WebView *)webView
#endif
{
	//TODO
}



// ========================================================================== //

#pragma mark - CMAuthProvider
	
- (NSString *) providedAuthenticationMethod {
	return nil; // I dunno, basic?
}

- (void) authorizeRequest:(NSMutableURLRequest *)URLRequest {
	NSDate *now = [NSDate date];
	NSComparisonResult comparisonResult = [self.token.accessExpires compare:now];
	if (self.token.accessExpires &&	 comparisonResult != NSOrderedDescending) {
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
		NSString *authHeader = [NSString stringWithFormat:@"%@ %@",self.token.tokenType,self.token.accessToken];
		[URLRequest setValue:authHeader forHTTPHeaderField:kCumulusHTTPHeaderAuthorization];
	}
}

- (void) refreshAccessToken {
	if (self.token.refreshToken.length) {
		NSDictionary *tokenPayload = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"refresh_token", @"grant_type"
									  , self.token.refreshToken, @"refresh_token"
									  , nil];
		
		CMResponse *response = [self.tokenService post:tokenPayload];
		if (response.wasSuccessful) {
			[self mapTokenFromResult:response.result];
		}
		else {
			RCLog(@"Could not refresh token: %@ (%@)",[response.error localizedDescription],[response.error userInfo]);
		}
	}
}

- (void) mapTokenFromResult:(id)result {
	self.token.tokenType = [result valueForKey:@"token_type"];
	if ( ! self.token.tokenType) {
		self.token.tokenType = @"OAuth";
	}
	self.token.accessToken = [result valueForKey:@"access_token"];
	self.token.refreshToken = [result valueForKey:@"refresh_token"];
	NSTimeInterval expiresIn = [[result valueForKey:@"expires_in"] doubleValue];
	if (expiresIn > 0) {
		self.token.accessExpires = [NSDate dateWithTimeIntervalSinceNow:expiresIn];
	}
	// TODO: if scope is not set, it should be gotten from the original request
	self.token.scope = [result valueForKey:@"scope"];
}


@end
