//
//  FetchedResultsMapViewController.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "FetchedResultsMapViewController.h"


@interface FetchedResultsMapViewController()
- (void) addAnnotationsForCoordinates:(NSArray *)coordinates;
- (MKCoordinateRegion)regionFromCoordinates:(NSArray *)coordinates;
@end

@implementation FetchedResultsMapViewController


// ========================================================================== //

#pragma mark - Properties

@synthesize fetchedResultsController=fetchedResultsController_;
@synthesize mapView=mapView_;

- (NSFetchedResultsController *) fetchedResultsController {
	NSAssert(NO, @"Implement in your subclass");
	return nil;
}


@dynamic managedObjectContext;
- (NSManagedObjectContext *) managedObjectContext {
	return self.appDelegate.mainContext;
}


// ========================================================================== //

#pragma mark - Object


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}


- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}


// ========================================================================== //

#pragma mark - View Controller



- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
	
	self.fetchedResultsController = nil;
}

- (void)viewWillAppear:(BOOL)animated {
	if (NO == self.appDelegate.isLoggedIn) {
		[self performSegueWithIdentifier:@"showLoginController" sender:self];
	} else {
		[super viewWillAppear:animated];
		[self.fetchedResultsController fetch];
		[self addAnnotationsForCoordinates:self.fetchedResultsController.fetchedObjects];
	}
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


// ========================================================================== //

#pragma mark - NSFetchedResultsControllerDelegate



//NSFetchedResultsChangeInsert = 1,
//NSFetchedResultsChangeDelete = 2,
//NSFetchedResultsChangeMove = 3,
//NSFetchedResultsChangeUpdate = 4


- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
	NSLog(@"Implement %@ in your subclass", NSStringFromSelector(_cmd));
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
		   atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
	NSLog(@"Implement %@ in your subclass", NSStringFromSelector(_cmd));

//	switch(type) {
//		case NSFetchedResultsChangeInsert:
//			break;
//			
//		case NSFetchedResultsChangeDelete:
//			break;
//	}
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
	   atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
	  newIndexPath:(NSIndexPath *)newIndexPath
{
//	NSLog(@"Implement %@ in your subclass", NSStringFromSelector(_cmd));
	
	MKPointAnnotation *annotation = [MKPointAnnotation new];
	annotation.coordinate = [(id<CoordinateLike>)anObject coordinate];
	[self configureAnnotation:annotation withCoordinateLike:(id<CoordinateLike>)anObject];

	
	switch(type) {
		case NSFetchedResultsChangeInsert:
			[self.mapView addAnnotation:annotation];
			break;			
		case NSFetchedResultsChangeDelete:
			[self.mapView removeAnnotation:annotation];
			break;
			
		case NSFetchedResultsChangeUpdate:
			break;
			
		case NSFetchedResultsChangeMove:
			break;
	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	[self.mapView setRegion:[self regionFromCoordinates:controller.fetchedObjects] animated:YES];
}

- (void) configureAnnotation:(MKPointAnnotation *)annotation withCoordinateLike:(id<CoordinateLike>)coordinateLike {
	NSLog(@"Implement %@ in your subclass", NSStringFromSelector(_cmd));
}



// ========================================================================== //

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	NSLog(@"Implement %@ in your subclass", NSStringFromSelector(_cmd));
	return nil;
}

- (void)mapViewWillStartLoadingMap:(MKMapView *)mapView {
	NSLog(@"mapViewWillStartLoadingMap:");
}

- (void)mapViewDidFinishLoadingMap:(MKMapView *)mapView {
	NSLog(@"mapViewDidFinishLoadingMap:");
}

- (void)mapViewDidFailLoadingMap:(MKMapView *)mapView withError:(NSError *)error {
	NSLog(@"mapViewDidFailLoadingMap:withError:%@",error);
}

- (void)mapViewWillStartLocatingUser:(MKMapView *)mapView {
	NSLog(@"mapViewWillStartLocatingUser:");
}

- (void)mapViewDidStopLocatingUser:(MKMapView *)mapView {
	NSLog(@"mapViewDidStopLocatingUser:");
}

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
	NSLog(@"mapView:didUpdateUserLocation:%@",userLocation);
	self.mapView.centerCoordinate = userLocation.coordinate;
}

- (void)mapView:(MKMapView *)mapView didFailToLocateUserWithError:(NSError *)error {
	NSLog(@"mapView:didFailToLocateUserWithError:%@",error);
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
	NSLog(@"mapView:annotationView:calloutAccessoryControlTapped:");
}

// ========================================================================== //

#pragma mark - Map Helpers

- (void) addAnnotationsForCoordinates:(NSArray *)coordinates {
//	[self.mapView removeAnnotations:self.mapView.annotations];
	for (id<CoordinateLike> coordinateLike in coordinates) {
		MKPointAnnotation *annotation = [MKPointAnnotation new];
		annotation.coordinate = coordinateLike.coordinate;
		[self configureAnnotation:annotation withCoordinateLike:coordinateLike];
		[self.mapView addAnnotation:annotation];
	}
	[self.mapView setRegion:[self regionFromCoordinates:coordinates] animated:YES];
}

- (MKCoordinateRegion)regionFromCoordinates:(NSArray *)coordinates {	
	id<CoordinateLike> lastCoordinate = [coordinates lastObject];
	CLLocationCoordinate2D upper = lastCoordinate.coordinate;
    CLLocationCoordinate2D lower = lastCoordinate.coordinate;
	
	for (id<CoordinateLike> coordinateLike in coordinates) {
		CLLocationCoordinate2D coordinate = coordinateLike.coordinate;
        if(coordinate.latitude > upper.latitude) upper.latitude = coordinate.latitude;
        if(coordinate.latitude < lower.latitude) lower.latitude = coordinate.latitude;
        if(coordinate.longitude > upper.longitude) upper.longitude = coordinate.longitude;
        if(coordinate.longitude < lower.longitude) lower.longitude = coordinate.longitude;
	}
	
    // FIND REGION
    MKCoordinateSpan locationSpan;
    locationSpan.latitudeDelta = upper.latitude - lower.latitude;
    locationSpan.longitudeDelta = upper.longitude - lower.longitude;
    CLLocationCoordinate2D locationCenter;
    locationCenter.latitude = (upper.latitude + lower.latitude) / 2;
    locationCenter.longitude = (upper.longitude + lower.longitude) / 2;
	
    MKCoordinateRegion region = MKCoordinateRegionMake(locationCenter, locationSpan);
    return region;
}






@end
