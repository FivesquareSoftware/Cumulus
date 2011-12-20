//
//  RCOAuthToken.h
//  RESTClient
//
//  Created by John Clayton on 12/19/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCOAuthToken : NSObject <NSCoding>

@property (nonatomic, strong) NSString *accessToken;
@property (nonatomic, strong) NSString *refreshToken;
@property (nonatomic, strong) NSDate *tokenExpiration;
@property (nonatomic, strong) NSString *scope;

@end
