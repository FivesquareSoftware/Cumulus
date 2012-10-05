//
//  SpecHelper.m
//  JSONClient
//
//  Created by John Clayton on 9/10/2009.
//  Copyright 2009 Fivesquare Software, LLC. All rights reserved.
//


#import "SpecHelper.h"

NSString *kTestServerHost = RESTClientTestServer;
NSString *kTestServerHostSSL = RESTClientTestServerSSL;

@implementation SpecHelper

@synthesize item=_item;
@synthesize list=_list;
@synthesize largeList=_largeList;
@synthesize complicatedList=_complicatedList;

- (NSDictionary *) item {
	if (nil == _item) {
		NSString *itemPath = [[NSBundle mainBundle] pathForResource:@"Item" ofType:@"plist"];
		_item = [NSDictionary dictionaryWithContentsOfFile:itemPath];
	}
	return _item;
}

- (NSArray *) list {
	if (nil == _list) {
		_list = [NSMutableArray array];
		for (int i = 0; i < 5; i++) {
			[(NSMutableArray *)_list addObject:self.item];
		}
	}
	return _list;
}

- (NSArray *) largeList {
	if (nil == _largeList) {
		_largeList = [NSMutableArray arrayWithCapacity:10000];
		for (int i = 0; i < 10000; i++) {
			[(NSMutableArray *)_largeList addObject:self.item];
		 }
	}
	return _largeList;
}

- (NSArray *) complicatedList {	
	if (nil == _complicatedList) {
		
		NSMutableDictionary *deepItem = [NSMutableDictionary dictionaryWithDictionary:self.item];
		NSMutableDictionary *nestOne = [NSMutableDictionary dictionaryWithDictionary:self.item];
		NSMutableDictionary *nestTwo = [NSMutableDictionary dictionaryWithDictionary:self.item];
		NSMutableDictionary *nestThree = [NSMutableDictionary dictionaryWithDictionary:self.item];
		NSMutableDictionary *nestFour = [NSMutableDictionary dictionaryWithDictionary:self.item];
		
		[nestThree setObject:nestFour forKey:@"object"];
		[nestTwo setObject:nestThree forKey:@"object"];
		[nestOne setObject:nestTwo forKey:@"object"];
		[deepItem setObject:nestOne forKey:@"object"];
		
		_complicatedList = [NSMutableArray arrayWithCapacity:100];
		for (int i = 0; i < 100; i++) {
			[(NSMutableArray *)_complicatedList addObject:deepItem];
		}
	}
	return _complicatedList;
}

- (void) cleanCaches {
	NSFileManager *fm = [NSFileManager new];
	NSArray *cacheFiles = [fm contentsOfDirectoryAtPath:[RESTClient cachesDir] error:NULL];
	for (NSString *file in cacheFiles) {
		NSString *filePath = [[RESTClient cachesDir] stringByAppendingPathComponent:file];
		NSError *error = nil;
		if (NO == [fm removeItemAtPath:filePath error:&error]) {
			NSLog(@"Could clear file %@: %@ (%@)",filePath, [error localizedDescription], [error userInfo]);
		}
	}	
}



@end


