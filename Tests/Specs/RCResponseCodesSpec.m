//
//  RCResponseCodesSpec.m
//  RESTClient
//
//  Created by John Clayton on 10/15/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCResponseCodesSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCResponseCodesSpec

@synthesize service;
@synthesize endpoint;

+ (NSString *)description {
    return @"Response Codes";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
	self.service = [RCResource withURL:kTestServerHost];
	
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


// requests never quit with this range, have to figure out another way to test

//- (void) shouldBeContinue {
//	RCResource *resource = [self.endpoint resource:@"continue"];
//	RCResponse *response = [resource get];
//	STAssertTrue([response isContinue], @"Response#isContinue should be true: %@",response);
//}

//- (void) shouldBeSwitchingProtocols {
//	RCResource *resource = [self.endpoint resource:@"switchingprotocols"];
//	RCResponse *response = [resource get];
//	STAssertTrue([response isSwitchingProtocols], @"Response#isSwitchingProtocols should be true: %@",response);
//}


- (void) shouldCreateAnErrorForHTTPErrorStatusCodes {
	RCResource *resource = [self.endpoint resource:@"badrequest"];
	RCResponse *response = [resource get];
	
	NSError *error = response.error;
	STAssertNotNil(error, @"Error should not be nil");
	NSNumber *errorStatusCode = [[error userInfo] objectForKey:kRESTCLientHTTPStatusCodeErrorKey];
	STAssertEqualObjects([NSNumber numberWithInt:kHTTPStatusBadRequest], errorStatusCode, @"Status code in error should have been %d",kHTTPStatusBadRequest);
}

- (void) shouldBeOk {
	RCResource *resource = [self.endpoint resource:@"ok"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPOk], @"Response#isOk should be true: %@",response);
}
- (void) shouldBeCreated {
	RCResource *resource = [self.endpoint resource:@"created"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPCreated], @"Response#isCreated should be true: %@",response);
}
- (void) shouldBeAccepted {
	RCResource *resource = [self.endpoint resource:@"accepted"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPAccepted], @"Response#isAccepted should be true: %@",response);
}
- (void) shouldBeNonAuthoritative {
	RCResource *resource = [self.endpoint resource:@"nonauthoritative"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPNonAuthoritative], @"Response#isNonAuthoritative should be true: %@",response);
}
- (void) shouldBeNoContent {
	RCResource *resource = [self.endpoint resource:@"nocontent"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPNoContent], @"Response#isNoContent should be true: %@",response);
}
- (void) shouldBeResetContent {
	RCResource *resource = [self.endpoint resource:@"resetcontent"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPResetContent], @"Response#isResetContent should be true: %@",response);
}
- (void) shouldBePartialContent {
	RCResource *resource = [self.endpoint resource:@"partialcontent"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPPartialContent], @"Response#isPartialContent should be true: %@",response);
}

- (void) shouldBeMultipleChoices {
	RCResource *resource = [self.endpoint resource:@"multiplechoices"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPMultipleChoices], @"Response#isMultipleChoices should be true: %@",response);
}
- (void) shouldBeMovedPermanently {
	RCResource *resource = [self.endpoint resource:@"movedpermanently"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPMovedPermanently], @"Response#isMovedPermanently should be true: %@",response);
}
- (void) shouldBeFound {
	RCResource *resource = [self.endpoint resource:@"found"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPFound], @"Response#isFound should be true: %@",response);
}
- (void) shouldBeSeeOther {
	RCResource *resource = [self.endpoint resource:@"seeother"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPSeeOther], @"Response#isSeeOther should be true: %@",response);
}
- (void) shouldBeNotModified {
	RCResource *resource = [self.endpoint resource:@"notmodified"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPNotModified], @"Response#isNotModified should be true: %@",response);
}
- (void) shouldBeUseProxy {
	RCResource *resource = [self.endpoint resource:@"useproxy"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPUseProxy], @"Response#isUseProxy should be true: %@",response);
}
- (void) shouldBeSwitchProxy {
	RCResource *resource = [self.endpoint resource:@"switchproxy"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPSwitchProxy], @"Response#isSwitchProxy should be true: %@",response);
}
- (void) shouldBeTemporaryRedirect {
	RCResource *resource = [self.endpoint resource:@"temporaryredirect"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPTemporaryRedirect], @"Response#isTemporaryRedirect should be true: %@",response);
}
- (void) shouldBeResumeIncomplete {
	RCResource *resource = [self.endpoint resource:@"resumeincomplete"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPResumeIncomplete], @"Response#isResumeIncomplete should be true: %@",response);
}

