//
//  CMResponse.h
//  Cumulus
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

#import "CMTypes.h"

@class CMRequest;


/** CMResponse contains a pointer back to the CMRequest that generated it, as well as numerous conveniences that allow quick introspection of the HTTP response and any transformed results or NSError objects. */
@interface CMResponse : NSObject {
    
}

/** @name Response Information */

@property (nonatomic, strong) CMRequest *request;

/** The HTTP status of the response. */
@property (nonatomic, readonly) NSInteger status;

/** The HTTP response headers. */
@property (nonatomic, readonly) NSDictionary *headers;

/** The entity identifier sent back by the server. */
@property (nonatomic, readonly) NSString *ETag;

/** The last modified date of the selected content as sent by the server. 
 *  @returns The last modified date or nil if the server did not report one.
 */
@property (nonatomic, readonly) NSDate *lastModified;

/** The expected length of the response body reported by the server. 
 *  @discussion If there is a 'Content-Length' response header, its value is used to represent this attribute. Otherwise, if there was a 'Content-Range' header, the difference between the start and end bytes is returned. If it is not possible to calculate contentLength by either method (such as when the response reflects streamed content), NSURLResponseUnknownLength is returned.
 *  @returns The content length or NSURLResponseUnknownLength.
 */
@property (nonatomic, readonly) long long expectedContentLength;

/** The expected range of the selected content to be sent back by the server in response to a range request.
 *  @discussion When the server sends back part of the selected content it includes a 'Content-Range' header with a value similar to: 'bytes 0-10000/50000, which corresponds the start and end of the range over the total bytes of the content. This property returns each of the three distinct data points in the location,length and contentLength of a CMContentRange.
 *  @note If there was no 'Content-Range' header, the returned range will have a location of kCFNotFound.
 */
@property (nonatomic, readonly) CMContentRange expectedContentRange;

/** The total bytes of the selected content as reported by the server, regardless of any range being returned in the current response. 
 *  @discussion  If part of the selected content was returned in response to a range request expectedContentRange.contentLength is returned. Otherwise, expectedContentLength is returned.
 */
@property (nonatomic, readonly) long long totalContentLength;

/** @see [CMRequest  responseBody]. */
@property (nonatomic, readonly) NSString *body;

/** @see [CMRequest  result]. */
@property (nonatomic, readonly) id result;

/** Whether the request received all the content in the response it was expecting. */
@property (nonatomic, readonly) BOOL wasComplete;

/** Either the request.error or a generic error constructed around an unsuccessful HTTP status if the request did not contain an error. 
 *  @returns an NSError or nil
 */
@property (nonatomic, readonly) NSError *error;

/** @deprecated Use wasSuccessful instead. */
@property (nonatomic, readonly) BOOL success DEPRECATED_ATTRIBUTE;

/** This is the primary mechanism for quickly determining the success or failure of a request.
 *  @returns YES if error is nil and HTTPSuccessful returns YES (status is in the range 200-299).
 */
@property (nonatomic, readonly) BOOL wasSuccessful;

/** @see wasSuccessful */
@property (nonatomic, readonly) BOOL wasUnsuccessful;

/** If the response contains an error that is considered transient (connection lost, DNS failed, bad gateway, etc) then this propery can be used to determine if another request would be useful. */
@property (nonatomic, readonly) BOOL shouldRetry;

/** @see HTTPNotModified */
@property (nonatomic, readonly) BOOL wasNotModified;


/** @name Creating requests. */


- (id)initWithRequest:(CMRequest *)request;


/** @name Tests for Common NSURLErrorDomain errors. */


