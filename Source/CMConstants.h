//
//  CMConstants.h
//  Cumulus
//
//  Created by John Clayton on 9/1/11.
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
 * DISCLAIMED. IN NO EVENT SHALL THE ICONFACTORY BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 * LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import <Foundation/Foundation.h>


#ifdef DEBUG
	#ifdef CumulusLoggingOn
		#define RCLog(fmt,...) NSLog(fmt, ##__VA_ARGS__ )
	#else
		#define RCLog(fmt,...) [Cumulus log:fmt, ##__VA_ARGS__ ]
	#endif
#else
	#define RCLog(fmt,...) 
#endif

#if TARGET_OS_IPHONE
	#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 60000
		#define kCumulusARCHandlesDispatchObjects 1
	#else
		#define kCumulusARCHandlesDispatchObjects 0
	#endif
#else
	#if __MAC_OS_X_VERSION_MIN_REQUIRED >= 1080
		#define kCumulusARCHandlesDispatchObjects 1
	#else
		#define kCumulusARCHandlesDispatchObjects 0
	#endif
#endif


#if kCumulusARCHandlesDispatchObjects
	#ifdef dispatch_release
		#undef dispatch_release
	#endif
	#define dispatch_release(object)
#endif

extern NSString *kCumulusErrorDomain;
extern NSString *kCumulusHTTPStatusCodeErrorKey;

enum  {
	kCumulusErrorCodeErrorProcessingResponse	= 1000,
	kCumulusErrorCodeErrorCreatingTempFile		= 1001,
	kCumulusErrorCodeErrorMismatchedChunkSize	= 1002,
	kCumulusErrorCodeErrorOutOfOrderChunks		= 1003
};

extern NSString *kCumulusHTTPMethodGET;
extern NSString *kCumulusHTTPMethodPOST;
extern NSString *kCumulusHTTPMethodPUT;
extern NSString *kCumulusHTTPMethodDELETE;
extern NSString *kCumulusHTTPMethodHEAD;

extern NSString *kCumulusHTTPHeaderAccept;
extern NSString *kCumulusHTTPHeaderContentType;
extern NSString *kCumulusHTTPHeaderContentLength;
extern NSString *kCumulusHTTPHeaderAuthorization;
extern NSString *kCumulusHTTPHeaderContentDisposition;
extern NSString *kCumulusHTTPHeaderETag;
extern NSString *kCumulusHTTPHeaderLastModified;
extern NSString *kCumulusHTTPHeaderRange;
extern NSString *kCumulusHTTPHeaderIfRange;
extern NSString *kCumulusHTTPHeaderContentRange;

extern NSString *kCumulusProgressInfoKeyURL;
extern NSString *kCumulusProgressInfoKeyTempFileURL;
extern NSString *kCumulusProgressInfoKeyFilename;
extern NSString *kCumulusProgressInfoKeyProgress;

extern NSString *kCumulusCachesDirectoryName;



// HTTP Status Codes (so we don't make silly mistakes :)

#define kHTTPStatusCanceled 0


#define kHTTPStatusContinue 100
#define kHTTPStatusSwitchingProtocols 101


#define kHTTPStatusOk 200
#define kHTTPStatusCreated 201
#define kHTTPStatusAccepted 202
#define kHTTPStatusNonAuthoritative 203
#define kHTTPStatusNoContent 204
#define kHTTPStatusResetContent 205
#define kHTTPStatusPartialContent 206

#define kHTTPStatusMultipleChoices 300
#define kHTTPStatusMovedPermanently 301
#define kHTTPStatusFound 302
#define kHTTPStatusSeeOther 303
#define kHTTPStatusNotModified 304
#define kHTTPStatusUseProxy 305
#define kHTTPStatusSwitchProxy 306
#define kHTTPStatusTemporaryRedirect 307
#define kHTTPStatusResumeIncomplete 308

#define kHTTPStatusBadRequest 400
#define kHTTPStatusUnauthorized 401
#define kHTTPStatusPaymentRequired 402
#define kHTTPStatusForbidden 403
#define kHTTPStatusNotFound 404
#define kHTTPStatusMethodNotAllowed 405
#define kHTTPStatusNotAcceptable 406
#define kHTTPStatusProxyAuthenticationRequired 407
#define kHTTPStatusRequestTimeout 408
#define kHTTPStatusConflict 409
#define kHTTPStatusGone 410
#define kHTTPStatusLengthRequired 411
#define kHTTPStatusPreconditionFailed 412
#define kHTTPStatusRequestEntityTooLarge 413
#define kHTTPStatusRequestURITooLong 414
#define kHTTPStatusUnsupportedMediaType 415
#define kHTTPStatusRequestRangeNotSatisfied 416
#define kHTTPStatusExpectationFailed 417
#define kHTTPStatusUnprocessableEntity 422

#define kHTTPStatusInternalServerError 500
#define kHTTPStatusNotImplemented 501
#define kHTTPStatusBadGateway 502
#define kHTTPStatusServiceUnavailable 503
#define kHTTPStatusGatewayTimeout 504
#define kHTTPStatusVersionNotSupported 505
