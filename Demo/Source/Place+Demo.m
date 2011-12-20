//
//  Place+Demo.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "Place+Demo.h"

@implementation Place (Demo)

@dynamic coordinate;
- (CLLocationCoordinate2D) coordinate {
	CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake([self.latitude doubleValue], [self.longitude doubleValue]);
	return coordinate;
}

@end
