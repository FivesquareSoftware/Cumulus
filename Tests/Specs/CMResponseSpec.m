//
//	CMResponseSpec.m
//	Cumulus
//
//	Created by John Clayton on 10/15/11.
//	Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResponseSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation CMResponseSpec


+ (NSString *)description {
	return @"Response Internals";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
	// set up resources common to all examples here
	NSString *resourceImagePath = [[NSBundle mainBundle] pathForResource:@"t_hero" ofType:@"png"];
	
	NSFileManager *fm = [NSFileManager new];
	NSError *error = nil;
	NSDictionary *attributes = [fm attributesOfItemAtPath:resourceImagePath error:&error];
	_heroBytes = (long long)[attributes fileSize];
}

- (void)beforeEach {
	// set up resources that need to be initialized before each example here
	self.service = [CMResource withURL:kTestServerHost];
	self.service.cachePolicy = NSURLRequestReloadIgnoringCacheData;
	
	self.endpoint = [self.service resource:@"test/response_codes"];
}

- (void)afterEach {
	// tear down resources specific to each example here
}


- (void)afterAll {
	// tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs



#pragma mark - - State and Derived Values

- (void) shouldBeSuccessful {
	CMResource *resource = [self.endpoint resource:@"successful"];
	CMResponse *response = [resource get];
	STAssertTrue([response wasSuccessful], @"Response#wasSuccessful should be true: %@",response);
}

- (void) shouldBeUnsuccessful {
	CMResource *resource = [self.endpoint resource:@"informational"];
	CMResponse *response = [resource get];
	STAssertTrue([response wasUnsuccessful], @"Response#wasUnsuccessful should be true for informational: %@",response);
	
	resource = [self.endpoint resource:@"redirect"];
	response = [resource get];
	STAssertTrue([response wasUnsuccessful], @"Response#wasUnsuccessful should be true for redirect: %@",response);
	
	resource = [self.endpoint resource:@"clienterrror"];
	response = [resource get];
	STAssertTrue([response wasUnsuccessful], @"Response#wasUnsuccessful should be true for clienterrror: %@",response);
	
	resource = [self.endpoint resource:@"servererror"];
	response = [resource get];
	STAssertTrue([response wasUnsuccessful], @"Response#wasUnsuccessful should be true for servererror: %@",response);
}

- (void) shouldNotBeUnsuccessful {
	CMResource *resource = [self.endpoint resource:@"successful"];
	CMResponse *response = [resource get];
	STAssertFalse([response wasUnsuccessful], @"Response#wasUnsuccessful should be false: %@",response);
}

- (void) shouldNotBeSuccessful {
	CMResource *resource = [self.endpoint resource:@"informational"];
	CMResponse *response = [resource get];
	STAssertFalse([response wasSuccessful], @"Response#wasSuccessful should be false for informational: %@",response);
	
	resource = [self.endpoint resource:@"redirect"];
	response = [resource get];
	STAssertFalse([response wasSuccessful], @"Response#wasSuccessful should be false for redirect: %@",response);
	
	resource = [self.endpoint resource:@"clienterrror"];
	response = [resource get];
	STAssertFalse([response wasSuccessful], @"Response#wasSuccessful should be false for clienterrror: %@",response);
	
	resource = [self.endpoint resource:@"servererror"];
	response = [resource get];
	STAssertFalse([response wasSuccessful], @"Response#wasSuccessful should be false for servererror: %@",response);
}

- (void) shouldReturnLastModifiedAsDate {
	CMResource *resource = [self.service resource:@"modified"];
	CMResponse *response = [resource get];
	BOOL lastModifiedWasDate = [response.lastModified isKindOfClass:[NSDate class]];
	STAssertTrue(lastModifiedWasDate, @"Response last modified should have been a date: %@",response.lastModified);
}

- (void) shouldReturnAValidContentRangeForARangeRequest {
	
	CMResource *hero = [self.service resource:@"resources/t_hero.png"];
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[hero downloadRange:CMContentRangeMake(0,(_heroBytes/2),0) progressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	//dispatch_release(request_sema);
	STAssertTrue(localResponse.expectedContentRange.location == 0, @"Content range location should be equal to the start of the range");
	STAssertTrue(CMContentRangeLastByte(localResponse.expectedContentRange) == (_heroBytes/2)-1, @"Content range last byte should be equal to the length of the range minus 1 because bytes are zero indexed");
	STAssertTrue(localResponse.expectedContentRange.contentLength == _heroBytes, @"Content range contentLength should be equal to the length of the content");
}

- (void) shouldReportPartialContentForARangeRequest {
	CMResource *hero = [self.service resource:@"resources/t_hero.png"];
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[hero downloadRange:CMContentRangeMake(0,(_heroBytes/2),0) progressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	//dispatch_release(request_sema);
	STAssertTrue(localResponse.HTTPPartialContent, @"Should return YES for a HTTPPartialContent for a range request");
}

- (void) shouldReturnAnInvalidContentRangeForANonRangeRequest {
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];
	STAssertTrue(response.expectedContentRange.location == kCFNotFound, @"Content range location should be invalid for a non range request");
}

- (void) shouldReturnAValidContentLengthWhenServerReportedIt {
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];
	NSString *contentLengthHeader = [response.headers objectForKey:kCumulusHTTPHeaderContentLength];
	STAssertTrue(response.expectedContentLength == [contentLengthHeader longLongValue], @"Content length should match what's in the Content-Length header");
}

- (void) shouldReturnContentRangeLengthForContentLengthWhenContentLengthWasNotReportedForARangeRequest {
	CMResource *hero = [self.service resource:@"resources/t_hero.png"];
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[hero downloadRange:CMContentRangeMake(0,(_heroBytes/2),0) progressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	//dispatch_release(request_sema);
	
	STAssertNil([localResponse.headers objectForKey:kCumulusHTTPHeaderContentLength], @"Content length header must be nil for this to be a valid test");
	STAssertEquals(localResponse.expectedContentLength, localResponse.expectedContentRange.length, @"Content length should derive from content range when the header is missing");
}

- (void) shouldReturnAContentRangeLengthThatIsTheSameAsWhatTheRequestExpectedForARangeRequest {
	CMResource *hero = [self.service resource:@"resources/t_hero.png"];
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[hero downloadRange:CMContentRangeMake(0,(_heroBytes/2),0) progressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	//dispatch_release(request_sema);
	
	STAssertEquals(localResponse.expectedContentRange.length, localResponse.request.expectedContentLength, @"Content range length should equal what the request expected: %@",@(localResponse.request.expectedContentLength));
}

- (void) shouldReportContentRangeContentLengthForTotalLengthForARangeRequest {
	CMResource *hero = [self.service resource:@"resources/t_hero.png"];
	dispatch_semaphore_t request_sema = dispatch_semaphore_create(0);
	
	__block CMResponse *localResponse = nil;
	[hero downloadRange:CMContentRangeMake(0,(_heroBytes/2),0) progressBlock:nil completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(request_sema);
	}];
	
	dispatch_semaphore_wait(request_sema, DISPATCH_TIME_FOREVER);
	//dispatch_release(request_sema);
	
	STAssertEquals(localResponse.totalContentLength, localResponse.expectedContentRange.contentLength, @"Total length should derive from content range for a range request");
}

- (void) shouldReturnContentLengthForTotalLengthForANonRangeRequest {
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];
	STAssertTrue(response.totalContentLength == response.expectedContentLength, @"Total length should derive from content length for a non range request");
}

- (void) shouldReturnUnknownContentLengthWhenThereIsNoContentLengthAndNoContentRange {
	CMResource *heroStream = [self.service resource:@"test/stream/hero"];
	CMResponse *response = [heroStream get];
	STAssertNil([response.headers objectForKey:kCumulusHTTPHeaderContentLength], @"Content length header must be nil for this to be a valid test");
	STAssertNil([response.headers objectForKey:kCumulusHTTPHeaderContentRange], @"Content range header must be nil for this to be a valid test");
	STAssertTrue(response.expectedContentLength == NSURLResponseUnknownLength, @"Content length should be unknown when not a range request and no content length reported");
}

- (void) shouldCreateAnErrorForHTTPErrorStatusCodes {
	CMResource *resource = [self.endpoint resource:@"badrequest"];
	CMResponse *response = [resource get];
	
	NSError *error = response.error;
	STAssertNotNil(error, @"Error should not be nil");
	NSNumber *errorStatusCode = [[error userInfo] objectForKey:kCumulusHTTPStatusCodeErrorKey];
	STAssertEqualObjects([NSNumber numberWithInt:kHTTPStatusBadRequest], errorStatusCode, @"Status code in error should have been %d",kHTTPStatusBadRequest);
}

- (void) shouldNotCreateAnErrorForCanceledRequest {
	CMResource *resource = [self.service resource:@"test/download/massive"];
	__block CMResponse *localResponse = nil;
	dispatch_semaphore_t cancel_sema = dispatch_semaphore_create(0);
	[resource getWithProgressBlock:^(CMProgressInfo *progressInfo) {
		if ([progressInfo.progress floatValue] > 0.f) {
			[progressInfo.request cancel];
		}
	} completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(cancel_sema);
	}];
	[resource cancelRequests];
	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
	//dispatch_release(cancel_sema);
	
	NSError *error = localResponse.error;
	STAssertNil(error, @"Status code error should have been nil: %@",error);
}

