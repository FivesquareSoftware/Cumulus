//
//  CMResourceScope.h
//  Cumulus
//
//  Created by John Clayton on 5/6/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMResourceContextScope : NSObject
@property (nonatomic, copy) void(^shutdownHook)();
+ (id) withScopeObject:(id)scopeObject;
@end

@interface NSObject (CMResourceContextScope)
@property (nonatomic, strong) CMResourceContextScope *CMResourceScope;
@end

