//
//  CoordinateLike.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol CoordinateLike <NSObject>

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;


@end
