//
//  AppDelegate.m
//  CoreDataSample
//
//  Created by Lata Sadhwani on 10/7/14.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    [self managedObjectContext];
    
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"data_saved"]) {
        NSURL *jsonURL = [NSURL URLWithString:@"https://s3.amazonaws.com/mustlist/week_455.json"];
        NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
        if (jsonData) {
            NSError *error;
            NSArray *jsonResponseArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
            if (!error) {
                if (jsonResponseArray && jsonResponseArray.count >0) {
                    for (NSDictionary *jsonDict in jsonResponseArray) {
                        NSManagedObject *book = [NSEntityDescription insertNewObjectForEntityForName:@"Books" inManagedObjectContext:[self managedObjectContext]];
                        
                        NSArray *allKeys = [jsonDict allKeys];
                        for (NSString *key in allKeys) {
                            NSString *attributeKey = [key stringByReplacingOccurrencesOfString:@"." withString:@"_"];
                            
                            id value = jsonDict[key];
                            
                            [book setValue:value forKey:attributeKey];
                        }
                    }
                    
                    [self saveContext];
                    
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"data_saved"];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }else{
                NSLog(@"Failed to convert to json object with error: %@", error);
            }
        }
    }
    
    // Add acceptable actions and category for the interactive notifications
    UIMutableUserNotificationAction *actionAccept = [[UIMutableUserNotificationAction alloc] init];
    actionAccept.identifier = @"Accept";
    actionAccept.title = @"Accept";
    actionAccept.activationMode = UIUserNotificationActivationModeForeground;
    actionAccept.destructive = NO;
    actionAccept.authenticationRequired = NO;
    
    UIMutableUserNotificationAction *actionIgnore = [[UIMutableUserNotificationAction alloc] init];
    actionIgnore.identifier = @"Ignore";
    actionIgnore.title = @"Ignore";
    actionIgnore.activationMode = UIUserNotificationActivationModeBackground;
    actionIgnore.destructive = NO;
    actionIgnore.authenticationRequired = NO;
    
    UIMutableUserNotificationCategory *notificationCategory = [[UIMutableUserNotificationCategory alloc] init];
    notificationCategory.identifier = @"Calendar";
    [notificationCategory setActions:@[actionAccept,actionIgnore] forContext:UIUserNotificationActionContextDefault];
    [notificationCategory setActions:@[actionAccept,actionIgnore] forContext:UIUserNotificationActionContextMinimal];
    
    NSSet *categories = [NSSet setWithObjects:notificationCategory, nil];
    
    UIUserNotificationType notificationType = UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *notificationSettings = [UIUserNotificationSettings settingsForTypes:notificationType categories:categories];
    
    [[UIApplication sharedApplication] registerUserNotificationSettings:notificationSettings];
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Firing local notification here for testing
#pragma mark - Remove local notification before deployment
    
    UILocalNotification* localNotification = [[UILocalNotification alloc] init];
    localNotification.fireDate = [NSDate dateWithTimeIntervalSinceNow:60];
    localNotification.alertBody = @"This is a test notification";
    localNotification.category = @"Calendar";
    localNotification.timeZone = [NSTimeZone defaultTimeZone];
    localNotification.userInfo = [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:200] forKey:@"id"];
    
    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Push notifications
