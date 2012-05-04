//
//  RCFixtureRequest.m
//  RESTClient
//
//  Created by John Clayton on 5/2/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCFixtureRequest.h"
#import "RCRequest+Protected.h"

#import "RESTClient.h"
#import "RCFixtureHTTPResponse.h"

@interface RCFixtureRequest ()

@property (nonatomic, readonly) NSData *fixtureData;

@end

@implementation RCFixtureRequest

@synthesize fixture=fixture_;

@dynamic fixtureData;
- (NSData *) fixtureData {
	if (fixture_ == nil) {
		return nil;
	}
	
	// First, check for obvious conversions of fixture by class
	id<RCCoder> fixtureEncoder = [RCCoder coderForObject:fixture_];
	
	//Then look at the accept header, because we won't have a response from the server
	NSString *contentType = [self.URLRequest valueForHTTPHeaderField:kRESTClientHTTPHeaderAccept];
	
	if (nil == fixtureEncoder) { // we have an non-literal object type, figure out encoding based on content type
		if (contentType && contentType.length > 0) {
			fixtureEncoder = [RCCoder coderForMimeType:contentType];
		}
	}
	
	NSAssert2(fixtureEncoder != nil,  @"Unable to convert fixture to HTTPBody using fixture.class: %@, Accept: %@. Make sure you are using a compatible object type or have set an appropriate Accept.", NSStringFromClass([fixture_ class]), contentType);

	NSData *fixtureData = [fixtureEncoder encodeObject:fixture_];
	return fixtureData;
}

- (id)initWithURLRequest:(NSURLRequest *)URLRequest fixture:(id)fixture {
    self = [super initWithURLRequest:URLRequest];
    if (self) {
        fixture_ = fixture;
    }
    return self;
}

- (void) start {
	NSAssert(NO == self.started, @"Attempting to start a request that has already been started, canceled or finished");
	if (NO == self.canStart) {
		return;
	}
	
    self.started = YES;
	
	RCLog(@"%@", self);
	
	[self handleConnectionDidSendData];
	[self handleConnectionDidReceiveData];
	
	
	if (self.timeout > 0) {
		NSTimer *timeoutTimer = [NSTimer timerWithTimeInterval:self.timeout target:self selector:@selector(timeoutFired:) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:timeoutTimer forMode:NSDefaultRunLoopMode];		
		self.timeoutTimer = timeoutTimer;
	}	
	
	[self.data appendData:self.fixtureData];
	NSString *mimeType = [self.URLRequest valueForHTTPHeaderField:kRESTClientHTTPHeaderAccept];

	id fakeResponse = [[RCFixtureHTTPResponse alloc] initWithURL:[self.URLRequest URL] MIMEType:mimeType expectedContentLength:(NSInteger)[self.data length] textEncodingName:@"NSUTF8StringEncoding"];
	[fakeResponse setStatusCode:200];
	[fakeResponse setAllHeaderFields:[NSDictionary dictionaryWithObject:self.acceptHeader forKey:kRESTClientHTTPHeaderContentType]];
	self.URLResponse = fakeResponse;
	
	self.expectedContentLength = [self.data length];
	self.receivedContentLength = [self.data length];
	
	[self handleConnectionFinished];
}


@end
