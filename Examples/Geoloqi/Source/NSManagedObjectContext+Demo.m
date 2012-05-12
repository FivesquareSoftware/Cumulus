//
//  NSManagedObjectContext+Demo.m
//  RESTClientExample
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

- (BOOL) saveChild:(NSError **)error {
	__block NSError *saveError = nil;
	__block BOOL success = NO;
	
	[self performBlockAndWait:^{
		 __autoreleasing NSError *localError = nil;
		if ( (success = [self save:&localError]) ) {
			if (self.parentContext) {
				[self.parentContext performBlock:^{[self.parentContext save:NULL];}];
			}
		}
		if (localError) {
			saveError = localError;
		}
	}];
	if (error) {
		*error = saveError;
	}
	return success;
}

@end
