//
//  DemoImageListViewController.m
//  GJCUAsyncImageView
//
//  Created by ZYVincent on 15/7/18.
//  Copyright (c) 2015年 ZYProSoft. All rights reserved.
//

#import "DemoImageListViewController.h"
#import "GJCUAsyncImageView.h"

#define DemoAsyncImageViewTag 898999

@interface DemoImageListViewController ()

@property (nonatomic,strong)NSMutableArray *sourceArray;

@end

@implementation DemoImageListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.sourceArray = [[NSMutableArray alloc]init];
    
    //图片
    [self.sourceArray addObject:@"http://img4.duitang.com/uploads/item/201404/30/20140430231146_j4SxK.jpeg"];
    [self.sourceArray addObject:@"http://img5.duitang.com/uploads/item/201206/06/20120606175247_tCLTW.jpeg"];
    [self.sourceArray addObject:@"http://www.33.la/uploads/20140403sj/7271.jpg"];
    [self.sourceArray addObject:@"http://img4q.duitang.com/uploads/item/201308/12/20130812114403_WFVCd.jpeg"];
    [self.sourceArray addObject:@"http://img5.duitang.com/uploads/item/201206/06/20120606175201_WZ2F3.thumb.700_0.jpeg"];
    [self.sourceArray addObject:@"http://dg2.zol-img.com.cn/74_module_images/19/53dee58fa5a79.jpg"];
    [self.sourceArray addObject:@"http://cdn.duitang.com/uploads/item/201405/10/20140510221440_zvkHi.thumb.700_0.jpeg"];
    [self.sourceArray addObject:@"http://dg2.zol-img.com.cn/74_module_images/19/53fd36639d10b.jpg"];
    [self.sourceArray addObject:@"http://img5.duitang.com/uploads/item/201406/27/20140627094415_zNPRi.thumb.700_0.jpeg"];
    [self.sourceArray addObject:@"http://img4.duitang.com/uploads/item/201308/16/20130816090111_LBvCd.jpeg"];
    [self.sourceArray addObject:@"http://d.3987.com/yrczs_140317/002.jpg"];
    [self.sourceArray addObject:@"http://img2.mtime.com/mg/2009/36/9a1d9903-71c6-4654-8b42-673bdad3aaef.jpg"];
    [self.sourceArray addObject:@"http://www.33.la/uploads/sjbz/fengguang/ltbytpgqsj_6775.jpg"];
    [self.sourceArray addObject:@"http://img1.gamedog.cn/2013/07/22/44-130H20ZA10.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/yzkjs_140313/005.jpg"];
    [self.sourceArray addObject:@"http://img4.duitang.com/uploads/item/201406/27/20140627094315_Wfcv5.thumb.700_0.jpeg"];
    [self.sourceArray addObject:@"http://www.bz55.com/uploads/140710/1-140G0120409415.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/runns_140317/005.jpg"];
    [self.sourceArray addObject:@"http://img5.duitang.com/uploads/item/201406/05/20140605214136_8cMdF.jpeg"];
    [self.sourceArray addObject:@"http://tupian.qqjay.com/u/2012/0915/1_17439_15.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/jscy_141103/001.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/xllq_140102/009.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/tysjs_140321/007.jpg"];
    [self.sourceArray addObject:@"http://img1.gamedog.cn/2013/07/22/44-130H20ZA10-50.jpg"];
    [self.sourceArray addObject:@"http://cdn.duitang.com/uploads/item/201409/13/20140913141520_Ydidj.jpeg"];
    [self.sourceArray addObject:@"http://d.3987.com/ydxxs_140127/004.jpg"];
    [self.sourceArray addObject:@"http://www.33.la/uploads/20140403sj/5663.jpg"];
    [self.sourceArray addObject:@"http://f4.topit.me/4/5d/0a/11785232823460a5d4o.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/ommms_140319/007.jpg"];
    [self.sourceArray addObject:@"http://img1.gamedog.cn/2013/07/22/44-130H20Z6490-50.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/jlrm_140107/002.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/jdwq_13127/001.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/lmql_131101/003.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/kayeip_130531/001.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/dxrhqx_130518/002.jpg"];
    [self.sourceArray addObject:@"http://d.3987.com/hwmm_140904/002.jpg"];

    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    return self.sourceArray.count;
    
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"CellIdentifier";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // Configure the cell...
    if (!cell) {
        
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        GJCUAsyncImageView *asyncImageView = [[GJCUAsyncImageView alloc]init];
        asyncImageView.gjcf_left = 30.f;
        asyncImageView.gjcf_top = 15.f;
        asyncImageView.gjcf_size = CGSizeMake(90, 90);
        asyncImageView.tag = DemoAsyncImageViewTag;
        
        [cell.contentView addSubview:asyncImageView];
    }
    
    //重新设置Url
    NSString *imageUrl = [self.sourceArray objectAtIndex:indexPath.row];
    
    GJCUAsyncImageView *imageView = (GJCUAsyncImageView *)[cell.contentView viewWithTag:DemoAsyncImageViewTag];
    imageView.image = nil;
    
    [imageView setUrl:imageUrl];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90 + 15*2;
}



@end
