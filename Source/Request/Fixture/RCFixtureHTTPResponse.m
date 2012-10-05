//
//  RCFixtureHTTPResponse.m
//  RESTClient
//
//  Created by John Clayton on 5/3/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCFixtureHTTPResponse.h"

@implementation RCFixtureHTTPResponse

@synthesize URL=_URL;
@synthesize MIMEType=_MIMEType;
@synthesize expectedContentLength=_expectedContentLength;
@synthesize textEncodingName=_textEncodingName;
@synthesize suggestedFilename=_suggestedFilename;
@synthesize statusCode=_statusCode;
@synthesize allHeaderFields=_allHeaderFields;


- (id)initWithURL:(NSURL *)URL MIMEType:(NSString *)MIMEType expectedContentLength:(NSInteger)length textEncodingName:(NSString *)name {
    self = [super init];
    if (self) {
        _URL = URL;
		_MIMEType=MIMEType;
		_expectedContentLength=length;
		_textEncodingName=name;
    }
    return self;
}

@end

