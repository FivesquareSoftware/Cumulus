//
//  MenuController.m
//  RESTClientExample
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "MenuController.h"


@implementation MenuController



// ========================================================================== //

#pragma mark - View Controller


- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewWillAppear:(BOOL)animated {
	if (NO == self.appDelegate.isLoggedIn) {
		[self performSegueWithIdentifier:@"showLoginController" sender:self];
	} else {
		[super viewWillAppear:animated];
	}
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// ========================================================================== //

#pragma mark - Actions

- (IBAction)logOut:(id)sender {
	self.appDelegate.service.authProviders = nil;
	[[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"authToken"];
	[self performSegueWithIdentifier:@"showLoginController" sender:self];
}

@end
