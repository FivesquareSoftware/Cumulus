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
#import "RCConstants.h"

@implementation RCResponse

// ========================================================================== //

#pragma mark - Properties



@synthesize request=_request;
@synthesize status=_status;
@synthesize error = _error;



@dynamic headers;
- (NSDictionary *) headers {
	return [_request.URLResponse allHeaderFields];
}

- (NSString *) body {
	return _request.responseBody;
} 

- (NSError *) error {
	if (nil == _error) {
		if (NO == [self HTTPSuccessful] && nil == _request.error) {
			NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:
								  [NSString stringWithFormat:@"Received %u HTTP Status code",_status], NSLocalizedDescriptionKey
								  , _request.responseBody, NSLocalizedFailureReasonErrorKey
								  , [_request.URLResponse URL], NSURLErrorFailingURLErrorKey
								  , [NSNumber numberWithInt:_status], kRESTCLientHTTPStatusCodeErrorKey
								  , nil];
			_error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorUnknown userInfo:info];
		}
		else {
			_error = _request.error;
		}
	}
	return _error;
}

- (id) result {
	return _request.result;
}

@dynamic success;
- (BOOL) success {
	return self.error == nil && [self HTTPSuccessful];
}



// ========================================================================== //

#pragma mark - Object



- (id)initWithRequest:(RCRequest *)request {
    self = [super init];
    if (self) {
        _request = request;
		// If user canceled auth, we need to help a bit and set the right status code
		NSError *error = request.error;
		if(error.code == NSURLErrorUserCancelledAuthentication) {
			_status = 401;
		} else {
			_status = [request.URLResponse statusCode];
		}
    }
    return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ (request = %@, status = %d, response.headers = %@, response.body = %@, result = %@, error = %@)"
			,[super description]
			, [_request description]
			, self.status
			, [self.headers description]
			, self.body
			, self.result
			, self.error
			];
}

// ========================================================================== //

#pragma mark - NSURLErrorDomain Tests


- (BOOL) ErrorBadURL {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorBadURL;
}

- (BOOL) ErrorTimedOut {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorTimedOut;
}

- (BOOL) ErrorUnsupportedURL {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorUnsupportedURL;
}

- (BOOL) ErrorCannotFindHost {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotFindHost;
}

- (BOOL) ErrorCannotConnectToHost {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotConnectToHost;
}

- (BOOL) ErrorDataLengthExceedsMaximum {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorDataLengthExceedsMaximum;
}

- (BOOL) ErrorNetworkConnectionLost {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorNetworkConnectionLost;
}

- (BOOL) ErrorDNSLookupFailed {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorDNSLookupFailed;
}

- (BOOL) ErrorHTTPTooManyRedirects {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorHTTPTooManyRedirects;
}

- (BOOL) ErrorResourceUnavailable {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorResourceUnavailable;
}

- (BOOL) ErrorNotConnectedToInternet {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorNotConnectedToInternet;
}

- (BOOL) ErrorRedirectToNonExistentLocation {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorRedirectToNonExistentLocation;
}

- (BOOL) ErrorBadServerResponse {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorBadServerResponse;
}

- (BOOL) ErrorUserCancelledAuthentication {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorUserCancelledAuthentication;
}

- (BOOL) ErrorUserAuthenticationRequired {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorUserAuthenticationRequired;
}

- (BOOL) ErrorZeroByteResource {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorZeroByteResource;
}

- (BOOL) ErrorCannotDecodeRawData {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotDecodeRawData;
}

- (BOOL) ErrorCannotDecodeContentData {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotDecodeContentData;
}

- (BOOL) ErrorCannotParseResponse {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotParseResponse;
}

- (BOOL) ErrorInternationalRoamingOff {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorInternationalRoamingOff;
}

- (BOOL) ErrorCallIsActive {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCallIsActive;
}

- (BOOL) ErrorDataNotAllowed {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorDataNotAllowed;
}

