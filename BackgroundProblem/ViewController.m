//
//  ViewController.m
//  BackgroundProblem
//
//  Created by 王双龙 on 2018/12/19.
//  Copyright © 2018年 https://www.jianshu.com/u/e15d1f644bea. All rights reserved.
//

#import "ViewController.h"
#import <UserNotifications/UserNotifications.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"发送通知" style:UIBarButtonItemStyleDone target:self action:@selector(postNotification)];
    
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2)];
    imageView.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height/2);
    imageView.image = [UIImage imageNamed:@"lufei"];
    [self.view addSubview:imageView];
    
}

//5秒以后发送本地通知
- (void)postNotification{
    
    UNUserNotificationCenter * center = [UNUserNotificationCenter currentNotificationCenter];
    //校验是否拥有权限，用户可能会关闭通知权限
    [center getNotificationSettingsWithCompletionHandler:^(UNNotificationSettings * _Nonnull settings) {
        NSUInteger status = [settings authorizationStatus];
        NSLog(@"当前的权限是？ %ld",status);
        if (status == 1) {
            return ;
        }
    }];
    //新建通知内容对象
    UNMutableNotificationContent *content = [[UNMutableNotificationContent alloc] init];
    content.title = @"测试通知";//标题
    content.subtitle = @"测试通知角标消失问题";//子标题
    content.body = @"欢迎关注我的Github：https://github.com/wsl2ls，和简书：http://www.jianshu.com/users/e15d1f644bea";//消息的主题
    content.badge = @(1);
    
    //  UNTimeIntervalNotificationTrigger 时间触发器，可以设置多长时间以后触发，是否重复。如果设置重复YES，重复时长要大于60s
    UNTimeIntervalNotificationTrigger *trigger1 = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:5.0 repeats:NO];
    NSString *requertIdentifier = [NSString stringWithFormat:@"requertIdentifier%d",arc4random()%100];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:requertIdentifier content:content trigger:trigger1];
    
    //第五步：将通知加到通知中心
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:^(NSError * _Nullable error) {
        NSLog(@"Error:%@",error);
    }];
    
}


@end
