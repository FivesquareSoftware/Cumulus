//
//  RecentLocationsController.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "RecentLocationsController.h"

#import "Location.h"
#import "PointView.h"

@interface RecentLocationsController()
@property (strong, nonatomic) RCResource *locationsResource;
- (void) refreshFromRemoteResource;
@end


@implementation RecentLocationsController

// ========================================================================== //

#pragma mark - Properties

@synthesize locationsResource=locationsResource_;

- (RCResource *) locationsResource {
	if (nil == locationsResource_) {
		locationsResource_ = [self.appDelegate.service resource:@"location/history?count=100"];
		
		// Set up a post processing block to map to core data
		
		NSManagedObjectContext *childContext = [self.managedObjectContext newChildContext];
		RCPostProcessorBlock postProcessor = ^(RCResponse *response, id result) {
			
			if (NO == response.success) {
				return result;
			}

			// map new data			
			__block NSMutableArray *localLocations = [NSMutableArray array];
			NSArray *remoteLocations = [result valueForKey:@"points"];
									
			for (id remoteLocation in remoteLocations) {
				[childContext performBlockAndWait:^{
					NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid = %@",[remoteLocation valueForKey:@"uuid"]];
					Location *localLocation = [Location findOrCreateWithPredicate:predicate inContext:childContext];

					localLocation.uuid = [remoteLocation valueForKey:@"uuid"];
					localLocation.date = [NSDate dateWithISO8601String:[remoteLocation valueForKey:@"date"]];
					localLocation.latitude = [NSNumber numberWithDouble:[[remoteLocation valueForKeyPath:@"location.position.latitude"] doubleValue]];
					localLocation.longitude = [NSNumber numberWithDouble:[[remoteLocation valueForKeyPath:@"location.position.longitude"] doubleValue]];
					localLocation.altitude = [NSNumber numberWithInt:[[remoteLocation valueForKeyPath:@"location.position.altitude"] intValue]];
					localLocation.speed = [NSNumber numberWithInt:[[remoteLocation valueForKeyPath:@"location.position.speed"] intValue]];

					[localLocations addObject:localLocation];
				}];
			}
			
			__autoreleasing NSError *saveError = nil;
			if (NO == [childContext saveChild:&saveError]) {
				NSLog(@"Could not save locations: %@ (%@)",[saveError localizedDescription], [saveError userInfo]);
			}
			return localLocations;
		};
		locationsResource_.postProcessorBlock = postProcessor;		
	}
	return locationsResource_;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
	fetchedResultsController_ = [NSFetchedResultsController withEntityName:@"Location" sortKey:@"date" ascending:NO inContext:self.managedObjectContext];
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
}

- (void) viewDidAppear:(BOOL)animated {
	[super viewDidAppear:animated];
	[self refreshFromRemoteResource];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// ========================================================================== //

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>)annotation {
	static NSString *kLocationAnnotation = @"LocationAnnotation";
	PointView *pointView = (PointView *)[self.mapView dequeueReusableAnnotationViewWithIdentifier:kLocationAnnotation];
	if (pointView == nil) {
		pointView = [[PointView alloc] initWithAnnotation:annotation reuseIdentifier:kLocationAnnotation];
	} else {
		pointView.annotation = annotation;
	}
	return pointView;
}



// ========================================================================== //

#pragma mark - Helpers

- (void) refreshFromRemoteResource {
	[SVProgressHUD showWithStatus:@"Updating.." networkIndicator:NO];
	[self.locationsResource getWithCompletionBlock:^(RCResponse *response) {
		if (response.success) {
			[SVProgressHUD dismiss];
		} else {
			NSString *error = [response.result valueForKey:@"error"];
			if ([error isEqualToString:@"expired_token"]) {
				[self performSelectorOnMainThread:_cmd withObject:nil waitUntilDone:NO];
				return;
			}
			NSString *errorMsg = [response.result valueForKey:@"error_description"];
			if (errorMsg.length == 0) {
				errorMsg = response.error ? [response.error localizedDescription] : @"Unknown error";
			}
			NSLog(@"ERROR: %@",errorMsg);
			[SVProgressHUD dismissWithError:errorMsg];
		}
	}];
}

// ========================================================================== //

#pragma mark - Actions



- (IBAction)resetLocationsAction:(id)sender {
	[Location deleteAllInContext:self.managedObjectContext];
	[self.managedObjectContext performBlockAndWait:^{
		[self.managedObjectContext save:NULL];
	}];
	[self refreshFromRemoteResource];
}


@end
