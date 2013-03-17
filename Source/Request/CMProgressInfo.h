//
//  CMProgressInfo.h
//  Cumulus
//
//  Created by John Clayton on 5/2/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CMProgressInfo : NSObject

@property (nonatomic, strong) NSURL *URL;
@property (nonatomic, strong) NSURL *tempFileURL;
@property (nonatomic, strong) NSString *filename;
@property (nonatomic, strong) NSNumber *progress;

@end