/// NSErrorBadURL (-1000)
- (BOOL) ErrorBadURL;
/// NSErrorTimedOut (-1001)
- (BOOL) ErrorTimedOut;
/// NSErrorUnsupportedURL (-1002)
- (BOOL) ErrorUnsupportedURL;
/// NSErrorCannotFindHost (-1003)
- (BOOL) ErrorCannotFindHost;
/// NSErrorCannotConnectToHost (-1004)
- (BOOL) ErrorCannotConnectToHost;
/// NSErrorDataLengthExceedsMaximum (-1103)
- (BOOL) ErrorDataLengthExceedsMaximum;
/// NSErrorNetworkConnectionLost (-1005)
- (BOOL) ErrorNetworkConnectionLost;
/// NSErrorDNSLookupFailed (-1006)
- (BOOL) ErrorDNSLookupFailed;
/// NSErrorHTTPTooManyRedirects (-1007)
- (BOOL) ErrorHTTPTooManyRedirects;
/// NSErrorResourceUnavailable (-1008)
- (BOOL) ErrorResourceUnavailable;
/// NSErrorNotConnectedToInternet (-1009)
- (BOOL) ErrorNotConnectedToInternet;
/// NSErrorRedirectToNonExistentLocation (-1010)
- (BOOL) ErrorRedirectToNonExistentLocation;
/// NSErrorBadServerResponse (-1011)
- (BOOL) ErrorBadServerResponse;
/// NSErrorUserCancelledAuthentication (-1012)
- (BOOL) ErrorUserCancelledAuthentication;
/// NSErrorUserAuthenticationRequired (-1013)
- (BOOL) ErrorUserAuthenticationRequired;
/// NSErrorZeroByteResource (-1014)
- (BOOL) ErrorZeroByteResource;
/// NSErrorCannotDecodeRawData (-1015)
- (BOOL) ErrorCannotDecodeRawData;
/// NSErrorCannotDecodeContentData (-1016)
- (BOOL) ErrorCannotDecodeContentData;
/// NSErrorCannotParseResponse (-1017)
- (BOOL) ErrorCannotParseResponse;
/// NSErrorInternationalRoamingOff (-1018)
- (BOOL) ErrorInternationalRoamingOff;
/// NSErrorCallIsActive (-1019)
- (BOOL) ErrorCallIsActive;
/// NSErrorDataNotAllowed (-1020)
- (BOOL) ErrorDataNotAllowed;
/// NSErrorRequestBodyStreamExhausted (-1021)
- (BOOL) ErrorRequestBodyStreamExhausted;
/// NSErrorFileDoesNotExist (-1100)
- (BOOL) ErrorFileDoesNotExist;
/// NSErrorFileIsDirectory (-1101)
- (BOOL) ErrorFileIsDirectory;
/// NSErrorNoPermissionsToReadFile (-1102)
- (BOOL) ErrorNoPermissionsToReadFile;
/// NSErrorSecureConnectionFailed (-1200)
- (BOOL) ErrorSecureConnectionFailed;
/// NSErrorServerCertificateHasBadDate (-1201)
- (BOOL) ErrorServerCertificateHasBadDate;
/// NSErrorServerCertificateUntrusted (-1202)
- (BOOL) ErrorServerCertificateUntrusted;
/// NSErrorServerCertificateHasUnknownRoot (-1203)
- (BOOL) ErrorServerCertificateHasUnknownRoot;
/// NSErrorServerCertificateNotYetValid (-1204)
- (BOOL) ErrorServerCertificateNotYetValid;
/// NSErrorClientCertificateRejected (-1205)
- (BOOL) ErrorClientCertificateRejected;
/// NSErrorClientCertificateRequired (-1206)
- (BOOL) ErrorClientCertificateRequired;
/// NSErrorCannotLoadFromNetwork (-2000)
- (BOOL) ErrorCannotLoadFromNetwork;
/// NSErrorCannotCreateFile (-3000)
- (BOOL) ErrorCannotCreateFile;
/// NSErrorCannotOpenFile (-3001)
- (BOOL) ErrorCannotOpenFile;
/// NSErrorCannotCloseFile (-3002)
- (BOOL) ErrorCannotCloseFile;
/// NSErrorCannotWriteToFile (-3003)
- (BOOL) ErrorCannotWriteToFile;
/// NSErrorCannotRemoveFile (-3004)
- (BOOL) ErrorCannotRemoveFile;
/// NSErrorCannotMoveFile (-3005)
- (BOOL) ErrorCannotMoveFile;
/// NSErrorDownloadDecodingFailedMidStream (-3006)
- (BOOL) ErrorDownloadDecodingFailedMidStream;
/// NSErrorDownloadDecodingFailedToComplete (-3007)
- (BOOL) ErrorDownloadDecodingFailedToComplete;



