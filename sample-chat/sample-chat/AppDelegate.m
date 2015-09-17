//
//  AppDelegate.m
//  sample-chat
//
//  Created by Igor Khomenko on 10/16/13.
//  Copyright (c) 2013 Igor Khomenko. All rights reserved.
//

#import "AppDelegate.h"
#import "ServicesManager.h"
#import "ChatViewController.h"

@implementation AppDelegate {
    BOOL launchedFromPush;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Set QuickBlox credentials (You must create application in admin.quickblox.com)
    [QBApplication sharedApplication].applicationId = 92;
    [QBConnection registerServiceKey:@"wJHdOcQSxXQGWx5"];
    [QBConnection registerServiceSecret:@"BTFsj7Rtt27DAmT"];
    [QBSettings setAccountKey:@"7yvNe17TnjNUqDoPwfqp"];
    
    // Enables Quickblox REST API calls debug console output
    [QBSettings setLogLevel:QBLogLevelDebug];
    
    // Enables detailed XMPP logging in console output
    [QBSettings enableXMPPLogging];
    
    // app was launched from push notification, handling it
    if (launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]) {
        launchedFromPush = YES;
        [self application:application didReceiveRemoteNotification:launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey]];
    }
    
    return YES;
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    NSString *deviceIdentifier = [[[UIDevice currentDevice] identifierForVendor] UUIDString];
    
    // subscribing for push notifications
    QBMSubscription *subscription = [QBMSubscription subscription];
    subscription.notificationChannel = QBMNotificationChannelAPNS;
    subscription.deviceUDID = deviceIdentifier;
    subscription.deviceToken = deviceToken;
    
    [QBRequest createSubscription:subscription successBlock:^(QBResponse *response, NSArray *objects) {
        //
    } errorBlock:^(QBResponse *response) {
        //
    }];
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    // failed to register push
    NSLog(@"Push failed to register with error: %@", error);
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
    if ([application applicationState] == UIApplicationStateInactive)
    {
        self.pushDialogID = userInfo[kDialogIdentifierKey];
        
        if (self.pushDialogID != nil) {
            if (ServicesManager.instance.currentUser == nil) {
                return;
            }
            if (launchedFromPush) {
                launchedFromPush = NO;
                return;
            }
            
            NSString *dialogWithIDWasEntered = [ServicesManager instance].currentDialogID;
            if ([dialogWithIDWasEntered isEqualToString:self.pushDialogID]) return;
            
            __weak __typeof(self)weakSelf = self;
            [ServicesManager.instance.chatService fetchDialogWithID:self.pushDialogID completion:^(QBChatDialog *chatDialog) {
                //
                if (chatDialog != nil) {
                    __typeof(weakSelf)strongSelf = weakSelf;
                    strongSelf.pushDialogID = nil;
                    UINavigationController *navigationController = (UINavigationController *)strongSelf.window.rootViewController;
                    
                    ChatViewController *chatController = (ChatViewController *)[[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"ChatViewController"];
                    chatController.dialog = chatDialog;
                    
                    if (dialogWithIDWasEntered != nil) {
                        // some chat already opened, return to dialogs view controller first
                        [navigationController popViewControllerAnimated:NO];
                    }
                    
                    [navigationController pushViewController:chatController animated:NO];
                }
            }];
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    // Logout from chat
    //
	[ServicesManager.instance.chatService logoutChat];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	
    // Login to QuickBlox Chat
    //
	[ServicesManager.instance.chatService logIn:nil];
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
