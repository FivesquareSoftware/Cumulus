//
//  FetchedListController.h
//  RESTClientDemo
//
//  Created by John Clayton on 12/11/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "FetchedResultsMapViewController.h"

@interface FetchedListController : FetchedResultsMapViewController <UITableViewDataSource, UITableViewDelegate>

@property (retain, nonatomic) IBOutlet UITableView *tableView;

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end
