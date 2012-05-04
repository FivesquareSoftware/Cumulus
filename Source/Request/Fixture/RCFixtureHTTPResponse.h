//
//  RCFixtureHTTPResponse.h
//  RESTClient
//
//  Created by John Clayton on 5/3/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface RCFixtureHTTPResponse : NSObject

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSString *MIMEType;
@property (nonatomic) long long expectedContentLength;
@property (nonatomic, strong) NSString *textEncodingName;
@property (nonatomic, strong) NSString *suggestedFilename;
@property (nonatomic) NSInteger statusCode;
@property (nonatomic, strong) NSDictionary *allHeaderFields;

- (id)initWithURL:(NSURL *)URL MIMEType:(NSString *)MIMEType expectedContentLength:(NSInteger)length textEncodingName:(NSString *)name;


@end