-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    
    // Send device token to the server - wherever this should be stored
    
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    
    NSLog(@"%@", error);
    
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    
    // This is for normal notifications, non-interactive
    
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void(^)())completionHandler  {
    // This is for actions inside interactive notifications (local) - used for testing
    // Final code will use push notifications
    
    if([notification.category isEqualToString:@"Calendar"]) {

        if([identifier isEqualToString:@"Accept"]) {
            //Get the book id, get the date for that book and add a calendar event
            NSNumber *bookId = [notification.userInfo objectForKey:@"id"];
            
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Books" inManagedObjectContext:self.managedObjectContext];
            [fetchRequest setEntity:entity];
            [fetchRequest setPredicate: [NSPredicate predicateWithFormat:@"id == %@", bookId]];
            
            NSError *err;
            NSArray *bookArray = [NSArray arrayWithArray:[self.managedObjectContext executeFetchRequest:fetchRequest error:&err]];
            if (err) {
                NSLog(@"%@", err.localizedDescription);
                return;
            }
            if(bookArray.count > 0) {
                
                EKEventStore *eventStore = [[EKEventStore alloc] init];
                [eventStore requestAccessToEntityType:EKEntityTypeEvent completion:^(BOOL granted, NSError *error) {
                    if (error == nil) {
                        // Access granted - add event to calendar
                        NSManagedObject *book = bookArray[0];
                        
                        //Ideally the DateFormatter should be created globally - expensive
                        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSSS"];

                        NSString *dateString = [book valueForKey:@"date"];
                        NSDate *calDate = [dateFormatter dateFromString:dateString];
                        
                        EKCalendar *eventCalendar = [[eventStore calendarsForEntityType:EKEntityTypeEvent] objectAtIndex:0];
                        EKEvent *event = [EKEvent eventWithEventStore:eventStore];
                        event.title = [book valueForKey:@"title_text"];
                        event.calendar = eventCalendar;
                        event.startDate = calDate;
                        event.endDate = calDate;
                        
                        if([eventStore saveEvent:event span:EKSpanFutureEvents commit:YES error:&error]) {
                            NSLog(@"Event added");
                        }
                        else {
                            NSLog(@"Event adding failed");
                        }
                    }
                    else {
                        NSLog(@"%@", [error localizedDescription]);
                        // Access not granted - don't do anything
                    }
                }];
                
            }
        }
    }
    
    if(completionHandler != nil)
        completionHandler();
}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void(^)())completionHandler {
    
    // This will be used for handling the notifications (same code as above) when testing with actual push notifs
    // The push notif must have a key called "id" in the payload which holds the book id
    // For the local notif the id is added in the userInfo of the local notification

}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.adhoc.CoreDataSample" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *jsonURL = [NSURL URLWithString:@"https://s3.amazonaws.com/mustlist/week_455.json"];
    NSData *jsonData = [NSData dataWithContentsOfURL:jsonURL];
    if (jsonData) {
        NSError *error;
        NSArray *jsonResponseArray = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:&error];
        if (!error) {
            if (jsonResponseArray && jsonResponseArray.count >0) {
                NSDictionary *jsonDict = [jsonResponseArray lastObject];
                NSArray *keysArray = [jsonDict allKeys];
                
                
                //Create managed object model
                
                NSManagedObjectModel *model = [[NSManagedObjectModel alloc] init];
                
                NSEntityDescription *booksEntity = [[NSEntityDescription alloc] init];
                [booksEntity setName:@"Books"];
                
                [model setEntities:@[booksEntity]];
                
                NSMutableArray *booksProperties = [NSMutableArray array];
                
                for (NSString *key in keysArray) {
                    id value = jsonDict[key];
                    
                    NSAttributeDescription *attribute = [[NSAttributeDescription alloc] init];
                    
                    [booksProperties addObject:attribute];
                    
                    [attribute setName:[key stringByReplacingOccurrencesOfString:@"." withString:@"_"]];  //Remove dot[.] with underscore[_]
                    [attribute setOptional:YES];
                    
                    if ([value isKindOfClass:[NSString class]]) {
                        [attribute setAttributeType:NSStringAttributeType];
                    }else if ([value isKindOfClass:[NSNumber class]]){
                        //NSLog(@"type for '%@' is %@", key, [NSString stringWithUTF8String:[value objCType]]);
                        [attribute setAttributeType:NSInteger32AttributeType];
                    }else{
                        //NSLog(@"Unknown type '%@' for key: %@",[value class], key);
                        [attribute setAttributeType:NSStringAttributeType];
                    }
                }
                
                [booksEntity setProperties:booksProperties];
                
                _managedObjectModel = model;
                
            }
        }else{
            NSLog(@"Failed to convert to json object with error: %@", error);
        }
    }
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreDataSample.sqlite"];
    NSError *error = nil;
    NSString *failureReason = @"There was an error creating or loading the application's saved data.";
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        // Report any error we got.
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
        dict[NSLocalizedFailureReasonErrorKey] = failureReason;
        dict[NSUnderlyingErrorKey] = error;
        error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        // Replace this with code to handle the error appropriately.
        // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}


- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
