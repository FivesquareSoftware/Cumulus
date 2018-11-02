//
//  NSObject+Cumulus.m
//  Cumulus
//
//  Created by John Clayton on 1/4/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "NSObject+Cumulus.h"

#import "CMResourceContext.h"
#import "NSDictionary+Cumulus.h"

@implementation NSObject (Cumulus)

- (NSString *) queryEncodingWithKey:(NSString *)key {
	NSString *queryString = nil;
	if ([self isKindOfClass:[NSArray class]]) {
		NSMutableString *arrayString = [NSMutableString new];
		[(NSArray *)self enumerateObjectsUsingBlock:^(id value, NSUInteger idx, BOOL *stop) {
			[arrayString appendFormat:@"%@%@[]=%@",((idx > 0) ? @"&" : @""), key,[value description]];
		}];
		queryString = [NSString stringWithString:arrayString];
	}
	else if ([self isKindOfClass:[NSString class]]) {
		queryString = [NSString stringWithFormat:@"%@=%@",key,self];
	}
	else if ([self isKindOfClass:[NSDictionary class]]) {
		queryString = [(NSDictionary *)self toQueryString];
	}
	else {
		queryString = [NSString stringWithFormat:@"%@=%@",key,[self description]];
	}
	return queryString;
}

- (void) performRequestsInScope:(void(^)(void))work {
	CMResourceContext *context = [CMResourceContext withName:[NSString stringWithFormat:@"%@.%p",NSStringFromClass([self class]),self]];
	[context performRequests:work inScope:self];
}


@end
