//
//  LoginController.m
//  RESTClientExample
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "LoginController.h"

#import "MenuController.h"



@implementation LoginController

// ========================================================================== //

#pragma mark - Properties



@synthesize usernameTextField=usernameTextField_;
@synthesize passwordTextField=passwordTextField_;


// ========================================================================== //

#pragma mark - Object





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

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
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
		RCOAuth2AuthProvider *authProvider = [self.appDelegate.service.authProviders lastObject];
		[SVProgressHUD showWithStatus:@"Logging in.." maskType:SVProgressHUDMaskTypeClear networkIndicator:NO];		
		[authProvider requestAccessTokenWithUsername:self.usernameTextField.text password:self.passwordTextField.text completionBlock:^(RCResponse *response) {
			if (response.success) {		
				if (self.appDelegate.isLoggedIn) {
					// You might want to store this in the keychain in your app ...
					[[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:authProvider.token] forKey:@"authToken"];
					[[NSUserDefaults standardUserDefaults] synchronize];
					[SVProgressHUD dismiss];
					[self dismissModalViewControllerAnimated:YES];
				} else {
					[SVProgressHUD dismissWithError:@"Try again.."];
				}
			} else {
				if (response.HTTPUnauthorized) {
					[SVProgressHUD dismissWithError:@"Incorrect Client ID or Secret"];
				} else {
					NSString *errorMsg = [response.result valueForKey:@"error"];
					[SVProgressHUD dismissWithError:errorMsg];
				}
			}
		}];
	}
}

- (IBAction)getAccountAction:(id)sender {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.geoloqi.com"]];
}


@end
