//
//  AppDelegate.m
//  PermissionsTestApp
//
//  Created by Felix Lamouroux on 25.06.14.
//  Copyright (c) 2014 iosphere GmbH. All rights reserved.
//

#import "AppDelegate.h"
#import "SamplePermissionViewController.h"
#import "GrantedPermissionsViewController.h"
@import Accounts;

@interface AppDelegate ()
@property (nonatomic, weak) GrantedPermissionsViewController *rootViewController;
@end

@implementation AppDelegate

+ (AppDelegate *)appDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self setupWindow];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self presentPermissionsIfNeeded];
    });

    return YES;
}

+ (NSArray<NSNumber *> *)requiredPermissions {
    return @[
             @(ISHPermissionCategoryEvents),
             @(ISHPermissionCategoryReminders),
             @(ISHPermissionCategoryAddressBook),
             @(ISHPermissionCategoryLocationWhenInUse),
             @(ISHPermissionCategoryLocationAlways),
             @(ISHPermissionCategoryActivity),
             @(ISHPermissionCategoryMicrophone),
             @(ISHPermissionCategoryPhotoLibrary),
             @(ISHPermissionCategoryModernPhotoLibrary),
             @(ISHPermissionCategoryPhotoCamera),
             @(ISHPermissionCategoryUserNotification),
             @(ISHPermissionCategoryNotificationLocal),
             @(ISHPermissionCategorySocialTwitter),
             @(ISHPermissionCategorySocialFacebook),
             @(ISHPermissionCategorySpeechRecognition),
             ];
}

- (void)presentPermissionsIfNeeded {
    NSArray *permissions = [AppDelegate requiredPermissions];
    ISHPermissionsViewController *permissionsVC = [ISHPermissionsViewController permissionsViewControllerWithCategories:permissions dataSource:self];
    __weak GrantedPermissionsViewController *rootVC = self.rootViewController;
    [permissionsVC setCompletionBlock:^{
        [rootVC reloadPermissionsUsingDataSource:self];
    }];
    
    __weak ISHPermissionsViewController *weakPermissionsVC = permissionsVC;
    [permissionsVC setErrorBlock:^(ISHPermissionCategory category, NSError *error) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:ISHStringFromPermissionCategory(category)
                                                                       message:error.localizedDescription
                                                                preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"Too bad" style:UIAlertActionStyleCancel handler:nil]];
        // if weakPermissionsVC still has a parent, present from there else present from root
        UIViewController *presentingVC = weakPermissionsVC.parentViewController ? weakPermissionsVC : rootVC;
        [presentingVC presentViewController:alert animated:nil completion:nil];
    }];

    if (permissionsVC) {
        [self.window.rootViewController presentViewController:permissionsVC animated:YES completion:nil];
    }
}

#pragma mark ISHPermissionsViewControllerDataSource

- (ISHPermissionRequestViewController *)permissionsViewController:(ISHPermissionsViewController *)vc requestViewControllerForCategory:(ISHPermissionCategory)category {
    return [SamplePermissionViewController new];
}

- (void)permissionsViewController:(ISHPermissionsViewController *)vc didConfigureRequest:(ISHPermissionRequest *)request {
    if (request.permissionCategory == ISHPermissionCategoryNotificationLocal) {
        // the demo app only requests permissions for badges
        UIUserNotificationSettings *setting = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeBadge categories:nil];
        ISHPermissionRequestNotificationsLocal *localNotesRequest = (ISHPermissionRequestNotificationsLocal *)([request isKindOfClass:[ISHPermissionRequestNotificationsLocal class]] ? request : nil);
        [localNotesRequest setNotificationSettings:setting];
    }

    if (request.permissionCategory == ISHPermissionCategorySocialFacebook) {
        ISHPermissionRequestAccount *accountRequest = (ISHPermissionRequestAccount *)([request isKindOfClass:[ISHPermissionRequestAccount class]] ? request : nil);

        NSDictionary *options = @{
                                  ACFacebookAppIdKey: @"YOUR-API-KEY",
                                  ACFacebookPermissionsKey: @[@"email", @"user_about_me"],
                                  ACFacebookAudienceKey: ACFacebookAudienceFriends
                                  };

        [accountRequest setOptions:options];
    }
}

#pragma mark Important for local Notifications

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [[NSNotificationCenter defaultCenter] postNotificationName:ISHPermissionNotificationApplicationDidRegisterUserNotificationSettings
                                                        object:self];
}

#pragma mark Boiler plate

- (void)setupWindow {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];

    GrantedPermissionsViewController *rootViewController = [GrantedPermissionsViewController new];
    [self.window setRootViewController:rootViewController];
    self.rootViewController = rootViewController;
    [self.window makeKeyAndVisible];
}

@end
