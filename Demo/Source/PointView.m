//
//  PointView.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/20/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "PointView.h"



@implementation PointView

- (id)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
    if (self) {
		self.backgroundColor = [UIColor blackColor];
		self.layer.cornerRadius = 5;
		CGRect myFrame = self.frame;
		myFrame.size = CGSizeMake(10.f, 10.f);
		self.frame = myFrame;
    }
    return self;
}

@end
