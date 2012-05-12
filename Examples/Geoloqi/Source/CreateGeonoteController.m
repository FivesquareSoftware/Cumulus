//
//  CreateGeonoteController.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "CreateGeonoteController.h"


#import "RESTClient.h"

@interface CreateGeonoteController()
@property (nonatomic, strong) RCResource *geonoteResource;
@property (nonatomic, strong) CLLocation *lastLocation;
@end

@implementation CreateGeonoteController

// ========================================================================== //

#pragma mark - Properties

@synthesize noteTextView=noteTextView_;
@synthesize geonoteResource=geonoteResource_;
@synthesize lastLocation=lastLocation_;

@dynamic fetchedResultsController;
- (NSFetchedResultsController *) fetchedResultsController {
	return nil;
}

- (RCResource *) geonoteResource {
	if (nil == geonoteResource_) {
		geonoteResource_  = [self.appDelegate.service resource:@"geonote/create"];
		geonoteResource_.timeout = 15;
	}
	return geonoteResource_;
}



// ========================================================================== //

#pragma mark - Object

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}



// ========================================================================== //

#pragma mark - View Controller



- (void)viewDidLoad {
    [super viewDidLoad];
	
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
	
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)viewDidUnload {
	self.noteTextView = nil;
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
	[self.noteTextView becomeFirstResponder];
}

- (void) viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// ========================================================================== //

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
	NSString *trimmedText = [self.noteTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	self.navigationItem.rightBarButtonItem.enabled = trimmedText.length > 0;
}


// ========================================================================== //

#pragma mark - MKMapViewDelegate

- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
	CLLocationDistance distance = [userLocation.location distanceFromLocation:self.lastLocation];
	if (self.lastLocation == nil ||  distance > 1.0) {
		self.lastLocation = userLocation.location;
		MKCoordinateRegion region = MKCoordinateRegionMakeWithDistance(userLocation.coordinate, 1000, 1000);
		[self.mapView setRegion:region animated:YES];
		self.mapView.centerCoordinate = userLocation.coordinate;
	}
}




// ========================================================================== //

#pragma mark - Actions



- (IBAction)cancelAction:(id)sender {
	[self.geonoteResource cancelRequests];
	[self.managedObjectContext rollback];
	[self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)saveAction:(id)sender {
	NSString *trimmedText = [self.noteTextView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
	if (trimmedText.length) {
		
		self.navigationItem.rightBarButtonItem.enabled = NO;
		
		CLLocation *location = self.appDelegate.locationManager.location;
		NSDictionary *note = [NSDictionary dictionaryWithObjectsAndKeys:
							  trimmedText, @"text"
							  , [NSNumber numberWithDouble:location.coordinate.latitude], @"latitude"
							  , [NSNumber numberWithDouble:location.coordinate.longitude], @"longitude"
							  , [NSNumber numberWithInt:100], @"radius"
							  , nil];
		
		[SVProgressHUD showWithStatus:@"Creating.." networkIndicator:NO];
		[self.geonoteResource post:note withCompletionBlock:^(RCResponse *response) {
			if (response.success) {
				[SVProgressHUD dismissWithSuccess:@"Success!"];
				[self.navigationController popViewControllerAnimated:YES];
			} else {
				self.navigationItem.rightBarButtonItem.enabled = YES;
				NSString *errorMsg = [response.result valueForKey:@"error_description"];
				if (errorMsg.length == 0) {
					errorMsg = response.error ? [response.error localizedDescription] : @"Unknown error";
				}
				NSLog(@"ERROR: %@",errorMsg);
				[SVProgressHUD dismissWithError:errorMsg];
			}
		}];
	}
}

@end
