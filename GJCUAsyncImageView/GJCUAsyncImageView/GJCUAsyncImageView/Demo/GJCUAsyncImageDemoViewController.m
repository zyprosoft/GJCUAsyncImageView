//
//  GJCFAsyncImageDemoViewController.m
//  GJCommonFoundation
//
//  Created by ZYVincent on 14-10-30.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCUAsyncImageDemoViewController.h"
#import "GJCUAsyncImageView.h"

@interface GJCUAsyncImageDemoViewController ()

@end

@implementation GJCUAsyncImageDemoViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    GJCUAsyncImageView *imageView0 = [[GJCUAsyncImageView alloc]init];
    imageView0.frame = (CGRect){10,100,88,88};
    [self.view addSubview:imageView0];
    
    
    GJCUAsyncImageView *imageView1 = [[GJCUAsyncImageView alloc]init];
    imageView1.frame = (CGRect){10,200,88,88};
    [self.view addSubview:imageView1];
    
    GJCUAsyncImageView *imageView2 = [[GJCUAsyncImageView alloc]init];
    imageView2.frame = (CGRect){10,290,88,88};
    [self.view addSubview:imageView2];
    
    GJCUAsyncImageView *imageView3 = [[GJCUAsyncImageView alloc]init];
    imageView3.frame = (CGRect){10,380,88,88};
    [self.view addSubview:imageView3];
    
    
    imageView0.showDownloadIndicator = YES;
    imageView1.showDownloadIndicator = YES;
    imageView2.showDownloadIndicator = YES;
    imageView3.showDownloadIndicator = YES;
    
    /* 下载 */
    [imageView0 setUrl:@"http://g.hiphotos.baidu.com/image/w%3D310/sign=c8e79be89c510fb378197196e933c893/377adab44aed2e73a5fe537d8501a18b87d6fa48.jpg"];
    
    [imageView1 setUrl:@"http://a.hiphotos.baidu.com/image/w%3D310/sign=a9da57abf503738dde4a0a23831ab073/f603918fa0ec08fa41e63bac5aee3d6d54fbdad2.jpg"];
    
    [imageView2 setUrl:@"http://a.hiphotos.baidu.com/image/w%3D310/sign=c7098e7673cf3bc7e800cbede100babd/0e2442a7d933c8957143ea00d21373f08202008f.jpg"];
    
    [imageView3 setUrl:@"http://h.hiphotos.baidu.com/image/w%3D310/sign=152abdeebc096b63811958513c328733/ac345982b2b7d0a213987e5cc9ef76094a369a99.jpg"];
}



@end
