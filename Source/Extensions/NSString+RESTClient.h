//
//  NSString+RESTClient.h
//  RESTClient
//
//  Created by John Clayton on 2/20/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (RESTClient)

/** Returns a substring matching what would be a query string if the string represented a URL. Does not include the question mark. */
- (NSString *) queryString;

- (NSString *) queryString:(NSString **)prefix;

@end
