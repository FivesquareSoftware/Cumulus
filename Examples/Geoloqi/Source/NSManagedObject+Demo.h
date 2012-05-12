//
//  NSManagedObject+Demo.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/11/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSManagedObject (Demo)

+ (NSString *) entityName;
+ (id) firstInContext:(NSManagedObjectContext *)context;
+ (id) allInContext:(NSManagedObjectContext *)context;
+ (void) deleteAllInContext:(NSManagedObjectContext *)context;
+ (id) findOrCreateWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

@end
