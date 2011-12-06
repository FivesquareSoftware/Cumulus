//
//  RCResponse.m
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

#import "RCResponse.h"

#import "RCRequest.h"

@implementation RCResponse

// ========================================================================== //

#pragma mark - Properties



@synthesize request=request_;
@synthesize status=status_;

- (NSInteger) status {
	if(status_ == NSIntegerMax) {
		if(self.error) {
			if([self.error domain] == NSURLErrorDomain) {
				switch ([self.error code]) {
					case NSURLErrorUserCancelledAuthentication:
						status_ = 401;
						break;
					default:
						break;
				}
			}
		} else {
			status_ = [request_.URLResponse statusCode];
		}
	}
	return status_;
}

@dynamic headers;
- (NSDictionary *) headers {
	return [request_.URLResponse allHeaderFields];
}

- (NSString *) body {
	return request_.responseBody;
} 

- (NSError *) error {
	return request_.error;
}

- (id) result {
	return request_.result;
}

@dynamic success;
- (BOOL) success {
	return self.error == nil && [self wasSuccessful];
}



// ========================================================================== //

#pragma mark - Object



- (id)initWithRequest:(RCRequest *)request {
    self = [super init];
    if (self) {
        request_ = request;
        status_ = NSIntegerMax;
    }
    return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ (request = %@, status = %d, response.headers = %@, response.body = %@, result = %@, error = %@)"
			,[super description]
			, [request_ description]
			, self.status
			, [self.headers description]
			, self.body
			, self.result
			, self.error
			];
}



// ========================================================================== //

#pragma mark - Status Codes


#pragma mark -  -100's

- (BOOL) isContinue {
	return self.status == 100;
}

- (BOOL) isSwitchingProtocols {
	return self.status == 101;
}



#pragma mark -  -200's

- (BOOL) isOk {
	return self.status == 200;
}

- (BOOL) isCreated {
	return self.status == 201;
}

- (BOOL) isAccepted {
	return self.status == 202;
}

- (BOOL) isNonAuthoritative {
	return self.status == 203;
}

- (BOOL) isNoContent {
	return self.status == 204;
}

- (BOOL) isResetContent {
	return self.status == 205;
}

- (BOOL) isPartialContent {
	return self.status == 206;
}


#pragma mark -  -300's


- (BOOL) isMultipleChoices {
	return self.status == 300;
}

- (BOOL) isMovedPermanently {
	return self.status == 301;
}

- (BOOL) isFound {
	return self.status == 302;
}

- (BOOL) isSeeOther {
	return self.status == 303;
}

- (BOOL) isNotModified {
	return self.status == 304;
}

- (BOOL) isUseProxy {
	return self.status == 305;
}

- (BOOL) isSwitchProxy {
	return self.status == 306;
}

- (BOOL) isTemporaryRedirect {
	return self.status == 307;
}

- (BOOL) isResumeIncomplete {
	return self.status == 308;
}


#pragma mark -  -400's

- (BOOL) isBadRequest {
	return self.status == 400;
}

- (BOOL) isUnauthorized {
	return self.status == 401;
}

- (BOOL) isPaymentRequired {
	return self.status == 402;
}

- (BOOL) isForbidden {
	return self.status == 403;
}

- (BOOL) isNotFound {
	return self.status == 404;
}

- (BOOL) isMethodNotAllowed {
	return self.status == 405;
}

- (BOOL) isNotAcceptable {
	return self.status == 406;
}

- (BOOL) isProxyAuthenticationRequired {
	return self.status == 407;
}

- (BOOL) isRequestTimeout {
	return self.status == 408;
}

- (BOOL) isConflict {
	return self.status == 409;
}

- (BOOL) isGone {
	return self.status == 410;
}

- (BOOL) isLengthRequired {
	return self.status == 411;
}

- (BOOL) isPreconditionFailed {
	return self.status == 412;
}

- (BOOL) isRequestEntityTooLarge {
	return self.status == 413;
}

- (BOOL) isRequestURITooLong {
	return self.status == 414;
}

- (BOOL) isUnsupportedMediaType {
	return self.status == 415;
}

- (BOOL) isRequestRangeNotSatisfied {
	return self.status == 416;
}

- (BOOL) isExpectationFailed {
	return self.status == 417;
}

- (BOOL) isUnprocessableEntity {
	return self.status == 422;
}


#pragma mark -  -500's

- (BOOL) isInternalServerError {
	return self.status == 500;
}

- (BOOL) isNotImplemented {
	return self.status == 501;
}


- (BOOL) isBadGateway {
	return self.status == 502;
}


- (BOOL) isServiceUnavailable {
	return self.status == 503;
}


- (BOOL) isGatewayTimeout {
	return self.status == 504;
}


- (BOOL) isHTTPVersionNotSupported {
	return self.status == 505;
}



// ========================================================================== //

#pragma mark - Status Ranges


- (BOOL) wasInformational {
	return self.status >= 100 && self.status < 200;
}

- (BOOL) wasSuccessful {
	return self.status >= 200 && self.status < 300;
}

- (BOOL) wasRedirect {
	return self.status >= 300 && self.status < 400;
}

- (BOOL) wasClientErrror {
	return self.status >= 400 && self.status < 500;
}

- (BOOL) wasServerError {
	return self.status >= 500 && self.status < 600;
}




@end
