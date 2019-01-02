# AppIconBadge
解决在前台时重启应用和设置应用角标的问题

简书地址：https://www.jianshu.com/p/d1a933853013

 >  问：应用启动时是否会执行 - (void)applicationWillEnterForeground:(UIApplication *)application ？
 答：不会 ？ 你确定？那看一哈下面的情况。

![前台时重启应用调用了applicationWillEnterForeground：](https://upload-images.jianshu.io/upload_images/1708447-f15e4634823b8c34.gif?imageMogr2/auto-orient/strip)


# 已知条件：

>  &#160;&#160;  应用在退到后台时，会给应用加上一层毛玻璃效果，防止iOS系统自动对应用当前界面进行截屏处理时获取到用户的某些隐私，提高安全性；同时也会在退到后台时，重置应用的消息角标。

```

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
    NSLog(@" 即将进入非活动状态 ");
}

//当应用进入后台时执行  或者应用在前台时被强制关闭时执行
- (void)applicationDidEnterBackground:(UIApplication *)application {
    //给处于后台的应用添加毛玻璃效果
    if (_effectView == nil) {
        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        _effectView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _effectView.frame = CGRectMake(0, 0, self.window.frame.size.width, self.window.frame.size.height);
    }
    [self.window addSubview:_effectView];
    
    // 实现如下代码，才能使程序处于后台时被杀死后调用applicationWillTerminate:方法
     [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^(){}];
  
    //重置应用的角标
    [self resetApplicationIconBadgeNumber];
    NSLog(@" 进入后台 ");
}

//当应用即将从后台进入前台时执行，重新启动应用时并不执行，除了此demo演示的特殊情况
- (void)applicationWillEnterForeground:(UIApplication *)application {
  
    if (_effectView != nil) {
        [_effectView removeFromSuperview];
        _effectView = nil;
    }
    
    //弹窗
//   SL_ULog(@"执行了 applicationWillEnterForeground ");
    NSLog(@" 即将从后台进入前台 ");
}

//当应用进入活动状态时执行
- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (_effectView != nil) {
        [_effectView removeFromSuperview];
        _effectView = nil;
    }
    NSLog(@" 进入活动状态 ");
}

//应用被杀死时调用
- (void)applicationWillTerminate:(UIApplication *)application {
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

//这个方法是为了清除应用的角标，同时又不清除之前发送的通知内容
- (void)resetApplicationIconBadgeNumber {
 //使用这个方法清除角标，如果置为0的话会把之前收到的通知内容都清空；置为-1的话，不但能保留以前的通知内容，还有角标消失动画，iOS10之前这样设置是没有作用的 ，iOS10之后才有效果 。
    [UIApplication sharedApplication].applicationIconBadgeNumber = -1;
    
//这个发送本地通知的操作是为了解决在iOS10之前清除角标的同时可以保留通知内容的问题
   //这个进入后台时清除角标的操作会造成：应用在前台时被强制关闭后，立马重启应用后会调用方法applicationWillEnterForeground:，正常情况下重新启动应用时并不执行它.
//    UILocalNotification *clearEpisodeNotification = [[UILocalNotification alloc] init];
//    clearEpisodeNotification.applicationIconBadgeNumber = -1;
//    [[UIApplication sharedApplication] scheduleLocalNotification:clearEpisodeNotification];
}

```

# 问题描述：

> &#160;&#160; 当应用在前台时，手动强制重启应用后，发现没有正常的加载启动屏，加载的启动屏是退入后台时的应用截屏。

![前台时重启应用出现的问题展示](https://upload-images.jianshu.io/upload_images/1708447-29dd5dba25eaf850.gif?imageMogr2/auto-orient/strip)

# 调试分析

> &#160;&#160;  经过不断调试之后，发现：在前台时重启应用后，调用 application: didFinishLaunchingWithOptions: 方法之后，还调用了applicationWillEnterForeground： ？？？？ “这操作不合理呀！应用启动时应该不会执行 applicationWillEnterForeground 方法呀！”     如下示意图，我加了个弹窗验证：

![前台时重启应用调用了applicationWillEnterForeground：](https://upload-images.jianshu.io/upload_images/1708447-f15e4634823b8c34.gif?imageMogr2/auto-orient/strip)

>  &#160;&#160;  为什么在前台时重启应用会执行 applicationWillEnterForeground  ？通过删除排除法，找到了导致此问题的代码，如下，这段代码是退入后台时清除角标的操作。如果不在应用退入后台时执行下面的清除角标操作，就是正常的。 

```

//当应用进入后台时执行  或者应用在前台时被强制关闭时执行
- (void)applicationDidEnterBackground:(UIApplication *)application {
//这个发送本地通知的操作是为了解决在iOS10之前清除角标的同时可以保留通知内容的问题
 //这个清除角标的操作只在进入后台时执行才会造成：应用在前台时被强制关闭后，立马重启应用后会调用方法applicationWillEnterForeground:，正常情况下重新启动应用时并不执行它；
    UILocalNotification *clearEpisodeNotification = [[UILocalNotification alloc] init];
    clearEpisodeNotification.applicationIconBadgeNumber = -1;
    [[UIApplication sharedApplication] scheduleLocalNotification:clearEpisodeNotification];
}

```

> &#160;&#160; 这时有人肯定会疑惑为啥不用[UIApplication sharedApplication].applicationIconBadgeNumber = 0 ？
   &#160;&#160;  因为把应用角标值置为0的话会把之前收到的通知栏内的通知内容都清空，这样显然是不合理的；如果置为-1的话，不但能保留以前的通知内容，还有角标消失动画，iOS10之前这样设置是没有作用的 ，iOS10之后才有效果 ；所以iOS10之前只能通过上述代码来实现。


# 解决问题

>   &#160;&#160;  **方案一** ： 把上述清除角标的代码放在应用进入前台时执行的方法 applicationDidBecomeActive: 里面，这样的话就是看不到角标消失的过程。
 &#160;&#160;  **方案二**：通过 [UIApplication sharedApplication].applicationIconBadgeNumber = -1 来清除角标。

```

- (void)applicationDidEnterBackground:(UIApplication *)application {
   //使用这个方法清除角标，如果置为0的话会把之前收到的通知内容都清空；置为-1的话，不但能保留以前的通知内容，还有角标消失动画，iOS10之前这样设置是没有作用的 ，iOS10之后才有效果 。
    [UIApplication sharedApplication].applicationIconBadgeNumber = -1;
}

```

![问题解决后](https://upload-images.jianshu.io/upload_images/1708447-2650ac211961267d.gif?imageMogr2/auto-orient/strip)



>  虽然问题解决了，但是为什么 **调试分析** 步骤中的问题代码会导致在前台时重启应用会执行 applicationWillEnterForeground：？ 是系统的Bug ?  如果小伙伴有谁知道的话，欢迎底部留言交流👏👏👏 


> 如果需要跟我交流的话：  
※ Github： [https://github.com/wsl2ls](https://github.com/wsl2ls)  
※ 简书：[https://www.jianshu.com/u/e15d1f644bea](https://www.jianshu.com/u/e15d1f644bea)  
※ 微信公众号：iOS2679114653  
※ QQ：1685527540  
