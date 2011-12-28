//
//  NSObject+Demo.h
//  RESTClientExample
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "AppDelegate.h"

@interface NSObject (Demo)

@property (readonly, nonatomic) AppDelegate *appDelegate;
@property (readonly, nonatomic) NSManagedObjectContext *mainContext;

@end
