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
@synthesize accessExpires=accessExpires_;
@synthesize scope=scope_;

- (void)encodeWithCoder:(NSCoder *)aCoder {
	[aCoder encodeObject:self.accessToken forKey:@"accessToken"];
	[aCoder encodeObject:self.refreshToken forKey:@"refreshToken"];
	[aCoder encodeObject:self.accessExpires forKey:@"tokenExpiration"];
	[aCoder encodeObject:self.scope forKey:@"scope"];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self.accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
	self.refreshToken = [aDecoder decodeObjectForKey:@"refreshToken"];
	self.accessExpires = [aDecoder decodeObjectForKey:@"tokenExpiration"];
	self.scope = [aDecoder decodeObjectForKey:@"scope"];
	
	return self;
}

- (NSString *) description {
	return [NSString stringWithFormat:@"%@ (accessToken: %@, refreshToken: %@, accessExpires: %@, scope: %@)",[super description],accessToken_,refreshToken_,accessExpires_,scope_];
}

@end
