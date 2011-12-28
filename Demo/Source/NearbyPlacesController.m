//
//  NearbyPlacesController.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "NearbyPlacesController.h"

#import "Place.h"

@interface NearbyPlacesController()
@property (strong, nonatomic) RCResource *placesResource;
- (void) refreshFromRemoteResource;
@end


@implementation NearbyPlacesController

// ========================================================================== //

#pragma mark - Properties

@synthesize placesResource=placesResource_;

- (RCResource *) placesResource {
	if (nil == placesResource_) {
		placesResource_ = [self.appDelegate.service resource:@"place"];
		
		// Set up a post processing block to map to core data
		
		NSManagedObjectContext *childContext = [self.managedObjectContext newChildContext];
		RCPostProcessorBlock postProcessor = ^(RCResponse *response, id result) {
			
			if (NO == response.success) {
				return result;
			}
			
			// map new data			
			NSMutableArray *localPlaces = [NSMutableArray array];
			NSArray *remotePlaces = [result valueForKey:@"nearby"];
			
			// for the purposes of this demo we just wipe them all out and start over, you would probably do a find or create, then kill the stragglers
			[Place deleteAllInContext:childContext];
			
			for (id remotePlace in remotePlaces) {
				[childContext performBlockAndWait:^{
					Place *localPlace = [NSEntityDescription insertNewObjectForEntityForName:@"Place" inManagedObjectContext:childContext];
					localPlace.displayName = [remotePlace valueForKey:@"display_name"];
					localPlace.latitude = [NSNumber numberWithDouble:[[remotePlace valueForKey:@"latitude"] doubleValue]];
					localPlace.longitude = [NSNumber numberWithDouble:[[remotePlace valueForKey:@"longitude"] doubleValue]];
					localPlace.name = [remotePlace valueForKey:@"name"];
					localPlace.placeDescription = [remotePlace valueForKey:@"description"];
					localPlace.placeID = [remotePlace valueForKey:@"place_id"];
					localPlace.radius = [NSNumber numberWithInt:[[remotePlace valueForKey:@"radius"] intValue]];
					[localPlaces addObject:localPlace];
				}];
			}
			__autoreleasing NSError *saveError = nil;
			if (NO == [childContext saveChild:&saveError]) {
				NSLog(@"Could not save places: %@ (%@)",[saveError localizedDescription], [saveError userInfo]);
			}
			return localPlaces;
		};
		placesResource_.postProcessorBlock = postProcessor;
		
		
		// set up a preflight block to make sure we are logging in
		
		__weak AppDelegate *appDelegate = self.appDelegate;
		RCPreflightBlock preflight = ^(RCRequest *request) {
			NSLog(@"Preflighting request: %@, headers: %@",request, request.headers);
			if (NO == appDelegate.isLoggedIn) {
				[SVProgressHUD dismissWithError:@"Not logged in"];
				return NO;
			}
			return YES;
		};		
		placesResource_.preflightBlock = preflight;
	}
	return placesResource_;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
	fetchedResultsController_ = [NSFetchedResultsController withEntityName:@"Place" sortKey:@"displayName" ascending:YES inContext:self.managedObjectContext];
	fetchedResultsController_.delegate = self;
    
    return fetchedResultsController_;
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self refreshFromRemoteResource];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


// ========================================================================== //

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	if ([annotation isKindOfClass:[MKUserLocation class]]) {
		return nil;
	}
	static NSString *kPlaceAnnotation = @"PlaceAnnotation";
	MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:kPlaceAnnotation];
	if (annotationView == nil) {
		annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:kPlaceAnnotation];
		annotationView.canShowCallout = YES;
	} else {
		annotationView.annotation = annotation;
	}
	return annotationView;
}

- (void) configureAnnotation:(MKPointAnnotation *)annotation withCoordinateLike:(id<CoordinateLike>)coordinateLike {
	Place *place = (Place *)coordinateLike;
	annotation.title = place.displayName;
}


// ========================================================================== //

#pragma mark - Helpers

- (void) refreshFromRemoteResource {
	CLLocation *location = self.appDelegate.locationManager.location;
	// https://api.geoloqi.com/1/place/nearby?layer_id=10B&latitude=45.5246&longitude=-122.6843
	RCResource *nearbyPlacesResource = [self.placesResource resourceWithFormat:@"nearby?layer_id=1Wn&latitude=%f&longitude=%f",location.coordinate.latitude,location.coordinate.longitude];

	[SVProgressHUD showWithStatus:@"Fetching.." networkIndicator:NO];
	[nearbyPlacesResource getWithCompletionBlock:^(RCResponse *response) {
		if (response.success) {
			[SVProgressHUD dismiss];
		} else {
			NSString *errorMsg = [response.result valueForKey:@"error_description"];
			if (errorMsg.length == 0) {
				errorMsg = response.error ? [response.error localizedDescription] : @"Unknown error";
			}
			NSLog(@"ERROR: %@",errorMsg);
			[SVProgressHUD dismissWithError:errorMsg];
		}
	}];
}

@end
