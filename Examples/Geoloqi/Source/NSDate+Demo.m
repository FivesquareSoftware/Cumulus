//
//  NSDate+Demo.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/11/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "NSDate+Demo.h"

@implementation NSDate (Demo)

+ (NSDate *) dateWithISO8601String:(NSString *)dateString { //2011-03-26T15:36:00-07:00
	static NSDateFormatter *formatter = nil;
	@synchronized(self) {
		if (nil == formatter) {
			formatter = [[NSDateFormatter alloc] init];
			[formatter setDateFormat:@"YYYY-mm-ddThh:mm:ssZZ:ZZ"];
		}
	}
	return [formatter dateFromString:dateString];
}

@end
