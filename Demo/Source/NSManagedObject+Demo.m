//
//  NSManagedObject+Demo.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/11/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "NSManagedObject+Demo.h"

@implementation NSManagedObject (Demo)


+ (NSString *) entityName {
	return NSStringFromClass(self);
}

+ (id) firstInContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
	[fetchRequest setFetchBatchSize:1];
	[fetchRequest setFetchLimit:1];
		
	__block NSError *error = nil;
	__block NSArray *results = nil;
	
	[context performBlockAndWait:^{
		NSError __autoreleasing *localError = nil;
		results = [context executeFetchRequest:fetchRequest error:&localError];
		if (localError) {
			error = localError;
		}
	}];
	NSAssert3(error == nil, @"Error fetching first for fetchRequest %@ %@ (%@)",fetchRequest, [error localizedDescription], [error userInfo]);
	
	return [results lastObject];
}


+ (id) allInContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
	
	__block NSError *error = nil;
	__block NSArray *results = nil;
	
	[context performBlockAndWait:^{
		NSError __autoreleasing *localError = nil;
		results = [context executeFetchRequest:fetchRequest error:&localError];
		if (localError) {
			error = localError;
		}
	}];
	NSAssert3(error == nil, @"Error fetching all for fetchRequest %@ %@ (%@)",fetchRequest, [error localizedDescription], [error userInfo]);
	return results;
}

+ (void) deleteAllInContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
	[fetchRequest setIncludesPropertyValues:NO];

	__block NSError *error = nil;
	__block NSArray *results = nil;
	[context performBlockAndWait:^{
		__autoreleasing NSError *localError = nil;
		results = [context executeFetchRequest:fetchRequest error:&localError];
		if (localError) {
			error = localError;
		}
	}];
	NSAssert3(error == nil, @"Error fetching for deletion %@ %@ (%@)",fetchRequest, [error localizedDescription], [error userInfo]);
	 [context performBlockAndWait:^{
		 for (NSManagedObject *found in results) {
			 [context deleteObject:found];
		 }
	 }];
}

+ (id) findOrCreateWithPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
	NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
	[fetchRequest setPredicate:predicate];
	[fetchRequest setFetchBatchSize:1];
	[fetchRequest setFetchLimit:1];
	
	__block NSError *error = nil;
	__block NSArray *results = nil;
	
	[context performBlockAndWait:^{
		NSError __autoreleasing *localError = nil;
		results = [context executeFetchRequest:fetchRequest error:&localError];
		if (localError) {
			error = localError;
		}
	}];
	NSAssert3(error == nil, @"Error finding for fetchRequest %@ %@ (%@)",fetchRequest, [error localizedDescription], [error userInfo]);
	
	id found = [results lastObject];
	if(found == nil) {
		found = [NSEntityDescription insertNewObjectForEntityForName:[self entityName] inManagedObjectContext:context];
	}
	return found;
}



@end
