//
//  AppDelegate.h
//  RESTClientExample
//
//  Created by John Clayton on 12/9/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, CLLocationManagerDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@property (readonly, strong, nonatomic) CLLocationManager *locationManager;

@property (strong, nonatomic) RCResource *service;
@property (readonly, getter = isLoggedIn) BOOL loggedIn;


@end
