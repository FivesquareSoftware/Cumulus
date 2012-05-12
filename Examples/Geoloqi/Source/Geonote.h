//
//  Geonote.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/11/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Geonote : NSManagedObject

@property (nonatomic, retain) NSNumber * radius;
@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSString * placeId;
@property (nonatomic, retain) NSString * placeName;
@property (nonatomic, retain) NSString * text;
@property (nonatomic, retain) NSString * geonoteID;

@end
