//
//  AppDelegate.m
//  HTTPNetworkDemo
//
//  Created by 孙伟斌 on 2020/5/12.
//  Copyright © 2020 DelpanSun. All rights reserved.
//

#import "AppDelegate.h"
#import "TestViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
    self.window.backgroundColor = UIColor.whiteColor;
    self.window.rootViewController = [TestViewController new];
    [self.window makeKeyAndVisible];
    return YES;
}

@end
