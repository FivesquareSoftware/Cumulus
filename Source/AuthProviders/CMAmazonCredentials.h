//
//  CMAmazonCredentials.h
//  Cumulus
//
//  Created by John Clayton on 8/16/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


/** Represents a set of Amazon S3 credentials. */
@protocol CMAmazonCredentials <NSObject>

@property (nonatomic, strong) NSString *accessKey;
@property (nonatomic, strong) NSString *secretKey;
@property (nonatomic, strong) NSString *securityToken;
@property (nonatomic, strong) NSDate *expirationDate;

@property (nonatomic, readonly) BOOL expired;
@property (nonatomic, readonly) BOOL valid;

@end

@interface CMAmazonCredentials : NSObject <CMAmazonCredentials, NSCoding>

@end
