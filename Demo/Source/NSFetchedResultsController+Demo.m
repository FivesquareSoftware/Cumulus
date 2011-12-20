//
//  NSFetchedResultsController+Demo.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/11/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "NSFetchedResultsController+Demo.h"

@implementation NSFetchedResultsController (Demo)

+ (NSFetchedResultsController *) withEntityName:(NSString *)entityName sortKey:(NSString *)soryKey ascending:(BOOL)ascending inContext:(NSManagedObjectContext *)context {
	NSFetchedResultsController *controller = nil;
	
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:entityName];
    [fetchRequest setFetchBatchSize:20];
	if (soryKey.length) {
		NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:soryKey ascending:ascending];
		[fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
	}
	
	controller = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:context sectionNameKeyPath:nil cacheName:nil];
    
    return controller;
}

- (void) fetch {
	NSError *error = nil;
	[self performFetch:&error];
	NSAssert2(nil == error, @"Error performing fetch request: %@ (%@)", [error localizedDescription], [error userInfo]);
}


@end