- (BOOL) ErrorRequestBodyStreamExhausted {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorRequestBodyStreamExhausted;
}

- (BOOL) ErrorFileDoesNotExist {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorFileDoesNotExist;
}

- (BOOL) ErrorFileIsDirectory {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorFileIsDirectory;
}

- (BOOL) ErrorNoPermissionsToReadFile {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorNoPermissionsToReadFile;
}

- (BOOL) ErrorSecureConnectionFailed {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorSecureConnectionFailed;
}

- (BOOL) ErrorServerCertificateHasBadDate {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorServerCertificateHasBadDate;
}

- (BOOL) ErrorServerCertificateUntrusted {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorServerCertificateUntrusted;
}

- (BOOL) ErrorServerCertificateHasUnknownRoot {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorServerCertificateHasUnknownRoot;
}

- (BOOL) ErrorServerCertificateNotYetValid {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorServerCertificateNotYetValid;
}

- (BOOL) ErrorClientCertificateRejected {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorClientCertificateRejected;
}

- (BOOL) ErrorClientCertificateRequired {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorClientCertificateRequired;
}

- (BOOL) ErrorCannotLoadFromNetwork {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotLoadFromNetwork;
}

- (BOOL) ErrorCannotCreateFile {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotCreateFile;
}

- (BOOL) ErrorCannotOpenFile {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotOpenFile;
}

- (BOOL) ErrorCannotCloseFile {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotCloseFile;
}

- (BOOL) ErrorCannotWriteToFile {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotWriteToFile;
}

- (BOOL) ErrorCannotRemoveFile {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotRemoveFile;
}

- (BOOL) ErrorCannotMoveFile {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorCannotMoveFile;
}

- (BOOL) ErrorDownloadDecodingFailedMidStream {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorDownloadDecodingFailedMidStream;
}

- (BOOL) ErrorDownloadDecodingFailedToComplete {
	return self.error && [self.error domain] == NSURLErrorDomain && self.error.code == NSURLErrorDownloadDecodingFailedToComplete;
}




// ========================================================================== //

#pragma mark - Status Codes


#pragma mark -  -100's

- (BOOL) HTTPContinue {
	return self.status == kHTTPStatusContinue;
}

- (BOOL) HTTPSwitchingProtocols {
	return self.status == kHTTPStatusSwitchingProtocols;
}



#pragma mark -  -200's

- (BOOL) HTTPOk {
	return self.status == kHTTPStatusOk;
}

- (BOOL) HTTPCreated {
	return self.status == kHTTPStatusCreated;
}

- (BOOL) HTTPAccepted {
	return self.status == kHTTPStatusAccepted;
}

- (BOOL) HTTPNonAuthoritative {
	return self.status == kHTTPStatusNonAuthoritative;
}

- (BOOL) HTTPNoContent {
	return self.status == kHTTPStatusNoContent;
}

- (BOOL) HTTPResetContent {
	return self.status == kHTTPStatusResetContent;
}

- (BOOL) HTTPPartialContent {
	return self.status == kHTTPStatusPartialContent;
}


#pragma mark -  -300's


- (BOOL) HTTPMultipleChoices {
	return self.status == kHTTPStatusMultipleChoices;
}

- (BOOL) HTTPMovedPermanently {
	return self.status == kHTTPStatusMovedPermanently;
}

- (BOOL) HTTPFound {
	return self.status == kHTTPStatusFound;
}

- (BOOL) HTTPSeeOther {
	return self.status == kHTTPStatusSeeOther;
}

- (BOOL) HTTPNotModified {
	return self.status == kHTTPStatusNotModified;
}

- (BOOL) HTTPUseProxy {
	return self.status == kHTTPStatusUseProxy;
}

- (BOOL) HTTPSwitchProxy {
	return self.status == kHTTPStatusSwitchProxy;
}

