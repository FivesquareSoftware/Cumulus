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


@import Nimble;


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
	expect([response wasSuccessful]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#wasSuccessful should be true: %@",response]);
}

- (void) shouldBeUnsuccessful {
	CMResource *resource = [self.endpoint resource:@"informational"];
	CMResponse *response = [resource get];
	expect([response wasUnsuccessful]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#wasUnsuccessful should be true for informational: %@",response]);
	
	resource = [self.endpoint resource:@"redirect"];
	response = [resource get];
	expect([response wasUnsuccessful]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#wasUnsuccessful should be true for redirect: %@",response]);
	
	resource = [self.endpoint resource:@"clienterrror"];
	response = [resource get];
	expect([response wasUnsuccessful]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#wasUnsuccessful should be true for clienterrror: %@",response]);
	
	resource = [self.endpoint resource:@"servererror"];
	response = [resource get];
	expect([response wasUnsuccessful]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#wasUnsuccessful should be true for servererror: %@",response]);
}

- (void) shouldNotBeUnsuccessful {
	CMResource *resource = [self.endpoint resource:@"successful"];
	CMResponse *response = [resource get];
	expect([response wasUnsuccessful]).toWithDescription(beFalse(),[NSString stringWithFormat:@"Response#wasUnsuccessful should be false: %@", response]);
}

- (void) shouldNotBeSuccessful {
	CMResource *resource = [self.endpoint resource:@"informational"];
	CMResponse *response = [resource get];
	expect([response wasSuccessful]).toWithDescription(beFalse(),[NSString stringWithFormat:@"Response#wasSuccessful should be false for informational: %@", response]);
	
	resource = [self.endpoint resource:@"redirect"];
	response = [resource get];
	expect([response wasSuccessful]).toWithDescription(beFalse(),[NSString stringWithFormat:@"Response#wasSuccessful should be false for redirect: %@", response]);
	
	resource = [self.endpoint resource:@"clienterrror"];
	response = [resource get];
	expect([response wasSuccessful]).toWithDescription(beFalse(),[NSString stringWithFormat:@"Response#wasSuccessful should be false for clienterrror: %@", response]);
	
	resource = [self.endpoint resource:@"servererror"];
	response = [resource get];
	expect([response wasSuccessful]).toWithDescription(beFalse(),[NSString stringWithFormat:@"Response#wasSuccessful should be false for servererror: %@", response]);
}

- (void) shouldReturnLastModifiedAsDate {
	CMResource *resource = [self.service resource:@"modified"];
	CMResponse *response = [resource get];
	BOOL lastModifiedWasDate = [response.lastModified isKindOfClass:[NSDate class]];
	expect(lastModifiedWasDate).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response last modified should have been a date: %@",response.lastModified]);
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
		expect(localResponse.expectedContentRange.location == 0).toWithDescription(beTrue(), @"Content range location should be equal to the start of the range");
	expect(CMContentRangeLastByte(localResponse.expectedContentRange) == (_heroBytes/2)-1).toWithDescription(beTrue(), @"Content range last byte should be equal to the length of the range minus 1 because bytes are zero indexed");
	expect(localResponse.expectedContentRange.contentLength == _heroBytes).toWithDescription(beTrue(), @"Content range contentLength should be equal to the length of the content");
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
		expect(localResponse.HTTPPartialContent).toWithDescription(beTrue(), @"Should return YES for a HTTPPartialContent for a range request");
}

- (void) shouldReturnAnInvalidContentRangeForANonRangeRequest {
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];
	expect(response.expectedContentRange.location == kCFNotFound).toWithDescription(beTrue(), @"Content range location should be invalid for a non range request");
}

- (void) shouldReturnAValidContentLengthWhenServerReportedIt {
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];
	NSString *contentLengthHeader = [response.headers objectForKey:kCumulusHTTPHeaderContentLength];
	expect(response.expectedContentLength == [contentLengthHeader longLongValue]).toWithDescription(beTrue(), @"Content length should match what's in the Content-Length header");
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
		
	expect([localResponse.headers objectForKey:kCumulusHTTPHeaderContentLength]).toWithDescription(beNil(), @"Content length header must be nil for this to be a valid test");
	expect(@(localResponse.expectedContentLength)).toWithDescription(equal(@(localResponse.expectedContentRange.length)), @"Content length should derive from content range when the header is missing");
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
		
	expect(@(localResponse.expectedContentRange.length)).toWithDescription(equal(@(localResponse.request.expectedContentLength)), [NSString stringWithFormat:@"Content range length should equal what the request expected: %@", @(localResponse.request.expectedContentLength)]);

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
		
	expect(@(localResponse.totalContentLength)).toWithDescription(equal(@(localResponse.expectedContentRange.contentLength)), @"Total length should derive from content range for a range request");
}

- (void) shouldReturnContentLengthForTotalLengthForANonRangeRequest {
	CMResource *index = [self.service resource:@"index"];
	CMResponse *response = [index get];
	expect(response.totalContentLength == response.expectedContentLength).toWithDescription(beTrue(), @"Total length should derive from content length for a non range request");
}

- (void) shouldReturnUnknownContentLengthWhenThereIsNoContentLengthAndNoContentRange {
	CMResource *heroStream = [self.service resource:@"test/stream/hero"];
	CMResponse *response = [heroStream get];
	expect([response.headers objectForKey:kCumulusHTTPHeaderContentLength]).toWithDescription(beNil(), @"Content length header must be nil for this to be a valid test");
	expect([response.headers objectForKey:kCumulusHTTPHeaderContentRange]).toWithDescription(beNil(), @"Content range header must be nil for this to be a valid test");
	expect(response.expectedContentLength == NSURLResponseUnknownLength).toWithDescription(beTrue(), @"Content length should be unknown when not a range request and no content length reported");
}

- (void) shouldCreateAnErrorForHTTPErrorStatusCodes {
	CMResource *resource = [self.endpoint resource:@"badrequest"];
	CMResponse *response = [resource get];
	
	NSError *error = response.error;
	expect(error).toNotWithDescription(beNil(),@"Error should not be nil");
	NSNumber *errorStatusCode = [[error userInfo] objectForKey:kCumulusHTTPStatusCodeErrorKey];
	expect([NSNumber numberWithInt:kHTTPStatusBadRequest]).toWithDescription(equal(errorStatusCode), [NSString stringWithFormat:@"Status code in error should have been %d",kHTTPStatusBadRequest]);
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
		
	NSError *error = localResponse.error;
	expect(error).toWithDescription(beNil(), [NSString stringWithFormat:@"Status code error should have been nil: %@", error]);
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
		expect([localResponse HTTPCanceled]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#HTTPCanceled should be true: %@",localResponse]);
}




#pragma mark - - Response Codes



/* requests never quit with this range, have to figure out another way to test
 
 //- (void) shouldBeContinue {
 // CMResource *resource = [self.endpoint resource:@"continue"];
 // CMResponse *response = [resource get];
 // expect([response isContinue]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isContinue should be true: %@",response]);
 //}
 
 //- (void) shouldBeSwitchingProtocols {
 // CMResource *resource = [self.endpoint resource:@"switchingprotocols"];
 // CMResponse *response = [resource get];
 // expect([response isSwitchingProtocols]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isSwitchingProtocols should be true: %@",response]);
 //}
 
 end */


- (void) shouldBeOk {
	CMResource *resource = [self.endpoint resource:@"ok"];
	CMResponse *response = [resource get];
	expect([response HTTPOk]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isOk should be true: %@",response]);
}
- (void) shouldBeCreated {
	CMResource *resource = [self.endpoint resource:@"created"];
	CMResponse *response = [resource get];
	expect([response HTTPCreated]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isCreated should be true: %@",response]);
}
- (void) shouldBeAccepted {
	CMResource *resource = [self.endpoint resource:@"accepted"];
	CMResponse *response = [resource get];
	expect([response HTTPAccepted]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isAccepted should be true: %@",response]);
}
- (void) shouldBeNonAuthoritative {
	CMResource *resource = [self.endpoint resource:@"nonauthoritative"];
	CMResponse *response = [resource get];
	expect([response HTTPNonAuthoritative]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isNonAuthoritative should be true: %@",response]);
}
- (void) shouldBeNoContent {
	CMResource *resource = [self.endpoint resource:@"nocontent"];
	CMResponse *response = [resource get];
	expect([response HTTPNoContent]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isNoContent should be true: %@",response]);
}
- (void) shouldBeResetContent {
	CMResource *resource = [self.endpoint resource:@"resetcontent"];
	CMResponse *response = [resource get];
	expect([response HTTPResetContent]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isResetContent should be true: %@",response]);
}
- (void) shouldBePartialContent {
	CMResource *resource = [self.endpoint resource:@"partialcontent"];
	CMResponse *response = [resource get];
	expect([response HTTPPartialContent]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isPartialContent should be true: %@",response]);
}

- (void) shouldBeMultipleChoices {
	CMResource *resource = [self.endpoint resource:@"multiplechoices"];
	CMResponse *response = [resource get];
	expect([response HTTPMultipleChoices]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isMultipleChoices should be true: %@",response]);
}
- (void) shouldBeMovedPermanently {
	CMResource *resource = [self.endpoint resource:@"movedpermanently"];
	CMResponse *response = [resource get];
	expect([response HTTPMovedPermanently]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isMovedPermanently should be true: %@",response]);
}
- (void) shouldBeFound {
	CMResource *resource = [self.endpoint resource:@"found"];
	CMResponse *response = [resource get];
	expect([response HTTPFound]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isFound should be true: %@",response]);
}
- (void) shouldBeSeeOther {
	CMResource *resource = [self.endpoint resource:@"seeother"];
	CMResponse *response = [resource get];
	expect([response HTTPSeeOther]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isSeeOther should be true: %@",response]);
}
- (void) shouldBeNotModified {
	CMResource *resource = [self.endpoint resource:@"notmodified"];
	CMResponse *response = [resource get];
	expect([response HTTPNotModified]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isNotModified should be true: %@",response]);
}
- (void) shouldBeUseProxy {
	CMResource *resource = [self.endpoint resource:@"useproxy"];
	CMResponse *response = [resource get];
	expect([response HTTPUseProxy]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isUseProxy should be true: %@",response]);
}
- (void) shouldBeSwitchProxy {
	CMResource *resource = [self.endpoint resource:@"switchproxy"];
	CMResponse *response = [resource get];
	expect([response HTTPSwitchProxy]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isSwitchProxy should be true: %@",response]);
}
- (void) shouldBeTemporaryRedirect {
	CMResource *resource = [self.endpoint resource:@"temporaryredirect"];
	CMResponse *response = [resource get];
	expect([response HTTPTemporaryRedirect]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isTemporaryRedirect should be true: %@",response]);
}
- (void) shouldBeResumeIncomplete {
	CMResource *resource = [self.endpoint resource:@"resumeincomplete"];
	CMResponse *response = [resource get];
	expect([response HTTPResumeIncomplete]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isResumeIncomplete should be true: %@",response]);
}

- (void) shouldBeBadRequest {
	CMResource *resource = [self.endpoint resource:@"badrequest"];
	CMResponse *response = [resource get];
	expect([response HTTPBadRequest]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isBadRequest should be true: %@",response]);
}
- (void) shouldBeUnauthorized {
	CMResource *resource = [self.endpoint resource:@"unauthorized"];
	CMResponse *response = [resource get];
	expect([response HTTPUnauthorized]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isUnauthorized should be true: %@",response]);
}
- (void) shouldBePaymentRequired {
	CMResource *resource = [self.endpoint resource:@"paymentrequired"];
	CMResponse *response = [resource get];
	expect([response HTTPPaymentRequired]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isPaymentRequired should be true: %@",response]);
}
- (void) shouldBeForbidden {
	CMResource *resource = [self.endpoint resource:@"forbidden"];
	CMResponse *response = [resource get];
	expect([response HTTPForbidden]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isForbidden should be true: %@",response]);
}
- (void) shouldBeNotFound {
	CMResource *resource = [self.endpoint resource:@"notfound"];
	CMResponse *response = [resource get];
	expect([response HTTPNotFound]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isNotFound should be true: %@",response]);
}
- (void) shouldBeMethodNotAllowed {
	CMResource *resource = [self.endpoint resource:@"methodnotallowed"];
	CMResponse *response = [resource get];
	expect([response HTTPMethodNotAllowed]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isMethodNotAllowed should be true: %@",response]);
}
- (void) shouldBeNotAcceptable {
	CMResource *resource = [self.endpoint resource:@"notacceptable"];
	CMResponse *response = [resource get];
	expect([response HTTPNotAcceptable]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isNotAcceptable should be true: %@",response]);
}
- (void) shouldBeProxyAuthenticationRequired {
	CMResource *resource = [self.endpoint resource:@"proxyauthenticationrequired"];
	CMResponse *response = [resource get];
	expect([response HTTPProxyAuthenticationRequired]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isProxyAuthenticationRequired should be true: %@",response]);
}
- (void) shouldBeRequestTimeout {
	CMResource *resource = [self.endpoint resource:@"requesttimeout"];
	CMResponse *response = [resource get];
	expect([response HTTPRequestTimeout]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isRequestTimeout should be true: %@",response]);
}
- (void) shouldBeConflict {
	CMResource *resource = [self.endpoint resource:@"conflict"];
	CMResponse *response = [resource get];
	expect([response HTTPConflict]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isConflict should be true: %@",response]);
}
- (void) shouldBeGone {
	CMResource *resource = [self.endpoint resource:@"gone"];
	CMResponse *response = [resource get];
	expect([response HTTPGone]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isGone should be true: %@",response]);
}
- (void) shouldBeLengthRequired {
	CMResource *resource = [self.endpoint resource:@"lengthrequired"];
	CMResponse *response = [resource get];
	expect([response HTTPLengthRequired]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isLengthRequired should be true: %@",response]);
}
- (void) shouldBePreconditionFailed {
	CMResource *resource = [self.endpoint resource:@"preconditionfailed"];
	CMResponse *response = [resource get];
	expect([response HTTPPreconditionFailed]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isPreconditionFailed should be true: %@",response]);
}
- (void) shouldBeRequestEntityTooLarge {
	CMResource *resource = [self.endpoint resource:@"requestentitytoolarge"];
	CMResponse *response = [resource get];
	expect([response HTTPRequestEntityTooLarge]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isRequestEntityTooLarge should be true: %@",response]);
}
- (void) shouldBeRequestURITooLong {
	CMResource *resource = [self.endpoint resource:@"requesturitoolong"];
	CMResponse *response = [resource get];
	expect([response HTTPRequestURITooLong]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isRequestURITooLong should be true: %@",response]);
}
- (void) shouldBeUnsupportedMediaType {
	CMResource *resource = [self.endpoint resource:@"unsupportedmediatype"];
	CMResponse *response = [resource get];
	expect([response HTTPUnsupportedMediaType]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isUnsupportedMediaType should be true: %@",response]);
}
- (void) shouldBeRequestRangeNotSatisfied {
	CMResource *resource = [self.endpoint resource:@"requestrangenotsatisfied"];
	CMResponse *response = [resource get];
	expect([response HTTPRequestRangeNotSatisfied]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isRequestRangeNotSatisfied should be true: %@",response]);
}
- (void) shouldBeExpectationFailed {
	CMResource *resource = [self.endpoint resource:@"expectationfailed"];
	CMResponse *response = [resource get];
	expect([response HTTPExpectationFailed]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isExpectationFailed should be true: %@",response]);
}
- (void) shouldBeUnprocessableEntity {
	CMResource *resource = [self.endpoint resource:@"unprocessableentity"];
	CMResponse *response = [resource get];
	expect([response HTTPUnprocessableEntity]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isUnprocessableEntity should be true: %@",response]);
}

- (void) shouldBeInternalServerError {
	CMResource *resource = [self.endpoint resource:@"notimplemented"];
	CMResponse *response = [resource get];
	expect([response HTTPNotImplemented]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isNotImplemented should be true: %@",response]);
}
- (void) shouldBeNotImplemented {
	CMResource *resource = [self.endpoint resource:@"notimplemented"];
	CMResponse *response = [resource get];
	expect([response HTTPNotImplemented]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isNotImplemented should be true: %@",response]);
}
- (void) shouldBeBadGateway {
	CMResource *resource = [self.endpoint resource:@"badgateway"];
	CMResponse *response = [resource get];
	expect([response HTTPBadGateway]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isBadGateway should be true: %@",response]);
}
- (void) shouldBeServiceUnavailable {
	CMResource *resource = [self.endpoint resource:@"serviceunavailable"];
	CMResponse *response = [resource get];
	expect([response HTTPServiceUnavailable]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isServiceUnavailable should be true: %@",response]);
}
- (void) shouldBeGatewayTimeout {
	CMResource *resource = [self.endpoint resource:@"gatewaytimeout"];
	CMResponse *response = [resource get];
	expect([response HTTPGatewayTimeout]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isGatewayTimeout should be true: %@",response]);
}
- (void) shouldBeHTTPVersionNotSupported {
	CMResource *resource = [self.endpoint resource:@"httpversionnotsupported"];
	CMResponse *response = [resource get];
	expect([response HTTPVersionNotSupported]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#isHTTPVersionNotSupported should be true: %@",response]);
}



/** Ranges of codes */

/* requests never quit with this range
 
 //- (void) shouldBeInformational {
 //	CMResource *resource = [self.endpoint resource:@"informational"];
 //	CMResponse *response = [resource get];
 //	expect([response wasInformational]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#wasInformational should be true: %@",response]);
 //}
 
 end */



- (void) shouldBeHTTPSuccessful {
	CMResource *resource = [self.endpoint resource:@"successful"];
	CMResponse *response = [resource get];
	expect([response HTTPSuccessful]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#HTTPSuccessful should be true: %@",response]);
}

- (void) shouldBeHTTPRedirect {
	CMResource *resource = [self.endpoint resource:@"redirect"];
	CMResponse *response = [resource get];
	expect([response HTTPRedirect]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#HTTPRedirect should be true: %@",response]);
}

- (void) shouldBeHTTPClientErrror {
	CMResource *resource = [self.endpoint resource:@"clienterrror"];
	CMResponse *response = [resource get];
	expect([response HTTPClientErrror]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#HTTPClientErrror should be true: %@",response]);
}

- (void) shouldBeHTTPServerError {
	CMResource *resource = [self.endpoint resource:@"servererror"];
	CMResponse *response = [resource get];
	expect([response HTTPServerError]).toWithDescription(beTrue(), [NSString stringWithFormat:@"Response#HTTPServerError should be true: %@",response]);
}



@end
