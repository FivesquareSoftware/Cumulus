//
//  RCCodingSpec.m
//  RESTClient
//
//  Created by John Clayton on 10/15/11.
//  Copyright 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCCodingSpec.h"

// This class will be instantiated for you and made available in the property "self.specHelper", store your cross-test data and helper methods there
#import "SpecHelper.h"


#import <SenTestingKit/SenTestingKit.h>


@implementation RCCodingSpec

@synthesize service;

+ (NSString *)description {
    return @"Data Encoding and Decoding";
}

// ========================================================================== //

#pragma mark - Setup and Teardown


- (void)beforeAll {
    // set up resources common to all examples here
}

- (void)beforeEach {
    // set up resources that need to be initialized before each example here 
	self.service = [RCResource withURL:kTestServerHost];
}

- (void)afterEach {
    // tear down resources specific to each example here
}


- (void)afterAll {
    // tear down common resources here
}

// ========================================================================== //

#pragma mark - Specs

 // Object coders

static NSString *kHelloWorld = @"Hello World!";

- (void)shouldEncodeDataWithIdentityCoder {	
	NSData *data = [kHelloWorld dataUsingEncoding:NSUTF8StringEncoding];
	RCResource *resource = [self.service resource:@"test/encoding"];
	RCResponse *response = [resource put:data];
	STAssertTrue([response.request.payloadEncoder isKindOfClass:[RCIdentityCoder class]], @"Payload encoder should have been an identity coder: %@", response.request.payloadEncoder);
	NSString *bodyString = [[NSString alloc] initWithData:response.request.URLRequest.HTTPBody encoding:NSUTF8StringEncoding];
	STAssertEqualObjects(kHelloWorld, bodyString, @"Encoded body should equal input");
}

- (void)shouldEncodeStringWithTextCoder {
	RCResource *resource = [self.service resource:@"test/encoding"];
	RCResponse *response = [resource put:kHelloWorld];
	STAssertTrue([response.request.payloadEncoder isKindOfClass:[RCTextCoder class]], @"Payload encoder should have been a text coder: %@", response.request.payloadEncoder);
	NSString *bodyString = [[NSString alloc] initWithData:response.request.URLRequest.HTTPBody encoding:NSUTF8StringEncoding];
	STAssertEqualObjects(kHelloWorld, bodyString, @"Encoded body should equal input");
}

- (void)shouldEncodeImageWithImageCoder {
	UIImage *image =  [UIImage imageNamed:@"t_hero.png"];
	RCResource *resource = [self.service resource:@"test/encoding"];
	RCResponse *response = [resource put:image];
	STAssertTrue([response.request.payloadEncoder isKindOfClass:[RCImageCoder class]], @"Payload encoder should have been an image coder: %@", response.request.payloadEncoder);
	NSData *bodyData = response.request.URLRequest.HTTPBody;
	STAssertEqualObjects(UIImagePNGRepresentation(image), bodyData, @"Encoded body should equal input");
}

// JSON coding

- (void)shouldEncodeJSONWhenContentTypeSet {
	NSDictionary *payload = [NSDictionary dictionaryWithObject:kHelloWorld forKey:@"message"];
	RCResource *resource = [self.service resource:@"test/encoding"];
	resource.contentType = RESTClientContentTypeJSON;
	RCResponse *response = [resource put:payload];	
	STAssertTrue([response.request.payloadEncoder isKindOfClass:[RCJSONCoder class]], @"Payload encoder should have been a JSON coder: %@", response.request.payloadEncoder);
	NSDictionary *bodyDictionary = [NSJSONSerialization JSONObjectWithData:response.request.URLRequest.HTTPBody options:NSJSONReadingAllowFragments error:NULL];
	STAssertEqualObjects(payload, bodyDictionary, @"Encoded body should equal input");
}

- (void)shouldDecodeJSONWhenServerSendsContentType {
	NSDictionary *content = [NSDictionary dictionaryWithObject:kHelloWorld forKey:@"message"];
	RCResource *resource = [self.service resource:@"test/decoding/json/content-type"];
	RCResponse *response = [resource get];	
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCJSONCoder class]], @"Response decoder should have been a JSON coder: %@", response.request.responseDecoder);
	STAssertEqualObjects(content, response.result, @"Response#result should equal content");
}

- (void)shouldDecodeJSONUsingAcceptWhenServerSendsWrongContentType {
	NSDictionary *content = [NSDictionary dictionaryWithObject:kHelloWorld forKey:@"message"];
	RCResource *resource = [self.service resource:@"test/decoding/json/wrong-content-type"];
	[resource setValue:@"application/json" forHeaderField:kRESTClientHTTPHeaderAccept];
	RCResponse *response = [resource get];	
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCJSONCoder class]], @"Response decoder should have been a JSON coder: %@", response.request.responseDecoder);
	STAssertEqualObjects(content, response.result, @"Response#result should equal content");
}

// XML coding