- (void) shouldBeBadRequest {
	RCResource *resource = [self.endpoint resource:@"badrequest"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPBadRequest], @"Response#isBadRequest should be true: %@",response);
}
- (void) shouldBeUnauthorized {
	RCResource *resource = [self.endpoint resource:@"unauthorized"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPUnauthorized], @"Response#isUnauthorized should be true: %@",response);
}
- (void) shouldBePaymentRequired {
	RCResource *resource = [self.endpoint resource:@"paymentrequired"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPPaymentRequired], @"Response#isPaymentRequired should be true: %@",response);
}
- (void) shouldBeForbidden {
	RCResource *resource = [self.endpoint resource:@"forbidden"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPForbidden], @"Response#isForbidden should be true: %@",response);
}
- (void) shouldBeNotFound {
	RCResource *resource = [self.endpoint resource:@"notfound"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPNotFound], @"Response#isNotFound should be true: %@",response);
}
- (void) shouldBeMethodNotAllowed {
	RCResource *resource = [self.endpoint resource:@"methodnotallowed"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPMethodNotAllowed], @"Response#isMethodNotAllowed should be true: %@",response);
}
- (void) shouldBeNotAcceptable {
	RCResource *resource = [self.endpoint resource:@"notacceptable"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPNotAcceptable], @"Response#isNotAcceptable should be true: %@",response);
}
- (void) shouldBeProxyAuthenticationRequired {
	RCResource *resource = [self.endpoint resource:@"proxyauthenticationrequired"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPProxyAuthenticationRequired], @"Response#isProxyAuthenticationRequired should be true: %@",response);
}
- (void) shouldBeRequestTimeout {
	RCResource *resource = [self.endpoint resource:@"requesttimeout"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPRequestTimeout], @"Response#isRequestTimeout should be true: %@",response);
}
- (void) shouldBeConflict {
	RCResource *resource = [self.endpoint resource:@"conflict"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPConflict], @"Response#isConflict should be true: %@",response);
}
- (void) shouldBeGone {
	RCResource *resource = [self.endpoint resource:@"gone"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPGone], @"Response#isGone should be true: %@",response);
}
- (void) shouldBeLengthRequired {
	RCResource *resource = [self.endpoint resource:@"lengthrequired"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPLengthRequired], @"Response#isLengthRequired should be true: %@",response);
}
- (void) shouldBePreconditionFailed {
	RCResource *resource = [self.endpoint resource:@"preconditionfailed"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPPreconditionFailed], @"Response#isPreconditionFailed should be true: %@",response);
}
- (void) shouldBeRequestEntityTooLarge {
	RCResource *resource = [self.endpoint resource:@"requestentitytoolarge"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPRequestEntityTooLarge], @"Response#isRequestEntityTooLarge should be true: %@",response);
}
- (void) shouldBeRequestURITooLong {
	RCResource *resource = [self.endpoint resource:@"requesturitoolong"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPRequestURITooLong], @"Response#isRequestURITooLong should be true: %@",response);
}
- (void) shouldBeUnsupportedMediaType {
	RCResource *resource = [self.endpoint resource:@"unsupportedmediatype"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPUnsupportedMediaType], @"Response#isUnsupportedMediaType should be true: %@",response);
}
- (void) shouldBeRequestRangeNotSatisfied {
	RCResource *resource = [self.endpoint resource:@"requestrangenotsatisfied"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPRequestRangeNotSatisfied], @"Response#isRequestRangeNotSatisfied should be true: %@",response);
}
- (void) shouldBeExpectationFailed {
	RCResource *resource = [self.endpoint resource:@"expectationfailed"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPExpectationFailed], @"Response#isExpectationFailed should be true: %@",response);
}
- (void) shouldBeUnprocessableEntity {
	RCResource *resource = [self.endpoint resource:@"unprocessableentity"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPUnprocessableEntity], @"Response#isUnprocessableEntity should be true: %@",response);
}

- (void) shouldBeInternalServerError {
	RCResource *resource = [self.endpoint resource:@"notimplemented"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPNotImplemented], @"Response#isNotImplemented should be true: %@",response);
}
- (void) shouldBeNotImplemented {
	RCResource *resource = [self.endpoint resource:@"notimplemented"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPNotImplemented], @"Response#isNotImplemented should be true: %@",response);
}
- (void) shouldBeBadGateway {
	RCResource *resource = [self.endpoint resource:@"badgateway"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPBadGateway], @"Response#isBadGateway should be true: %@",response);
}
- (void) shouldBeServiceUnavailable {
	RCResource *resource = [self.endpoint resource:@"serviceunavailable"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPServiceUnavailable], @"Response#isServiceUnavailable should be true: %@",response);
}
- (void) shouldBeGatewayTimeout {
	RCResource *resource = [self.endpoint resource:@"gatewaytimeout"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPGatewayTimeout], @"Response#isGatewayTimeout should be true: %@",response);
}
- (void) shouldBeHTTPVersionNotSupported {
	RCResource *resource = [self.endpoint resource:@"httpversionnotsupported"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPVersionNotSupported], @"Response#isHTTPVersionNotSupported should be true: %@",response);
}


/** Ranges of codes */

// requests never quit with this range

//- (void) shouldBeInformational {
//	RCResource *resource = [self.endpoint resource:@"informational"];
//	RCResponse *response = [resource get];
//	STAssertTrue([response wasInformational], @"Response#wasInformational should be true: %@",response);
//}

- (void) shouldBeSuccessful {
	RCResource *resource = [self.endpoint resource:@"successful"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPSuccessful], @"Response#wasSuccessful should be true: %@",response);
}

- (void) shouldBeRedirect {
	RCResource *resource = [self.endpoint resource:@"redirect"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPRedirect], @"Response#wasRedirect should be true: %@",response);
}

- (void) shouldBeClientErrror {
	RCResource *resource = [self.endpoint resource:@"clienterrror"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPClientErrror], @"Response#wasClientErrror should be true: %@",response);
}

- (void) shouldBeServerError {
	RCResource *resource = [self.endpoint resource:@"servererror"];
	RCResponse *response = [resource get];
	STAssertTrue([response HTTPServerError], @"Response#wasServerError should be true: %@",response);
}

 
 


@end
