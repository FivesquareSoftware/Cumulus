//
//  Location+Demo.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "Location+Demo.h"

@implementation Location (Demo)

@dynamic coordinate;
- (CLLocationCoordinate2D) coordinate {
	CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
	return coordinate;
}

@end
