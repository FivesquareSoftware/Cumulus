//
//  RCFixtureRequest.h
//  RESTClient
//
//  Created by John Clayton on 5/2/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "RCRequest.h"

@interface RCFixtureRequest : RCRequest

/** Used as the HTTP response data (a fake successful response is made) */
@property (nonatomic, strong) id fixture;

- (id)initWithURLRequest:(NSURLRequest *)URLRequest fixture:(id)fixture;

@end