- (void) shouldBeCanceled {
	CMResource *resource = [self.service resource:@"test/download/massive"];
	__block CMResponse *localResponse = nil;
	dispatch_semaphore_t cancel_sema = dispatch_semaphore_create(0);
	//	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
	[resource getWithProgressBlock:^(CMProgressInfo *progressInfo) {
		if ([progressInfo.progress floatValue] > 0.f) {
			[progressInfo.request cancel];
		}
	} completionBlock:^(CMResponse *response) {
		localResponse = response;
		dispatch_semaphore_signal(cancel_sema);
	}];
	//	  [resource cancelRequestsWithBlock:^{
	//		dispatch_semaphore_signal(cancel_sema);
	//	}];
	dispatch_semaphore_wait(cancel_sema, DISPATCH_TIME_FOREVER);
	//dispatch_release(cancel_sema);
	STAssertTrue([localResponse HTTPCanceled], @"Response#HTTPCanceled should be true: %@",localResponse);
}




#pragma mark - - Response Codes



/* requests never quit with this range, have to figure out another way to test
 
 //- (void) shouldBeContinue {
 // CMResource *resource = [self.endpoint resource:@"continue"];
 // CMResponse *response = [resource get];
 // STAssertTrue([response isContinue], @"Response#isContinue should be true: %@",response);
 //}
 
 //- (void) shouldBeSwitchingProtocols {
 // CMResource *resource = [self.endpoint resource:@"switchingprotocols"];
 // CMResponse *response = [resource get];
 // STAssertTrue([response isSwitchingProtocols], @"Response#isSwitchingProtocols should be true: %@",response);
 //}
 
 end */


