//
//  NSString+Cumulus.m
//  Cumulus
//
//  Created by John Clayton on 2/20/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "NSString+Cumulus.h"

@implementation NSString (Cumulus)

- (NSString *) queryString {
	NSString *queryString = nil;
	NSRange queryRange = [self rangeOfString:@"?"];
	if (queryRange.location != NSNotFound) {
		queryString = [self substringFromIndex:queryRange.location+1];
	}
	return queryString;
}

- (NSString *) queryString:(NSString **)prefix {
	NSString *queryString = nil;
	NSRange queryRange = [self rangeOfString:@"?"];
	if (queryRange.location != NSNotFound) {
		queryString = [self substringFromIndex:queryRange.location+1];
		if (prefix) {
			*prefix = [self substringToIndex:queryRange.location];
		}
	}
	return queryString;
}

@end
