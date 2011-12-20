//
//  DetailViewController.h
//  RESTClientExample
//
//  Created by John Clayton on 12/9/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DetailViewController : UIViewController

@property (strong, nonatomic) id detailItem;

@property (strong, nonatomic) IBOutlet UILabel *detailDescriptionLabel;

@end
