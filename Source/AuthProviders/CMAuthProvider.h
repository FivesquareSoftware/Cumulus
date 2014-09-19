//
//  CMAuthProvider.h
//  Cumulus
//
//  Created by John Clayton on 8/27/11.
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
 * DISCLAIMED. IN NO EVENT SHALL FIVESQUARE SOFTWARE BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>

/** CMAuthProvider is a simple protocol that can be easily implemented to include just about any type of request authorization. Cumulus includes built in implementations of CMAuthProvider that provide [BASIC](CMBasicAuthProvider), [CMServerTrustAuthProvider](Server Trust), [CMClientCertificateAuthProvider](Client Certificate), [CMOAuth2AuthProvider](OAuth2) and [CMS3AuthProvider](Amazon S3) authoriization. 
 *  @see the Cumulus Programming Guide for an example implementation of a custom auth provider.
 */
@protocol CMAuthProvider <NSObject>

/** One of the authentication methods defined in the NSURLAuthenticationMethod* constants. For example, a BASIC auth provider would return NSURLAuthenticationMethodHTTPBasic.
  * @returns The authentication type provided.
  */
- (NSString *) providedAuthenticationMethod;

/** Each implementation performs the works specific to their authentication type in this method, authorizing the specified request. 
 *  @param urlRequest the NSMutableURLRequest to authorize
 */
- (void) authorizeRequest:(NSMutableURLRequest *)urlRequest;

/** If appropriate for the authentication type, an auth provider implementation may return an NSURLCredential from this method. 
 *  @returns An instance of NSURLCredential
 */
- (NSURLCredential *) credentialForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end

// import known auth providers

#import "CMBasicAuthProvider.h"
#import "CMServerTrustAuthProvider.h"
#import "CMClientCertificateAuthProvider.h"
#import "CMOAuth2AuthProvider.h"
#import "CMS3AuthProvider.h"