- (void)shouldEncodeXMLWhenContentTypeSet {
	NSDictionary *payload = [NSDictionary dictionaryWithObject:kHelloWorld forKey:@"message"];
	RCResource *resource = [self.service resource:@"test/encoding"];
	resource.contentType = RESTClientContentTypeXML;
	RCResponse *response = [resource put:payload];	
	STAssertTrue([response.request.payloadEncoder isKindOfClass:[RCXMLCoder class]], @"Payload encoder should have been an XML coder: %@", response.request.payloadEncoder);
	NSDictionary *bodyDictionary = [NSPropertyListSerialization propertyListWithData:response.request.URLRequest.HTTPBody options:NSPropertyListImmutable format:NULL error:NULL];
	STAssertEqualObjects(payload, bodyDictionary, @"Encoded body should equal input");
}

- (void)shouldDecodeXMLWhenServerSendsContentType {
	NSDictionary *content = [NSDictionary dictionaryWithObject:kHelloWorld forKey:@"message"];
	RCResource *resource = [self.service resource:@"test/decoding/plist/content-type"];
	RCResponse *response = [resource get];	
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCXMLCoder class]], @"Response decoder should have been an XML coder: %@", response.request.responseDecoder);
	STAssertEqualObjects(content, response.result, @"Response#result should equal content");
}

- (void)shouldDecodeXMLUsingAcceptWhenServerSendsWrongContentType {
	NSDictionary *content = [NSDictionary dictionaryWithObject:kHelloWorld forKey:@"message"];
	RCResource *resource = [self.service resource:@"test/decoding/plist/wrong-content-type"];
	[resource setValue:@"application/xml" forHeaderField:kRESTClientHTTPHeaderAccept];
	RCResponse *response = [resource get];	
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCXMLCoder class]], @"Response decoder should have been an XML coder: %@", response.request.responseDecoder);
	STAssertEqualObjects(content, response.result, @"Response#result should equal content");
}



// Text coding


- (void)shouldDecodeTextWhenServerSendsContentType {
	RCResource *resource = [self.service resource:@"test/decoding/text/content-type"];
	RCResponse *response = [resource get];	
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCTextCoder class]], @"Response decoder should have been a text coder: %@", response.request.responseDecoder);
	STAssertEqualObjects(kHelloWorld, response.result, @"Response#result should equal text");
}

- (void)shouldDecodeTextUsingAcceptWhenServerSendsWrongContentType {
	RCResource *resource = [self.service resource:@"test/decoding/text/wrong-content-type"];
	[resource setValue:@"text/plain" forHeaderField:kRESTClientHTTPHeaderAccept];
	RCResponse *response = [resource get];	
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCTextCoder class]], @"Response decoder should have been a text coder: %@", response.request.responseDecoder);
	STAssertEqualObjects(kHelloWorld, response.result, @"Response#result should equal text");
}


// Image coding

- (void)shouldDecodeImageWhenServerSendsContentType {
	UIImage *image =  [UIImage imageNamed:@"t_hero.png"];
	RCResource *resource = [self.service resource:@"test/decoding/image/content-type"];
	RCResponse *response = [resource get];	
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCImageCoder class]], @"Response decoder should have been an image coder: %@", response.request.responseDecoder);
	NSData *imageData = UIImagePNGRepresentation(image);
	NSData *resultImageData = UIImagePNGRepresentation(response.result);
	STAssertEqualObjects(imageData, resultImageData, @"Response#result should equal image");
}

- (void)shouldDecodeImageUsingAcceptWhenServerSendsWrongContentType {
	UIImage *image =  [UIImage imageNamed:@"t_hero.png"];
	RCResource *resource = [self.service resource:@"test/decoding/image/wrong-content-type"];
	[resource setValue:@"image/png" forHeaderField:kRESTClientHTTPHeaderAccept];
	RCResponse *response = [resource get];	
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCImageCoder class]], @"Response decoder should have been an image coder: %@", response.request.responseDecoder);
	NSData *imageData = UIImagePNGRepresentation(image);
	NSData *resultImageData = UIImagePNGRepresentation(response.result);
	STAssertEqualObjects(imageData, resultImageData, @"Response#result should equal image");
}


// Request-based coding



- (void)shouldEncodeBasedOnFileExtension {
	NSDictionary *payload = [NSDictionary dictionaryWithObject:kHelloWorld forKey:@"message"];
	RCResource *resource = [self.service resource:@"test/encoding.json"];
//	resource.contentType = RESTClientContentTypeJSON;
	RCResponse *response = [resource put:payload];
	STAssertTrue([response.request.payloadEncoder isKindOfClass:[RCJSONCoder class]], @"Payload encoder should have been a JSON coder: %@", response.request.payloadEncoder);
	NSDictionary *bodyDictionary = [NSJSONSerialization JSONObjectWithData:response.request.URLRequest.HTTPBody options:NSJSONReadingAllowFragments error:NULL];
	STAssertEqualObjects(payload, bodyDictionary, @"Encoded body should equal input");
}

- (void)shouldDecodeBasedOnFileExtensionWhenServerSendsWrongContentType {
	NSDictionary *content = [NSDictionary dictionaryWithObject:kHelloWorld forKey:@"message"];
	RCResource *resource = [self.service resource:@"test/decoding/wrong-content-type.json"];
	RCResponse *response = [resource get];
	STAssertTrue(response.success, @"Response should have succeeded: %@", response);
	STAssertTrue([response.request.responseDecoder isKindOfClass:[RCJSONCoder class]], @"Response decoder should have been a JSON coder: %@", response.request.responseDecoder);
	STAssertEqualObjects(content, response.result, @"Response#result should equal content");
}


@end
