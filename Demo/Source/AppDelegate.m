//
//  AppDelegate.m
//  RESTClientExample
//
//  Created by John Clayton on 12/9/11.
//  Copyright (c) 2011 Me. All rights reserved.
//

#import "AppDelegate.h"


#import "RESTClient.h"

@interface AppDelegate()
- (NSURL *)applicationDocumentsDirectory;
@end


@implementation AppDelegate

// ========================================================================== //

#pragma mark - Properties



@synthesize window = window_;
@synthesize managedObjectContext = managedObjectContext_;
@synthesize managedObjectModel = managedObjectModel_;
@synthesize persistentStoreCoordinator = persistentStoreCoordinator_;

@synthesize locationManager=locationManager_;
@synthesize service=service_;

- (CLLocationManager *)locationManager {
	
    if (locationManager_ != nil) {
		return locationManager_;
	}
	
	locationManager_ = [[CLLocationManager alloc] init];
	[locationManager_ setDesiredAccuracy:kCLLocationAccuracyBest];
	[locationManager_ setDelegate:self];
	
	return locationManager_;
}

@dynamic loggedIn;
- (BOOL) isLoggedIn {
	return ((RCOAuth2AuthProvider *)[self.service.authProviders lastObject]).token.accessToken.length > 0;
}






// ========================================================================== //

#pragma mark - UIApplicationDelegate



- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
	self.service = [RCResource withURL:@"https://api.geoloqi.com/1"];
	service_.contentType = RESTClientContentTypeJSON;

	// set up a preflight block to make sure we are logging in	
	__weak AppDelegate *self_ = self;
	RCPreflightBlock preflight = ^(RCRequest *request) {
		NSLog(@"Preflighting request: %@, headers: %@",request, request.headers);
		if (NO == self_.isLoggedIn) {
			[SVProgressHUD dismissWithError:@"Not logged in"];
			return NO;
		}
		return YES;
	};		
	service_.preflightBlock = preflight;
	
	NSURL *authorizationURL = [self.service.URL URLByAppendingPathComponent:@"oauth/authorize"];

	RCResource *tokenService = [RCResource withURL:@"https://api.geoloqi.com/1/oauth/token"];
	tokenService.contentType = RESTClientContentTypeJSON;
//	tokenService.username =  @"59f5e7440a1fc56e9cc096c802ce8649";
//	tokenService.password = @"f6d8f9485b66bc332ec3c084ba76f0fd";

	tokenService.username =  @"8487d79e6ffc2b7f5cd489d9d3e7466b";
	tokenService.password = @"3c240df657788402367d2364642d86af";

	
	RCOAuth2AuthProvider *provider = [RCOAuth2AuthProvider withAuthorizationURL:authorizationURL tokenService:tokenService];
	provider.token = [NSKeyedUnarchiver unarchiveObjectWithData:[[NSUserDefaults standardUserDefaults] dataForKey:@"authToken"]]; 

	[service_ addAuthProvider:provider];
	
	[self.locationManager startUpdatingLocation];
	
    return YES;
}
							


// ========================================================================== //

#pragma mark - Core Data stack


/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)managedObjectContext
{
    if (managedObjectContext_ != nil)
    {
        return managedObjectContext_;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil)
    {
        managedObjectContext_ = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [managedObjectContext_ setPersistentStoreCoordinator:coordinator];
    }
    return managedObjectContext_;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)managedObjectModel
{
    if (managedObjectModel_ != nil)
    {
        return managedObjectModel_;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"RESTClientDemo" withExtension:@"momd"];
    managedObjectModel_ = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return managedObjectModel_;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (persistentStoreCoordinator_ != nil)
    {
        return persistentStoreCoordinator_;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"RESTClientDemo.sqlite"];
    
    NSError *error = nil;
    persistentStoreCoordinator_ = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![persistentStoreCoordinator_ addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return persistentStoreCoordinator_;
}

#pragma mark - Application's Documents directory

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


// ========================================================================== //

#pragma mark - CLLocationManagerDelegate


- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
	NSLog(@"locationManager:didUpdateToLocation: %@",newLocation);
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error {
	NSLog(@"locationManager:didFailWithError: %@",[error localizedDescription]);
}

@end