/** @name Tests for Specific HTTP response codes */

/// HTTP  0
- (BOOL) HTTPCanceled;

/// HTTP  100
- (BOOL) HTTPContinue;
/// HTTP  101
- (BOOL) HTTPSwitchingProtocols;


/// HTTP  200
- (BOOL) HTTPOk;
/// HTTP  201
- (BOOL) HTTPCreated;
/// HTTP  202
- (BOOL) HTTPAccepted;
/// HTTP  203
- (BOOL) HTTPNonAuthoritative;
/// HTTP  204
- (BOOL) HTTPNoContent;
/// HTTP  205
- (BOOL) HTTPResetContent;
/// HTTP  206
- (BOOL) HTTPPartialContent;

/// HTTP  300
- (BOOL) HTTPMultipleChoices;
/// HTTP  301
- (BOOL) HTTPMovedPermanently;
/// HTTP  302
- (BOOL) HTTPFound;
/// HTTP  303
- (BOOL) HTTPSeeOther;
/// HTTP  304
- (BOOL) HTTPNotModified;
/// HTTP  305
- (BOOL) HTTPUseProxy;
/// HTTP  306
- (BOOL) HTTPSwitchProxy;
/// HTTP  307
- (BOOL) HTTPTemporaryRedirect;
/// HTTP  308
- (BOOL) HTTPResumeIncomplete;

/// HTTP  400
- (BOOL) HTTPBadRequest;
/// HTTP  401
- (BOOL) HTTPUnauthorized;
/// HTTP  402
- (BOOL) HTTPPaymentRequired;
/// HTTP  403
- (BOOL) HTTPForbidden;
/// HTTP  404
- (BOOL) HTTPNotFound;
/// HTTP  405
- (BOOL) HTTPMethodNotAllowed;
/// HTTP  406
- (BOOL) HTTPNotAcceptable;
/// HTTP  407
- (BOOL) HTTPProxyAuthenticationRequired;
/// HTTP  408
- (BOOL) HTTPRequestTimeout;
/// HTTP  409
- (BOOL) HTTPConflict;
/// HTTP  410
- (BOOL) HTTPGone;
/// HTTP  411
- (BOOL) HTTPLengthRequired;
/// HTTP  412
- (BOOL) HTTPPreconditionFailed;
/// HTTP  413
- (BOOL) HTTPRequestEntityTooLarge;
/// HTTP  414
- (BOOL) HTTPRequestURITooLong;
/// HTTP  415
- (BOOL) HTTPUnsupportedMediaType;
/// HTTP  416
- (BOOL) HTTPRequestRangeNotSatisfied;
/// HTTP  417
- (BOOL) HTTPExpectationFailed;
/// HTTP  422
- (BOOL) HTTPUnprocessableEntity;

/// HTTP  500
- (BOOL) HTTPInternalServerError;
/// HTTP  501
- (BOOL) HTTPNotImplemented;
/// HTTP  502
- (BOOL) HTTPBadGateway;
/// HTTP  503
- (BOOL) HTTPServiceUnavailable;
/// HTTP  504
- (BOOL) HTTPGatewayTimeout;
/// HTTP  505
- (BOOL) HTTPVersionNotSupported;


/** @name Tests for Ranges of HTTP response codes */

/// HTTP  100's
- (BOOL) HTTPInformational;
/// HTTP  200's
- (BOOL) HTTPSuccessful;
/// HTTP  300's
- (BOOL) HTTPRedirect;
/// HTTP  400's
- (BOOL) HTTPClientErrror;
/// HTTP  500's
- (BOOL) HTTPServerError;



@end





