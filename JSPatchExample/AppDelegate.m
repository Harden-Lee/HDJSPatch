//
//  AppDelegate.m
//  JSPatchExample
//
//  Created by Harden.L on 2020/2/16.
//  Copyright © 2020 Harden.L. All rights reserved.
//

#import "AppDelegate.h"
#import "HDHotUpdateManger.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    //检查是需要热更新
    HDHotUpdateManger *manger = [[HDHotUpdateManger alloc] initWithBaseUrl:nil];
    [manger checkHotUpdate:@"hotUpdate.xml" comp:^(BOOL update) {
        
    }];
    
    return YES;
}

@end
