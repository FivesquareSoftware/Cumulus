//
//  NSObject+Demo.m
//  RESTClientExample
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "NSObject+Demo.h"

@implementation NSObject (Demo)

@dynamic appDelegate;
- (AppDelegate *) appDelegate {
	return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

@dynamic mainContext;
- (NSManagedObjectContext *) mainContext {
	return self.appDelegate.managedObjectContext;
}

@end
