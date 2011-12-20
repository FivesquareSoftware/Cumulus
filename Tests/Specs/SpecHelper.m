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

@synthesize item=item_;
@synthesize list=list_;
@synthesize largeList=largeList_;
@synthesize complicatedList=complicatedList_;

- (NSDictionary *) item {
	if (nil == item_) {
		NSString *itemPath = [[NSBundle mainBundle] pathForResource:@"Item" ofType:@"plist"];
		item_ = [NSDictionary dictionaryWithContentsOfFile:itemPath];
	}
	return item_;
}

- (NSArray *) list {
	if (nil == list_) {
		list_ = [NSMutableArray array];
		for (int i = 0; i < 5; i++) {
			[(NSMutableArray *)list_ addObject:self.item];
		}
	}
	return list_;
}

- (NSArray *) largeList {
	if (nil == largeList_) {
		largeList_ = [NSMutableArray arrayWithCapacity:10000];
		for (int i = 0; i < 10000; i++) {
			[(NSMutableArray *)largeList_ addObject:self.item];
		 }
	}
	return largeList_;
}

- (NSArray *) complicatedList {	
	if (nil == complicatedList_) {
		
		NSMutableDictionary *deepItem = [NSMutableDictionary dictionaryWithDictionary:self.item];
		NSMutableDictionary *nestOne = [NSMutableDictionary dictionaryWithDictionary:self.item];
		NSMutableDictionary *nestTwo = [NSMutableDictionary dictionaryWithDictionary:self.item];
		NSMutableDictionary *nestThree = [NSMutableDictionary dictionaryWithDictionary:self.item];
		NSMutableDictionary *nestFour = [NSMutableDictionary dictionaryWithDictionary:self.item];
		
		[nestThree setObject:nestFour forKey:@"object"];
		[nestTwo setObject:nestThree forKey:@"object"];
		[nestOne setObject:nestTwo forKey:@"object"];
		[deepItem setObject:nestOne forKey:@"object"];
		
		complicatedList_ = [NSMutableArray arrayWithCapacity:100];
		for (int i = 0; i < 100; i++) {
			[(NSMutableArray *)complicatedList_ addObject:deepItem];
		}
	}
	return complicatedList_;
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