- (void) shouldBeOk {
	CMResource *resource = [self.endpoint resource:@"ok"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPOk], @"Response#isOk should be true: %@",response);
}
- (void) shouldBeCreated {
	CMResource *resource = [self.endpoint resource:@"created"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPCreated], @"Response#isCreated should be true: %@",response);
}
- (void) shouldBeAccepted {
	CMResource *resource = [self.endpoint resource:@"accepted"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPAccepted], @"Response#isAccepted should be true: %@",response);
}
- (void) shouldBeNonAuthoritative {
	CMResource *resource = [self.endpoint resource:@"nonauthoritative"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPNonAuthoritative], @"Response#isNonAuthoritative should be true: %@",response);
}
- (void) shouldBeNoContent {
	CMResource *resource = [self.endpoint resource:@"nocontent"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPNoContent], @"Response#isNoContent should be true: %@",response);
}
- (void) shouldBeResetContent {
	CMResource *resource = [self.endpoint resource:@"resetcontent"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPResetContent], @"Response#isResetContent should be true: %@",response);
}
- (void) shouldBePartialContent {
	CMResource *resource = [self.endpoint resource:@"partialcontent"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPPartialContent], @"Response#isPartialContent should be true: %@",response);
}

- (void) shouldBeMultipleChoices {
	CMResource *resource = [self.endpoint resource:@"multiplechoices"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPMultipleChoices], @"Response#isMultipleChoices should be true: %@",response);
}
- (void) shouldBeMovedPermanently {
	CMResource *resource = [self.endpoint resource:@"movedpermanently"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPMovedPermanently], @"Response#isMovedPermanently should be true: %@",response);
}
- (void) shouldBeFound {
	CMResource *resource = [self.endpoint resource:@"found"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPFound], @"Response#isFound should be true: %@",response);
}
- (void) shouldBeSeeOther {
	CMResource *resource = [self.endpoint resource:@"seeother"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPSeeOther], @"Response#isSeeOther should be true: %@",response);
}
- (void) shouldBeNotModified {
	CMResource *resource = [self.endpoint resource:@"notmodified"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPNotModified], @"Response#isNotModified should be true: %@",response);
}
- (void) shouldBeUseProxy {
	CMResource *resource = [self.endpoint resource:@"useproxy"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPUseProxy], @"Response#isUseProxy should be true: %@",response);
}
- (void) shouldBeSwitchProxy {
	CMResource *resource = [self.endpoint resource:@"switchproxy"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPSwitchProxy], @"Response#isSwitchProxy should be true: %@",response);
}
- (void) shouldBeTemporaryRedirect {
	CMResource *resource = [self.endpoint resource:@"temporaryredirect"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPTemporaryRedirect], @"Response#isTemporaryRedirect should be true: %@",response);
}
- (void) shouldBeResumeIncomplete {
	CMResource *resource = [self.endpoint resource:@"resumeincomplete"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPResumeIncomplete], @"Response#isResumeIncomplete should be true: %@",response);
}

