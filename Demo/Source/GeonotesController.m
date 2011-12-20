//
//  GeonotesController.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "GeonotesController.h"


#import "Geonote.h"


@interface GeonotesController()
@property (strong, nonatomic) RCResource *geonotesResource;
- (void) refreshFromRemoteResource;
@end


@implementation GeonotesController


// ========================================================================== //

#pragma mark - Properties

@synthesize geonotesResource=geonotesResource_;

- (RCResource *) geonotesResource {
	if (nil == geonotesResource_) {
		geonotesResource_ = [self.appDelegate.service resource:@"geonote/list_recent"];
		
		// Set up a post processing block to map to core data
		
		NSManagedObjectContext *childContext = [self.managedObjectContext newChildContext];
		RCPostProcessorBlock postProcessor = ^(RCResponse *response, id result) {
			
			if (NO == response.success) {
				return result;
			}
			
			// map new data			
			NSMutableArray *localGeonotes = [NSMutableArray array];
			NSArray *remoteGeonotes = [result valueForKey:@"geonotes"];
			
			// for the purposes of this demo we just wipe them all out and start over, you would probably do a find or create, then kill the stragglers
			[Geonote deleteAllInContext:childContext];
			
			for (id remoteGeonote in remoteGeonotes) {
				[childContext performBlock:^{
					Geonote *localGeonote = [NSEntityDescription insertNewObjectForEntityForName:@"Geonote" inManagedObjectContext:childContext];
					localGeonote.dateCreated = [NSDate dateWithISO8601String:[remoteGeonote valueForKey:@"date_created"]];
					localGeonote.geonoteID = [remoteGeonote valueForKey:@"geonote_id"];
					localGeonote.latitude = [NSNumber numberWithDouble:[[remoteGeonote valueForKey:@"latitude"] doubleValue]];
					localGeonote.longitude = [NSNumber numberWithDouble:[[remoteGeonote valueForKey:@"longitude"] doubleValue]];
					localGeonote.placeId = [remoteGeonote valueForKey:@"place_id"];
					localGeonote.placeName = [remoteGeonote valueForKey:@"place_name"];
					localGeonote.radius = [NSNumber numberWithInt:[[remoteGeonote valueForKey:@"radius"] intValue]];
					localGeonote.text = [remoteGeonote valueForKey:@"text"];
					[localGeonotes addObject:localGeonote];
				}];
			}
			__autoreleasing NSError *saveError = nil;
			if (NO == [childContext saveChild:&saveError]) {
				NSLog(@"Could not save geonotes: %@ (%@)",[saveError localizedDescription], [saveError userInfo]);
			}
			return localGeonotes;
		};
		geonotesResource_.postProcessorBlock = postProcessor;
		
		
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
		geonotesResource_.preflightBlock = preflight;
	}
	return geonotesResource_;
}

- (NSFetchedResultsController *)fetchedResultsController {
    if (fetchedResultsController_ != nil) {
        return fetchedResultsController_;
    }
	fetchedResultsController_ = [NSFetchedResultsController withEntityName:@"Geonote" sortKey:@"dateCreated" ascending:NO inContext:self.managedObjectContext];
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
	[self.fetchedResultsController fetch];
	[self refreshFromRemoteResource];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


// ========================================================================== //

#pragma mark - Table View



- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *kGeonoteCell = @"GeonoteCell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kGeonoteCell];
	[self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Geonote *geonote = [self.fetchedResultsController objectAtIndexPath:indexPath];
    cell.textLabel.text = geonote.placeName;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"showGeonote"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        Geonote *selectedGeonote = [[self fetchedResultsController] objectAtIndexPath:indexPath];
		//        [[segue destinationViewController] setDetailItem:selectedGeonote];
    }
}


// ========================================================================== //

#pragma mark - Helpers

- (void) refreshFromRemoteResource {
	[SVProgressHUD showWithStatus:@"Fetching.." networkIndicator:NO];
	[self.geonotesResource getWithCompletionBlock:^(RCResponse *response) {
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
