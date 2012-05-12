//
//  Place.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/11/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Place : NSManagedObject

@property (nonatomic, retain) NSString * placeID;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * radius;
@property (nonatomic, retain) NSString * displayName;
@property (nonatomic, retain) NSString * placeDescription;

@end