- (void) shouldBeBadRequest {
	CMResource *resource = [self.endpoint resource:@"badrequest"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPBadRequest], @"Response#isBadRequest should be true: %@",response);
}
- (void) shouldBeUnauthorized {
	CMResource *resource = [self.endpoint resource:@"unauthorized"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPUnauthorized], @"Response#isUnauthorized should be true: %@",response);
}
- (void) shouldBePaymentRequired {
	CMResource *resource = [self.endpoint resource:@"paymentrequired"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPPaymentRequired], @"Response#isPaymentRequired should be true: %@",response);
}
- (void) shouldBeForbidden {
	CMResource *resource = [self.endpoint resource:@"forbidden"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPForbidden], @"Response#isForbidden should be true: %@",response);
}
- (void) shouldBeNotFound {
	CMResource *resource = [self.endpoint resource:@"notfound"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPNotFound], @"Response#isNotFound should be true: %@",response);
}
- (void) shouldBeMethodNotAllowed {
	CMResource *resource = [self.endpoint resource:@"methodnotallowed"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPMethodNotAllowed], @"Response#isMethodNotAllowed should be true: %@",response);
}
- (void) shouldBeNotAcceptable {
	CMResource *resource = [self.endpoint resource:@"notacceptable"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPNotAcceptable], @"Response#isNotAcceptable should be true: %@",response);
}
- (void) shouldBeProxyAuthenticationRequired {
	CMResource *resource = [self.endpoint resource:@"proxyauthenticationrequired"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPProxyAuthenticationRequired], @"Response#isProxyAuthenticationRequired should be true: %@",response);
}
- (void) shouldBeRequestTimeout {
	CMResource *resource = [self.endpoint resource:@"requesttimeout"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPRequestTimeout], @"Response#isRequestTimeout should be true: %@",response);
}
- (void) shouldBeConflict {
	CMResource *resource = [self.endpoint resource:@"conflict"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPConflict], @"Response#isConflict should be true: %@",response);
}
- (void) shouldBeGone {
	CMResource *resource = [self.endpoint resource:@"gone"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPGone], @"Response#isGone should be true: %@",response);
}
- (void) shouldBeLengthRequired {
	CMResource *resource = [self.endpoint resource:@"lengthrequired"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPLengthRequired], @"Response#isLengthRequired should be true: %@",response);
}
- (void) shouldBePreconditionFailed {
	CMResource *resource = [self.endpoint resource:@"preconditionfailed"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPPreconditionFailed], @"Response#isPreconditionFailed should be true: %@",response);
}
- (void) shouldBeRequestEntityTooLarge {
	CMResource *resource = [self.endpoint resource:@"requestentitytoolarge"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPRequestEntityTooLarge], @"Response#isRequestEntityTooLarge should be true: %@",response);
}
- (void) shouldBeRequestURITooLong {
	CMResource *resource = [self.endpoint resource:@"requesturitoolong"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPRequestURITooLong], @"Response#isRequestURITooLong should be true: %@",response);
}
- (void) shouldBeUnsupportedMediaType {
	CMResource *resource = [self.endpoint resource:@"unsupportedmediatype"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPUnsupportedMediaType], @"Response#isUnsupportedMediaType should be true: %@",response);
}
- (void) shouldBeRequestRangeNotSatisfied {
	CMResource *resource = [self.endpoint resource:@"requestrangenotsatisfied"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPRequestRangeNotSatisfied], @"Response#isRequestRangeNotSatisfied should be true: %@",response);
}
- (void) shouldBeExpectationFailed {
	CMResource *resource = [self.endpoint resource:@"expectationfailed"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPExpectationFailed], @"Response#isExpectationFailed should be true: %@",response);
}
- (void) shouldBeUnprocessableEntity {
	CMResource *resource = [self.endpoint resource:@"unprocessableentity"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPUnprocessableEntity], @"Response#isUnprocessableEntity should be true: %@",response);
}

