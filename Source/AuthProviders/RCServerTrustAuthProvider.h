//
//  RCServerTrustAuthProvider.h
//  RESTClient
//
//  Created by John Clayton on 12/13/11.
//  Copyright (c) 2011 Fivesquare Software, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "RCAuthProvider.h"

@interface RCServerTrustAuthProvider : NSObject <RCAuthProvider>

/** When this is set to YES, will trust any certificate, which is inherently insecure. If you need to use a self-signed cert during testing, it's better to import the cert into your keychain so you don't forget and leave this on. Defaults to NO. */
@property (nonatomic, getter = isInsecure) BOOL insecure; 

@end
