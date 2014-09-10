//
//  CMResource_Protected.h
//  Cumulus
//
//  Created by John Clayton on 8/7/13.
//  Copyright (c) 2013 Fivesquare Software, LLC. All rights reserved.
//

#import "Cumulus.h"

@class CMRequestQueue;

@interface CMResource ()

@property (nonatomic, strong) CMRequestQueue *requestQueue;

@end