- (void) shouldBeInternalServerError {
	CMResource *resource = [self.endpoint resource:@"notimplemented"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPNotImplemented], @"Response#isNotImplemented should be true: %@",response);
}
- (void) shouldBeNotImplemented {
	CMResource *resource = [self.endpoint resource:@"notimplemented"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPNotImplemented], @"Response#isNotImplemented should be true: %@",response);
}
- (void) shouldBeBadGateway {
	CMResource *resource = [self.endpoint resource:@"badgateway"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPBadGateway], @"Response#isBadGateway should be true: %@",response);
}
- (void) shouldBeServiceUnavailable {
	CMResource *resource = [self.endpoint resource:@"serviceunavailable"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPServiceUnavailable], @"Response#isServiceUnavailable should be true: %@",response);
}
- (void) shouldBeGatewayTimeout {
	CMResource *resource = [self.endpoint resource:@"gatewaytimeout"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPGatewayTimeout], @"Response#isGatewayTimeout should be true: %@",response);
}
- (void) shouldBeHTTPVersionNotSupported {
	CMResource *resource = [self.endpoint resource:@"httpversionnotsupported"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPVersionNotSupported], @"Response#isHTTPVersionNotSupported should be true: %@",response);
}



/** Ranges of codes */

/* requests never quit with this range
 
 //- (void) shouldBeInformational {
 //	CMResource *resource = [self.endpoint resource:@"informational"];
 //	CMResponse *response = [resource get];
 //	STAssertTrue([response wasInformational], @"Response#wasInformational should be true: %@",response);
 //}
 
 end */



- (void) shouldBeHTTPSuccessful {
	CMResource *resource = [self.endpoint resource:@"successful"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPSuccessful], @"Response#HTTPSuccessful should be true: %@",response);
}

- (void) shouldBeHTTPRedirect {
	CMResource *resource = [self.endpoint resource:@"redirect"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPRedirect], @"Response#HTTPRedirect should be true: %@",response);
}

- (void) shouldBeHTTPClientErrror {
	CMResource *resource = [self.endpoint resource:@"clienterrror"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPClientErrror], @"Response#HTTPClientErrror should be true: %@",response);
}

- (void) shouldBeHTTPServerError {
	CMResource *resource = [self.endpoint resource:@"servererror"];
	CMResponse *response = [resource get];
	STAssertTrue([response HTTPServerError], @"Response#HTTPServerError should be true: %@",response);
}



@end
