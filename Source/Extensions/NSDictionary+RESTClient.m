//
//  NSDictionary+RESTClient.m
//  RESTClient
//
//  Created by John Clayton on 1/5/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "NSDictionary+RESTClient.h"

#import "NSObject+RESTClient.h"

@implementation NSDictionary (RESTClient)

- (NSString *) toQueryString {
	NSMutableString *queryString = [NSMutableString new];
	[[self allKeys] enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
		NSObject *value = [self objectForKey:key];
		[queryString appendFormat:@"%@%@",((idx > 0) ? @"&" : @""),[value queryWithKey:key]];
	}];
	return queryString;
}

@end
