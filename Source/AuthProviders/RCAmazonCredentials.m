//
//  RCAmazonCredentials.m
//  RESTClient
//
//  Created by John Clayton on 8/16/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCAmazonCredentials.h"

@implementation RCAmazonCredentials


@synthesize accessKey = _accessKey;
@synthesize secretKey = _secretKey;
@synthesize securityToken = _securityToken;
@synthesize expirationDate = _expirationDate;


@dynamic expired;
- (BOOL) expired {
	NSDate *now = [NSDate date];
	NSComparisonResult comparisonResult = [_expirationDate compare:now];
	return (comparisonResult != NSOrderedDescending);
}

@dynamic valid;
- (BOOL) valid {
	return (_accessKey && _accessKey.length && _secretKey && _secretKey.length && NO == self.expired); //???: do we care about token?
}


- (id)initWithCoder:(NSCoder *)decoder {
	_accessKey = [decoder decodeObjectForKey:@"_accessKey"];
	_secretKey = [decoder decodeObjectForKey:@"_secretKey"];
	_securityToken = [decoder decodeObjectForKey:@"_securityToken"];
	_expirationDate = [decoder decodeObjectForKey:@"_expirationDate"];
    return self;
}

- (void) encodeWithCoder:(NSCoder *)encoder {
	[encoder encodeObject:_accessKey forKey:@"_accessKey"];
	[encoder encodeObject:_secretKey forKey:@"_secretKey"];
	[encoder encodeObject:_securityToken forKey:@"_securityToken"];
	[encoder encodeObject:_expirationDate forKey:@"_expirationDate"];
}

@end
