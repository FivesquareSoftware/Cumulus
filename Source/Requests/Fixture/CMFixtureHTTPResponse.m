//
//	CMFixtureHTTPResponse.m
//	Cumulus
//
//	Created by John Clayton on 5/3/12.
//	Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMFixtureHTTPResponse.h"

@implementation CMFixtureHTTPResponse



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

