//
//  RCResourceGroup_Protected.h
//  Cumulus
//
//  Created by John Clayton on 8/28/12.
//  Copyright (c) 2012 Fivesquare Software, LLC. All rights reserved.
//

#import "CMResourceGroup.h"

@class CMResponse;

@interface CMResourceGroup ()
- (void) enter;
- (void) leaveWithResponse:(CMResponse *)response;
@end
