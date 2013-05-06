//
//  CMResourceContextScope.m
//  Cumulus
//
//  Created by John Clayton on 5/6/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceContextScope.h"

#import <objc/runtime.h>

@implementation CMResourceContextScope
- (void)dealloc {
	if (_shutdownHook) {
		_shutdownHook();
	}
}
+ (id) withScopeObject:(id)scopeObject {
	CMResourceContextScope *contextScope = [self new];
	[scopeObject setCMResourceScope:contextScope];
	return contextScope;
}
@end

static const NSString *kNSObject_CMResourceContextScope_resourceScope;
@implementation NSObject (CMResourceContextScope)
@dynamic CMResourceScope;
- (CMResourceContextScope *) CMResourceScope {
	CMResourceContextScope *scope = objc_getAssociatedObject(self, &kNSObject_CMResourceContextScope_resourceScope);
	return scope;
}
- (void) setCMResourceScope:(CMResourceContextScope *)scope {
	objc_setAssociatedObject(self, &kNSObject_CMResourceContextScope_resourceScope, scope, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
@end
