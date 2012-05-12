//
//  NSFetchedResultsController+Demo.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/11/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NSFetchedResultsController (Demo)

+ (NSFetchedResultsController *) withEntityName:(NSString *)entityName sortKey:(NSString *)soryKey ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context;

- (void) fetch;

@end
