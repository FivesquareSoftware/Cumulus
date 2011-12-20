//
//  FetchedResultsMapViewController.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "FetchedResultsMapViewController.h"

#import "CoordinateLike.h"

@interface FetchedResultsMapViewController()
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
	}
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
	NSLog(@"Implement %@ in your subclass", NSStringFromSelector(_cmd));
	
//	switch(type) {
//		case NSFetchedResultsChangeInsert:
//			break;
//			
//		case NSFetchedResultsChangeDelete:
//			break;
//			
//		case NSFetchedResultsChangeUpdate:
//			break;
//			
//		case NSFetchedResultsChangeMove:
//			break;
//	}
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
	NSArray *coordinates = [self.fetchedResultsController fetchedObjects];
	[self.mapView removeAnnotations:self.mapView.annotations];
	for (id<CoordinateLike> coordinateLike in coordinates) {
		MKPointAnnotation *annotation = [MKPointAnnotation new];
		annotation.coordinate = coordinateLike.coordinate;
		[self.mapView addAnnotation:annotation];
	}
	[self.mapView setRegion:[self regionFromCoordinates:coordinates] animated:YES];
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


// ========================================================================== //

#pragma mark - Actions



- (void)insertNewObject
{
    // Create a new instance of the entity managed by the fetched results controller.
    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
    
    // If appropriate, configure the new managed object.
    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
    
    // Save the context.
    NSError *error = nil;
    if (![context save:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
}





@end
