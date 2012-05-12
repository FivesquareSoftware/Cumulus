//
//  NSManagedObjectContext+Demo.h
//  RESTClientExample
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//



@interface NSManagedObjectContext (Demo)

- (NSManagedObjectContext *) newChildContext;

- (BOOL) saveChild:(NSError **)error;

@end
