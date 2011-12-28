//
//  FetchedResultsMapViewController.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CoordinateLike.h"


@interface FetchedResultsMapViewController : UIViewController <NSFetchedResultsControllerDelegate, MKMapViewDelegate> {
@protected
	NSFetchedResultsController *fetchedResultsController_;
}

@property (strong, nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (readonly, nonatomic) NSManagedObjectContext *managedObjectContext;

@property (nonatomic, weak) IBOutlet MKMapView *mapView;

- (void) configureAnnotation:(MKPointAnnotation *)annotation withCoordinateLike:(id<CoordinateLike>)coordinateLike;

@end
