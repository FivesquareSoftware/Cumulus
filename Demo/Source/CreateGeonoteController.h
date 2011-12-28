//
//  CreateGeonoteController.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FetchedResultsMapViewController.h"

@interface CreateGeonoteController : FetchedResultsMapViewController <UITextViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *noteTextView;

- (IBAction)cancelAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
