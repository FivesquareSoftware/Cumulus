//
//  LoginController.m
//  GeoloqiExample
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "LoginController.h"

#import "MenuController.h"



@implementation LoginController

// ========================================================================== //

#pragma mark - Properties



@synthesize tokenService=tokenService_;
@synthesize usernameTextField=usernameTextField_;
@synthesize passwordTextField=passwordTextField_;


// ========================================================================== //

#pragma mark - Object



- (id)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
		self.tokenService = [self.appDelegate.service resource:@"1/oauth/token"];
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
}

- (void)viewDidUnload {
	[self setUsernameTextField:nil];
	[self setPasswordTextField:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


// ========================================================================== //

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	if (self.usernameTextField.text.length && self.passwordTextField.text.length) {
		[self loginAction:self];
		return YES;
	}
	return NO;
}


// ========================================================================== //

#pragma mark - Actions


- (IBAction)loginAction:(id)sender {
	if (self.usernameTextField.text.length && self.passwordTextField.text.length) {
		NSDictionary *tokenPayload = [NSDictionary dictionaryWithObjectsAndKeys:
									  @"password", @"grant_type"
									  , self.usernameTextField.text, @"username"
									  , self.passwordTextField.text, @"password"
									  , @"client_id", @"59f5e7440a1fc56e9cc096c802ce8649"
									  , @"client_secret", @"f6d8f9485b66bc332ec3c084ba76f0fd"
									  , nil];
		[self.tokenService post:tokenPayload completionBlock:^(RCResponse *response) {
			if (response.success) {
				MenuController *controller = [[MenuController alloc] initWithNibName:nil bundle:nil];
				[self.navigationController pushViewController:controller animated:YES];
			}
		}];
	}	
}




@end
