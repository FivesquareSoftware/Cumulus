//
//	CMFixtureRequest.m
//	Cumulus
//
//	Created by John Clayton on 5/2/12.
//	Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMFixtureRequest.h"
#import "CMRequest+Protected.h"

#import "Cumulus.h"
#import "CMFixtureHTTPResponse.h"

// Allow access to the private timeout method in the CMRequest base class
@interface CMRequest ()
- (void) timeoutFired:(NSTimer *)timer;
@end


@interface CMFixtureRequest ()
@end

@implementation CMFixtureRequest


@synthesize fixtureData=_fixtureData;
- (NSData *) fixtureData {
	if (_fixture == nil) {
		return nil;
	}
	
	if (_fixtureData == nil) {
		
		// If a file system URL was supplied, load fixture data from the file system
		if ([_fixture isKindOfClass:[NSURL class]] && [_fixture isFileURL]) {
			NSURL *fixtureURL = _fixture;
			NSString *fixturePath = [fixtureURL path];
			NSFileManager *fm = [NSFileManager new];
			if ([fm fileExistsAtPath:fixturePath]) {
				NSString *MIMEType = [self mimeTypeForFileAtPath:fixturePath];
				_expectedContentType = MIMEType;
				
				_fixtureData = [NSData dataWithContentsOfFile:fixturePath];
			}
		}
		else {
			// First, check for obvious conversions of fixture by class
			id<CMCoder> fixtureEncoder = [CMCoder coderForObject:_fixture];
			
			//Then look at the accept header, because we won't have a response from the server
			NSString *contentType = self.acceptHeader;
			
			if (nil == fixtureEncoder) { // we have an non-literal object type, figure out encoding based on content type
				if (contentType && contentType.length > 0) {
					fixtureEncoder = [CMCoder coderForMimeType:contentType];
				}
			}
			
			NSAssert2(fixtureEncoder != nil,  @"Unable to convert fixture to HTTPBody using fixture.class: %@, Accept: %@. Make sure you are using a compatible object type or have set an appropriate Accept.", NSStringFromClass([_fixture class]), contentType);
			
			_fixtureData = [fixtureEncoder encodeObject:_fixture];
			
			// set up the expected content type
			if (self.acceptHeader && self.acceptHeader.length) {
				_expectedContentType = self.acceptHeader;
			}
			else if ([fixtureEncoder isKindOfClass:[CMTextCoder class]]) {
				_expectedContentType = @"text/plain"; // could be html, but no way to tell, really
			}
			else if ([fixtureEncoder isKindOfClass:[CMImageCoder class]]) {
				uint8_t c;
				[_fixtureData getBytes:&c length:1];
				
				switch (c) {
					case 0xFF:
						_expectedContentType = @"image/jpeg";
						break;
					case 0x89:
						_expectedContentType = @"image/png";
						break;
					case 0x47:
						_expectedContentType = @"image/gif";
						break;
					case 0x49:
					case 0x4D:
						_expectedContentType = @"image/tiff";
						break;
				}
			}
		}
	}
	return _fixtureData;
}

- (id)initWithURLRequest:(NSURLRequest *)URLRequest fixture:(id)fixture {
	self = [super initWithURLRequest:URLRequest];
	if (self) {
		_fixture = fixture;
	}
	return self;
}

- (BOOL) start {
	NSAssert(NO == self.started, @"Attempting to start a request that has already been started, canceled or finished");
	if (NO == self.canStart) {
		return NO;
	}
	
	self.started = YES;
	
	[CMRequest incrementRequestCountFor:self];
	
	CMLog(@"%@", self);
	
	[self handleConnectionDidSendData];
	[self handleConnectionDidReceiveData];
	
	
	if (self.timeout > 0) {
		NSTimer *timeoutTimer = [NSTimer timerWithTimeInterval:self.timeout target:self selector:@selector(timeoutFired:) userInfo:nil repeats:NO];
		[[NSRunLoop mainRunLoop] addTimer:timeoutTimer forMode:NSDefaultRunLoopMode];
		self.timeoutTimer = timeoutTimer;
	}
	
	[self.data appendData:self.fixtureData];
	
	
	id fakeResponse = [[CMFixtureHTTPResponse alloc] initWithURL:[self.URLRequest URL] MIMEType:_expectedContentType expectedContentLength:(NSInteger)[self.data length] textEncodingName:@"NSUTF8StringEncoding"];
	[fakeResponse setStatusCode:200];
	if (_expectedContentType) {
		[fakeResponse setAllHeaderFields:[NSDictionary dictionaryWithObject:_expectedContentType forKey:kCumulusHTTPHeaderContentType]];
	}
	self.URLResponse = fakeResponse;
	
	self.expectedContentLength = [self.data length];
	self.receivedContentLength = [self.data length];
	
	[self handleConnectionFinished];
	
	return YES;
}


@end
