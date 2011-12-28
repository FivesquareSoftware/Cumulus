//
//  LoginController.h
//  RESTClientExample
//
//  Created by John Clayton on 12/10/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginController : UITableViewController <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITextField *usernameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

- (IBAction)loginAction:(id)sender;
- (IBAction)getAccountAction:(id)sender;

@end
