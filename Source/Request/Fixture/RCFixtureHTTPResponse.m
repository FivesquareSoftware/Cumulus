//
//  RCFixtureHTTPResponse.m
//  RESTClient
//
//  Created by John Clayton on 5/3/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCFixtureHTTPResponse.h"

@implementation RCFixtureHTTPResponse

@synthesize URL=URL_;
@synthesize MIMEType=MIMEType_;
@synthesize expectedContentLength=expectedContentLength_;
@synthesize textEncodingName=textEncodingName_;
@synthesize suggestedFilename=suggestedFilename_;
@synthesize statusCode=statusCode_;
@synthesize allHeaderFields=allHeaderFields_;


- (id)initWithURL:(NSURL *)URL MIMEType:(NSString *)MIMEType expectedContentLength:(NSInteger)length textEncodingName:(NSString *)name {
    self = [super init];
    if (self) {
        URL_ = URL;
		MIMEType_=MIMEType;
		expectedContentLength_=length;
		textEncodingName_=name;
    }
    return self;
}

@end