- (BOOL) HTTPTemporaryRedirect {
	return self.status == kHTTPStatusTemporaryRedirect;
}

- (BOOL) HTTPResumeIncomplete {
	return self.status == kHTTPStatusResumeIncomplete;
}


#pragma mark -  -400's

- (BOOL) HTTPBadRequest {
	return self.status == kHTTPStatusBadRequest;
}

- (BOOL) HTTPUnauthorized {
	return self.status == kHTTPStatusUnauthorized;
}

- (BOOL) HTTPPaymentRequired {
	return self.status == kHTTPStatusPaymentRequired;
}

- (BOOL) HTTPForbidden {
	return self.status == kHTTPStatusForbidden;
}

- (BOOL) HTTPNotFound {
	return self.status == kHTTPStatusNotFound;
}

- (BOOL) HTTPMethodNotAllowed {
	return self.status == kHTTPStatusMethodNotAllowed;
}

- (BOOL) HTTPNotAcceptable {
	return self.status == kHTTPStatusNotAcceptable;
}

- (BOOL) HTTPProxyAuthenticationRequired {
	return self.status == kHTTPStatusProxyAuthenticationRequired;
}

- (BOOL) HTTPRequestTimeout {
	return self.status == kHTTPStatusRequestTimeout;
}

- (BOOL) HTTPConflict {
	return self.status == kHTTPStatusConflict;
}

- (BOOL) HTTPGone {
	return self.status == kHTTPStatusGone;
}

- (BOOL) HTTPLengthRequired {
	return self.status == kHTTPStatusLengthRequired;
}

- (BOOL) HTTPPreconditionFailed {
	return self.status == kHTTPStatusPreconditionFailed;
}

- (BOOL) HTTPRequestEntityTooLarge {
	return self.status == kHTTPStatusRequestEntityTooLarge;
}

- (BOOL) HTTPRequestURITooLong {
	return self.status == kHTTPStatusRequestURITooLong;
}

- (BOOL) HTTPUnsupportedMediaType {
	return self.status == kHTTPStatusUnsupportedMediaType;
}

- (BOOL) HTTPRequestRangeNotSatisfied {
	return self.status == kHTTPStatusRequestRangeNotSatisfied;
}

- (BOOL) HTTPExpectationFailed {
	return self.status == kHTTPStatusExpectationFailed;
}

- (BOOL) HTTPUnprocessableEntity {
	return self.status == kHTTPStatusUnprocessableEntity;
}


#pragma mark -  -500's

- (BOOL) HTTPInternalServerError {
	return self.status == kHTTPStatusInternalServerError;
}

- (BOOL) HTTPNotImplemented {
	return self.status == kHTTPStatusNotImplemented;
}


- (BOOL) HTTPBadGateway {
	return self.status == kHTTPStatusBadGateway;
}


- (BOOL) HTTPServiceUnavailable {
	return self.status == kHTTPStatusServiceUnavailable;
}


- (BOOL) HTTPGatewayTimeout {
	return self.status == kHTTPStatusGatewayTimeout;
}


- (BOOL) HTTPVersionNotSupported {
	return self.status == kHTTPStatusVersionNotSupported;
}



// ========================================================================== //

#pragma mark - Status Ranges


- (BOOL) HTTPInformational {
	return self.status >= kHTTPStatusContinue && self.status < kHTTPStatusOk;
}

- (BOOL) HTTPSuccessful {
	return self.status >= kHTTPStatusOk && self.status < kHTTPStatusMultipleChoices;
}

- (BOOL) HTTPRedirect {
	return self.status >= kHTTPStatusMultipleChoices && self.status < kHTTPStatusBadRequest;
}

- (BOOL) HTTPClientErrror {
	return self.status >= kHTTPStatusBadRequest && self.status < kHTTPStatusInternalServerError;
}

- (BOOL) HTTPServerError {
	return self.status >= kHTTPStatusInternalServerError && self.status < 600;
}




@end
