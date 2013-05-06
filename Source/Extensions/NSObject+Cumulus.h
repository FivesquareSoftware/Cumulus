//
//  NSObject+Cumulus.h
//  Cumulus
//
//  Created by John Clayton on 1/4/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Cumulus)

- (NSString *) queryEncodingWithKey:(NSString *)key;

/** Performs a block of requests in the scope of the receiver: when the receiver is deallocated, any remaining requests are canceled. 
 *  @see [CMResourceContext performRequests:inScope:]
 */
- (void) performRequestsInScope:(void(^)())work;

@end
