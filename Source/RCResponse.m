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
		if([self ErrorUserCancelledAuthentication]) {
			status_ = 401;
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
	return self.error == nil && [self HTTPSuccessful];
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
	return self.status == 100;
}

- (BOOL) HTTPSwitchingProtocols {
	return self.status == 101;
}



#pragma mark -  -200's

- (BOOL) HTTPOk {
	return self.status == 200;
}

- (BOOL) HTTPCreated {
	return self.status == 201;
}

- (BOOL) HTTPAccepted {
	return self.status == 202;
}

- (BOOL) HTTPNonAuthoritative {
	return self.status == 203;
}

- (BOOL) HTTPNoContent {
	return self.status == 204;
}

- (BOOL) HTTPResetContent {
	return self.status == 205;
}

- (BOOL) HTTPPartialContent {
	return self.status == 206;
}


#pragma mark -  -300's


- (BOOL) HTTPMultipleChoices {
	return self.status == 300;
}

- (BOOL) HTTPMovedPermanently {
	return self.status == 301;
}

- (BOOL) HTTPFound {
	return self.status == 302;
}

- (BOOL) HTTPSeeOther {
	return self.status == 303;
}

- (BOOL) HTTPNotModified {
	return self.status == 304;
}

- (BOOL) HTTPUseProxy {
	return self.status == 305;
}

- (BOOL) HTTPSwitchProxy {
	return self.status == 306;
}

- (BOOL) HTTPTemporaryRedirect {
	return self.status == 307;
}

- (BOOL) HTTPResumeIncomplete {
	return self.status == 308;
}


#pragma mark -  -400's

- (BOOL) HTTPBadRequest {
	return self.status == 400;
}

- (BOOL) HTTPUnauthorized {
	return self.status == 401;
}

- (BOOL) HTTPPaymentRequired {
	return self.status == 402;
}

- (BOOL) HTTPForbidden {
	return self.status == 403;
}

- (BOOL) HTTPNotFound {
	return self.status == 404;
}

- (BOOL) HTTPMethodNotAllowed {
	return self.status == 405;
}

- (BOOL) HTTPNotAcceptable {
	return self.status == 406;
}

- (BOOL) HTTPProxyAuthenticationRequired {
	return self.status == 407;
}

- (BOOL) HTTPRequestTimeout {
	return self.status == 408;
}

- (BOOL) HTTPConflict {
	return self.status == 409;
}

- (BOOL) HTTPGone {
	return self.status == 410;
}

- (BOOL) HTTPLengthRequired {
	return self.status == 411;
}

- (BOOL) HTTPPreconditionFailed {
	return self.status == 412;
}

- (BOOL) HTTPRequestEntityTooLarge {
	return self.status == 413;
}

- (BOOL) HTTPRequestURITooLong {
	return self.status == 414;
}

- (BOOL) HTTPUnsupportedMediaType {
	return self.status == 415;
}

- (BOOL) HTTPRequestRangeNotSatisfied {
	return self.status == 416;
}

- (BOOL) HTTPExpectationFailed {
	return self.status == 417;
}

- (BOOL) HTTPUnprocessableEntity {
	return self.status == 422;
}


#pragma mark -  -500's

- (BOOL) HTTPInternalServerError {
	return self.status == 500;
}

- (BOOL) HTTPNotImplemented {
	return self.status == 501;
}


- (BOOL) HTTPBadGateway {
	return self.status == 502;
}


- (BOOL) HTTPServiceUnavailable {
	return self.status == 503;
}


- (BOOL) HTTPGatewayTimeout {
	return self.status == 504;
}


- (BOOL) HTTPVersionNotSupported {
	return self.status == 505;
}



// ========================================================================== //

#pragma mark - Status Ranges


- (BOOL) HTTPInformational {
	return self.status >= 100 && self.status < 200;
}

- (BOOL) HTTPSuccessful {
	return self.status >= 200 && self.status < 300;
}

- (BOOL) HTTPRedirect {
	return self.status >= 300 && self.status < 400;
}

- (BOOL) HTTPClientErrror {
	return self.status >= 400 && self.status < 500;
}

- (BOOL) HTTPServerError {
	return self.status >= 500 && self.status < 600;
}




@end
