//
//  RCResponse.h
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

#import <Foundation/Foundation.h>

@class RCRequest;

@interface RCResponse : NSObject {
    
}

@property (nonatomic, strong) RCRequest *request;
@property (nonatomic, readonly) NSInteger status;
@property (nonatomic, readonly) NSDictionary *headers;
@property (nonatomic, readonly) NSString *body;
@property (nonatomic, readonly) id result;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) BOOL success; ///< @return YES if #error is nil and #wasSuccessful returns YES (status is in the range 200-299).

- (id)initWithRequest:(RCRequest *)request;


/** Specific codes */

- (BOOL) isContinue; // 100
- (BOOL) isSwitchingProtocols; // 101


- (BOOL) isOk; // 200
- (BOOL) isCreated; // 201
- (BOOL) isAccepted; // 202
- (BOOL) isNonAuthoritative; // 203
- (BOOL) isNoContent; // 204
- (BOOL) isResetContent; // 205
- (BOOL) isPartialContent; // 206

- (BOOL) isMultipleChoices; // 300
- (BOOL) isMovedPermanently; // 301
- (BOOL) isFound; // 302
- (BOOL) isSeeOther; // 303
- (BOOL) isNotModified; // 304
- (BOOL) isUseProxy; // 305
- (BOOL) isSwitchProxy; // 306
- (BOOL) isTemporaryRedirect; // 307
- (BOOL) isResumeIncomplete; // 308

- (BOOL) isBadRequest; // 400
- (BOOL) isUnauthorized; // 401
- (BOOL) isPaymentRequired; // 402
- (BOOL) isForbidden; // 403
- (BOOL) isNotFound; // 404
- (BOOL) isMethodNotAllowed; // 405
- (BOOL) isNotAcceptable; // 406
- (BOOL) isProxyAuthenticationRequired; // 407
- (BOOL) isRequestTimeout; // 408
- (BOOL) isConflict; // 409
- (BOOL) isGone; // 410
- (BOOL) isLengthRequired; // 411
- (BOOL) isPreconditionFailed; // 412
- (BOOL) isRequestEntityTooLarge; // 413
- (BOOL) isRequestURITooLong; // 414
- (BOOL) isUnsupportedMediaType; // 415
- (BOOL) isRequestRangeNotSatisfied; // 416
- (BOOL) isExpectationFailed; // 417
- (BOOL) isUnprocessableEntity; // 422

- (BOOL) isInternalServerError; // 500
- (BOOL) isNotImplemented; // 501
- (BOOL) isBadGateway; // 502
- (BOOL) isServiceUnavailable; // 503
- (BOOL) isGatewayTimeout; // 504
- (BOOL) isHTTPVersionNotSupported; // 505


/** Ranges of codes */

- (BOOL) wasInformational; // 100's
- (BOOL) wasSuccessful; // 200's
- (BOOL) wasRedirect; // 300's
- (BOOL) wasClientErrror; // 400's
- (BOOL) wasServerError; // 500's



@end





