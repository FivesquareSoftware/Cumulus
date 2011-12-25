//
//  RecentLocationsController.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FetchedResultsMapViewController.h"

@interface RecentLocationsController : FetchedResultsMapViewController <MKMapViewDelegate>

- (IBAction)resetLocationsAction:(id)sender;

@end
