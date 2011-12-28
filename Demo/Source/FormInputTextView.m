//
//  FormInputTextView.m
//  RESTClientDemo
//
//  Created by John Clayton on 12/21/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "FormInputTextView.h"

@implementation FormInputTextView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		self.layer.cornerRadius = 7.f;
    }
    return self;
}

- (void) awakeFromNib {
	[super awakeFromNib];
	self.layer.cornerRadius = 7.f;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
