//
//  AppDelegate.m
//  BackgroundProblem
//
//  Created by 王双龙 on 2018/12/19.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "PrefixHeader.pch"
#import <UserNotifications/UserNotifications.h>

@interface AppDelegate () <UNUserNotificationCenterDelegate> {
    //毛玻璃
    UIVisualEffectView *_effectView;
}

@end

@implementation AppDelegate


//关于前后台切换的苹果官方文档：https://developer.apple.com/library/ios/documentation/iPhone/Conceptual/iPhoneOSProgrammingGuide/StrategiesforHandlingAppStateTransitions/StrategiesforHandlingAppStateTransitions.html

//当应用启动载入完成后执行，也就是系统启动屏加载完成后执行
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    NSLog(@" 应用启动完成 ");
    
    //延长系统启动屏展示的时长
    [NSThread sleepForTimeInterval:2];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];
    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[[ViewController alloc] init]];
    
    //注册通知
    UNUserNotificationCenter * center  = [UNUserNotificationCenter currentNotificationCenter];
    //设置代理，用于检测点击方法
    center.delegate = self;
    //申请权限
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionAlert + UNAuthorizationOptionSound + UNAuthorizationOptionBadge + UNAuthorizationOptionCarPlay) completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            NSLog(@"用户同意开启通知");
        }
    }];
    
    return YES;
}

//当应用即将进入非活动状态时执行
- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    
    NSLog(@" 即将进入非活动状态 ");
}

//当应用进入后台时执行  或者应用在前台时被强制关闭时执行
- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    
    //给处于后台的应用添加毛玻璃效果
    if (_effectView == nil) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _effectView.frame = CGRectMake(0, 0, self.window.frame.size.width, self.window.frame.size.height);
    }
    [self.window addSubview:_effectView];
    
    // 实现如下代码，才能使程序处于后台时被杀死后调用applicationWillTerminate:方法
    [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(){}];
    
    //进入后台时重置应用的角标
    [self resetApplicationIconBadgeNumber];
    
    NSLog(@" 进入后台 ");
}

//当应用即将从后台进入前台时执行，重新启动应用时并不执行，除了此demo演示的特殊情况
- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    
    if (_effectView != nil) {
        [_effectView removeFromSuperview];
        _effectView = nil;
    }
    
    //弹窗
    SL_ULog(@"执行了 applicationWillEnterForeground ");
    NSLog(@" 即将从后台进入前台 ");
}

//当应用进入活动状态时执行
- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    
    if (_effectView != nil) {
        [_effectView removeFromSuperview];
        _effectView = nil;
    }
    
    NSLog(@" 进入活动状态 ");
}

//应用被杀死时调用
- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    
    NSLog(@" 应用被杀死了 ");
}

#pragma mark - iOS10 收到通知（本地和远端） UNUserNotificationCenterDelegate

//当APP处于前台的时候收到通知的事件
- (void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
    // 系统要求执行这个方法，选择是否提醒用户，有Badge、Sound、Alert三种类型可以设置
    completionHandler(UNNotificationPresentationOptionBadge|
                      UNNotificationPresentationOptionSound|
                      UNNotificationPresentationOptionAlert);
}

//这个方法是为了进入后台时清除应用的角标，同时又不清除之前发送的通知内容
- (void)resetApplicationIconBadgeNumber {
    
    //使用这个方法清除角标，如果置为0的话会把之前收到的通知内容都清空；置为-1的话，不但能保留以前的通知内容，还有角标消失动画，iOS10-以前这样设置是没有作用的 ，iOS10+之后才有效果 。
    //    [UIApplication sharedApplication].applicationIconBadgeNumber = -1;
    
    //这个发送本地通知的操作是为了解决在iOS10-之前清除角标的同时可以保留通知内容的问题
    //    这个清除角标的操作只在进入后台时执行才会造成：应用在前台时被强制关闭后，立马重启应用后会调用方法applicationWillEnterForeground:，正常情况下重新启动应用时并不执行它；
    UILocalNotification *clearEpisodeNotification = [[UILocalNotification alloc] init];
    clearEpisodeNotification.applicationIconBadgeNumber = -1;
    [[UIApplication sharedApplication] scheduleLocalNotification:clearEpisodeNotification];
    
}

@end
