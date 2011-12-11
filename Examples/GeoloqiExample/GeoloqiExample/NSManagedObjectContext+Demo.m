//
//  NSManagedObjectContext+Demo.m
//  GeoloqiExample
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "NSManagedObjectContext+Demo.h"

@implementation NSManagedObjectContext (Demo)

- (NSManagedObjectContext *) newChildContext {
    NSManagedObjectContext *child = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    child.parentContext = self;
    return child;
}

@end
