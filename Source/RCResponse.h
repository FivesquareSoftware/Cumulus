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


/** RCResponse contains a pointer back to the RCRequest that generated it, as well as numeroud conveniences that allow introspection of the HTTP response and any transformed results or NSError objects. */
@interface RCResponse : NSObject {
    
}

@property (nonatomic, strong) RCRequest *request;
@property (nonatomic, readonly) NSInteger status;
@property (nonatomic, readonly) NSDictionary *headers;
@property (nonatomic, readonly) NSString *body;
@property (nonatomic, readonly) id result;
@property (nonatomic, readonly) NSError *error;
@property (nonatomic, readonly) BOOL success; ///< @return YES if #error is nil and #wasSuccessful returns YES (status is in the range 200-299). This is the primary mechanism for quickly determining the success or failure of a request.

- (id)initWithRequest:(RCRequest *)request;


/** Some common NSURLErrorDomain error tests. */


- (BOOL) ErrorBadURL; // -1000
- (BOOL) ErrorTimedOut; // -1001
- (BOOL) ErrorUnsupportedURL; // -1002
- (BOOL) ErrorCannotFindHost; // -1003
- (BOOL) ErrorCannotConnectToHost; // -1004
- (BOOL) ErrorDataLengthExceedsMaximum; // -1103
- (BOOL) ErrorNetworkConnectionLost; // -1005
- (BOOL) ErrorDNSLookupFailed; // -1006
- (BOOL) ErrorHTTPTooManyRedirects; // -1007
- (BOOL) ErrorResourceUnavailable; // -1008
- (BOOL) ErrorNotConnectedToInternet; // -1009
- (BOOL) ErrorRedirectToNonExistentLocation; // -1010
- (BOOL) ErrorBadServerResponse; // -1011
- (BOOL) ErrorUserCancelledAuthentication; // -1012
- (BOOL) ErrorUserAuthenticationRequired; // -1013
- (BOOL) ErrorZeroByteResource; // -1014
- (BOOL) ErrorCannotDecodeRawData; // -1015
- (BOOL) ErrorCannotDecodeContentData; // -1016
- (BOOL) ErrorCannotParseResponse; // -1017
- (BOOL) ErrorInternationalRoamingOff; // -1018
- (BOOL) ErrorCallIsActive; // -1019
- (BOOL) ErrorDataNotAllowed; // -1020
- (BOOL) ErrorRequestBodyStreamExhausted; // -1021
- (BOOL) ErrorFileDoesNotExist; // -1100
- (BOOL) ErrorFileIsDirectory; // -1101
- (BOOL) ErrorNoPermissionsToReadFile; // -1102
- (BOOL) ErrorSecureConnectionFailed; // -1200
- (BOOL) ErrorServerCertificateHasBadDate; // -1201
- (BOOL) ErrorServerCertificateUntrusted; // -1202
- (BOOL) ErrorServerCertificateHasUnknownRoot; // -1203
- (BOOL) ErrorServerCertificateNotYetValid; // -1204
- (BOOL) ErrorClientCertificateRejected; // -1205
- (BOOL) ErrorClientCertificateRequired; // -1206
- (BOOL) ErrorCannotLoadFromNetwork; // -2000
- (BOOL) ErrorCannotCreateFile; // -3000
- (BOOL) ErrorCannotOpenFile; // -3001
- (BOOL) ErrorCannotCloseFile; // -3002
- (BOOL) ErrorCannotWriteToFile; // -3003
- (BOOL) ErrorCannotRemoveFile; // -3004
- (BOOL) ErrorCannotMoveFile; // -3005
- (BOOL) ErrorDownloadDecodingFailedMidStream; // -3006
- (BOOL) ErrorDownloadDecodingFailedToComplete; // -3007



/** Specific HTTP response codes */

- (BOOL) HTTPContinue; // 100
- (BOOL) HTTPSwitchingProtocols; // 101


- (BOOL) HTTPOk; // 200
- (BOOL) HTTPCreated; // 201
- (BOOL) HTTPAccepted; // 202
- (BOOL) HTTPNonAuthoritative; // 203
- (BOOL) HTTPNoContent; // 204
- (BOOL) HTTPResetContent; // 205
- (BOOL) HTTPPartialContent; // 206

- (BOOL) HTTPMultipleChoices; // 300
- (BOOL) HTTPMovedPermanently; // 301
- (BOOL) HTTPFound; // 302
- (BOOL) HTTPSeeOther; // 303
- (BOOL) HTTPNotModified; // 304
- (BOOL) HTTPUseProxy; // 305
- (BOOL) HTTPSwitchProxy; // 306
- (BOOL) HTTPTemporaryRedirect; // 307
- (BOOL) HTTPResumeIncomplete; // 308

- (BOOL) HTTPBadRequest; // 400
- (BOOL) HTTPUnauthorized; // 401
- (BOOL) HTTPPaymentRequired; // 402
- (BOOL) HTTPForbidden; // 403
- (BOOL) HTTPNotFound; // 404
- (BOOL) HTTPMethodNotAllowed; // 405
- (BOOL) HTTPNotAcceptable; // 406
- (BOOL) HTTPProxyAuthenticationRequired; // 407
- (BOOL) HTTPRequestTimeout; // 408
- (BOOL) HTTPConflict; // 409
- (BOOL) HTTPGone; // 410
- (BOOL) HTTPLengthRequired; // 411
- (BOOL) HTTPPreconditionFailed; // 412
- (BOOL) HTTPRequestEntityTooLarge; // 413
- (BOOL) HTTPRequestURITooLong; // 414
- (BOOL) HTTPUnsupportedMediaType; // 415
- (BOOL) HTTPRequestRangeNotSatisfied; // 416
- (BOOL) HTTPExpectationFailed; // 417
- (BOOL) HTTPUnprocessableEntity; // 422

- (BOOL) HTTPInternalServerError; // 500
- (BOOL) HTTPNotImplemented; // 501
- (BOOL) HTTPBadGateway; // 502
- (BOOL) HTTPServiceUnavailable; // 503
- (BOOL) HTTPGatewayTimeout; // 504
- (BOOL) HTTPVersionNotSupported; // 505


/** Ranges of HTTP response codes */

- (BOOL) HTTPInformational; // 100's
- (BOOL) HTTPSuccessful; // 200's
- (BOOL) HTTPRedirect; // 300's
- (BOOL) HTTPClientErrror; // 400's
- (BOOL) HTTPServerError; // 500's



@end





