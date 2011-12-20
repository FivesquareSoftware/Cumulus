//
//  RCOAuthToken.m
//  RESTClient
//
//  Created by John Clayton on 12/19/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import "RCOAuthToken.h"

@implementation RCOAuthToken

@synthesize accessToken=accessToken_;
@synthesize refreshToken=refreshToken_;
@synthesize tokenExpiration=tokenExpiration_;
@synthesize scope=scope_;

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.accessToken forKey:@"accessToken"];
	[aCoder encodeObject:self.refreshToken forKey:@"refreshToken"];
	[aCoder encodeObject:self.tokenExpiration forKey:@"tokenExpiration"];
	[aCoder encodeObject:self.scope forKey:@"scope"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self.accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
	self.refreshToken = [aDecoder decodeObjectForKey:@"refreshToken"];
	self.tokenExpiration = [aDecoder decodeObjectForKey:@"tokenExpiration"];
	self.scope = [aDecoder decodeObjectForKey:@"scope"];
	
	return self;
}


@end
