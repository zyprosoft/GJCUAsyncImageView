//
//  GJCFFileDownloadManager.m
//  GJCommonFoundation
//
//  Created by ZYVincent on 14-9-18.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCFFileDownloadManager.h"
#import "AFHTTPRequestOperationManager.h"
#import "AFHTTPRequestOperation.h"
#import "GJCFUitils.h"
#import "ZYNetWorkManager.h"
#import "ZYNetWorkTask.h"
#import "ZYNetWorkConst.h"

static NSString * kGJCFFileDownloadManagerCompletionBlockKey = @"kGJCFFileUploadManagerCompletionBlockKey";

static NSString * kGJCFFileDownloadManagerProgressBlockKey = @"kGJCFFileUploadManagerProgressBlockKey";

static NSString * kGJCFFileDownloadManagerFaildBlockKey = @"kGJCFFileUploadManagerFaildBlockKey";

static NSString * kGJCFFileDownloadManagerObserverUniqueIdentifier = @"kGJCFFileDownloadManagerObserverUniqueIdentifier";


@interface GJCFFileDownloadManager ()

@property (nonatomic,strong)NSMutableArray *taskArray;

@property (nonatomic,strong)NSMutableDictionary *taskOberverAction;

@property (nonatomic,strong)NSString *innerDefaultHost;

@end

@implementation GJCFFileDownloadManager

+ (GJCFFileDownloadManager *)shareDownloadManager
{
    static GJCFFileDownloadManager *_downloadManager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
       
        if (!_downloadManager) {
            _downloadManager = [[self alloc]init];
        }
    });
    return _downloadManager;
}

- (id)init
{
    if (self = [super init]) {
        
        self.taskArray = [[NSMutableArray alloc]init];
        self.taskOberverAction = [[NSMutableDictionary alloc]init];

        
    }
    return self;
}


#pragma mark - 观察者调用
+ (NSString*)uniqueKeyForObserver:(NSObject*)observer
{
    return [NSString stringWithFormat:@"%@_%lu",kGJCFFileDownloadManagerObserverUniqueIdentifier,(unsigned long)[observer hash]];
}

#pragma mark - 公开方法

/* 设置默认主机地址 */
- (void)setDefaultDownloadHost:(NSString *)host
{
    if ([_innerDefaultHost isEqualToString:host]) {
        return;
    }
    _innerDefaultHost = nil;
    _innerDefaultHost = [host copy];
}

- (void)addTask:(GJCFFileDownloadTask *)task
{
    if (!task) {
        NSLog(@"GJFileDownloadManager 错误: 试图添加一个空的下载任务:%@",task);
        return;
    }
    
    /* 如果没有指定下载地址，那么就不开始了 */
    if (![task isValidateForDownload]) {
        NSLog(@"GJCFFileDownloadManager 错误: 下载任务没有目标下载地址:%@",task.downloadUrl);
        return;
    }
    
    //使用新的网络组件
    ZYNetWorkTask *netWorkTask = [[ZYNetWorkTask alloc]init];
    netWorkTask.downloadUrl = task.downloadUrl;
    netWorkTask.groupTaskIdentifier = task.groupTaskIdentifier;
    netWorkTask.requestMethod = ZYNetworkRequestMethodGET;
    netWorkTask.taskType = ZYNetworkTaskTypeDownloadFile;
    
    /* 如果有相同的下载任务就不添加进入队列 */
    for (GJCFFileDownloadTask *dTask in self.taskArray) {
        
        if ([task isEqualToTask:dTask]) {
            
            /* 将这个任务的所有观察者添加到存在的任务的观察者中 */
            for (NSString *observer in task.taskObservers) {
                [dTask addTaskObserverFromOtherTask:observer];
            }            
        }
    }
    
    /* 建立下载链接 */
    netWorkTask.userInfo = @{@"task": task,@"taskIdentifier":task.taskUniqueIdentifier};
    
    //成功
    netWorkTask.successBlock = ^(ZYNetWorkTask *task , id response){
        
        GJCFFileDownloadTask *downloadTask = [task.userInfo objectForKey:@"task"];

        [self completionWithTask:downloadTask resultData:response];
        
    };
    
    //失败
    netWorkTask.faildBlock = ^(ZYNetWorkTask *task , NSError *error){
      
        GJCFFileDownloadTask *downloadTask = [task.userInfo objectForKey:@"task"];
        
        [self faildWithTask:downloadTask faild:error];
    };
    
    //进度
    netWorkTask.progressBlock = ^(ZYNetWorkTask *task, CGFloat progress){
      
        GJCFFileDownloadTask *downloadTask = [task.userInfo objectForKey:@"task"];

         [self progressWithTask:downloadTask progress:progress];
    };

    //进入下载管理
    [[ZYNetWorkManager shareManager]addTask:netWorkTask];
    
}

#pragma mark - 请求的三个状态
- (void)completionWithTask:(GJCFFileDownloadTask *)task resultData:(NSData*)downloadData
{
    NSArray *taskObservers = task.taskObservers;
    task.taskState = GJFileDownloadStateSuccess;
        
    /* 如果任务设定了存储路径 */
    BOOL cacheState = NO;
    if (downloadData) {
        
        if (task.cachePath) {
            
            cacheState = [downloadData writeToFile:task.cachePath atomically:YES];

        }
        
        for (NSString *path in task.cacheToPaths) {
            
            [downloadData writeToFile:path atomically:YES];
        }
    }
    
    [taskObservers enumerateObjectsUsingBlock:^(NSString *observeUniqueIdentifier, NSUInteger idx, BOOL *stop) {
       
        NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:observeUniqueIdentifier];
        
//        NSLog(@"GJCFFileDownloadManager 找到响应任务block:%@",actionDict);
        
        if (actionDict) {
            
            GJCFFileDownloadManagerCompletionBlock completionBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerCompletionBlockKey];
            
            
            if (completionBlcok) {
            
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    completionBlcok(task,downloadData,cacheState);

                });
                
            }
            
        }
        
    }];
    
    [self.taskArray removeObject:task];
    
    /* 取消相同的下载任务 */
    [self cancelSameUrlDownloadTaskForTask:task];
}

- (void)progressWithTask:(GJCFFileDownloadTask *)task progress:(CGFloat)progress
{
    NSArray *taskObservers = task.taskObservers;

    [taskObservers enumerateObjectsUsingBlock:^(NSString *observeUniqueIdentifier, NSUInteger idx, BOOL *stop) {
        
        NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:observeUniqueIdentifier];
        
        if (actionDict) {
            
            GJCFFileDownloadManagerProgressBlock progressBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerProgressBlockKey];
            
            
            if (progressBlcok) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    progressBlcok(task,progress);

                });
                
            }
            
        }
        
    }];

}

- (void)faildWithTask:(GJCFFileDownloadTask *)task faild:(NSError*)error
{
    NSArray *taskObservers = task.taskObservers;
    task.taskState = GJFileDownloadStateHadFaild;
    
    [taskObservers enumerateObjectsUsingBlock:^(NSString *observeUniqueIdentifier, NSUInteger idx, BOOL *stop) {
        
        NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:observeUniqueIdentifier];
        
        if (actionDict) {
            
            GJCFFileDownloadManagerFaildBlock faildBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerFaildBlockKey];
            
            
            if (faildBlcok) {
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    
                    faildBlcok(task,error);

                });
            }
            
        }
        
    }];

    [self.taskArray removeObject:task];
}

#pragma mark - 设定任务观察者
/*
 * 设定观察者完成方法
 */
- (void)setDownloadCompletionBlock:(GJCFFileDownloadManagerCompletionBlock)completionBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerUnique = [GJCFFileDownloadManager uniqueKeyForObserver:observer];
    
    NSMutableDictionary *observerActionDict = nil;
    if (![self.taskOberverAction objectForKey:observerUnique]) {
        
        observerActionDict = [NSMutableDictionary dictionary];
        
    }else{
        
        observerActionDict = [self.taskOberverAction objectForKey:observerUnique];
    }
    
    [observerActionDict setObject:completionBlock forKey:kGJCFFileDownloadManagerCompletionBlockKey];
    [self.taskOberverAction setObject:observerActionDict forKey:observerUnique];
}

/*
 * 设定观察者进度方法
 */
- (void)setDownloadProgressBlock:(GJCFFileDownloadManagerProgressBlock)progressBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerUnique = [GJCFFileDownloadManager uniqueKeyForObserver:observer];

    NSMutableDictionary *observerActionDict = nil;
    if (![self.taskOberverAction objectForKey:observerUnique]) {
        
        observerActionDict = [NSMutableDictionary dictionary];
        
    }else{
        
        observerActionDict = [self.taskOberverAction objectForKey:observerUnique];
    }
    
    [observerActionDict setObject:progressBlock forKey:kGJCFFileDownloadManagerProgressBlockKey];
    [self.taskOberverAction setObject:observerActionDict forKey:observerUnique];
}

/*
 * 设定观察者失败方法
 */
- (void)setDownloadFaildBlock:(GJCFFileDownloadManagerFaildBlock)faildBlock forObserver:(NSObject*)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerUnique = [GJCFFileDownloadManager uniqueKeyForObserver:observer];

    NSMutableDictionary *observerActionDict = nil;
    if (![self.taskOberverAction objectForKey:observerUnique]) {
        
        observerActionDict = [NSMutableDictionary dictionary];
        
    }else{
        
        observerActionDict = [self.taskOberverAction objectForKey:observerUnique];
    }
    
    [observerActionDict setObject:faildBlock forKey:kGJCFFileDownloadManagerFaildBlockKey];
    [self.taskOberverAction setObject:observerActionDict forKey:observerUnique];
}

/*
 * 将观察者的block全部清除
 */
- (void)clearTaskBlockForObserver:(NSObject *)observer
{
    if (!observer) {
        return;
    }
    
    NSString *observerUnique = [GJCFFileDownloadManager uniqueKeyForObserver:observer];

    if (![self.taskOberverAction.allKeys containsObject:observerUnique]) {
        return;
    }
    
    [self.taskOberverAction removeObjectForKey:observerUnique];
}

- (NSInteger)taskIndexForUniqueIdentifier:(NSString *)identifier
{
    NSInteger resultIndex = NSNotFound;
    for (int i = 0; i < self.taskArray.count ; i++) {
        
        GJCFFileDownloadTask *task = [self.taskArray objectAtIndex:i];
        
        if ([task.taskUniqueIdentifier isEqualToString:identifier]) {
            
            resultIndex = i;
            
            break;
        }
    }
    return resultIndex;
}

- (void)cancelTask:(NSString *)taskUniqueIdentifier
{
    if (GJCFStringIsNull(taskUniqueIdentifier)) {
        return;
    }
    
    NSInteger taskIndex = [self taskIndexForUniqueIdentifier:taskUniqueIdentifier];
    if (taskIndex == NSNotFound) {
        return;
    }
    GJCFFileDownloadTask *task = [self.taskArray objectAtIndex:taskIndex];
    
    /* 移除任务的所有观察者block */
    [task.taskObservers enumerateObjectsUsingBlock:^(NSString *observerIdentifier, NSUInteger idx, BOOL *stop) {
        
        [self clearTaskBlockForObserver:observerIdentifier];
        
    }];
    
    /* 退出任务 */
    NSDictionary *userInfoValues = @{
                                     @"taskIdentifier":taskUniqueIdentifier,
                                     };
    
    [[ZYNetWorkManager shareManager] cancelTaskByUserInfoValues:userInfoValues];
    
}

- (NSArray *)groupTaskByUniqueIdentifier:(NSString *)groupTaskIdnetifier
{
    NSMutableArray *groupTaskArray = [NSMutableArray array];
    
    for (GJCFFileDownloadTask *task in self.taskArray) {
        
        if ([task.groupTaskIdentifier isEqualToString:groupTaskIdnetifier]) {
            
            [groupTaskArray addObject:task];
        }
    }
    
    return groupTaskArray;
}

- (void)cancelGroupTask:(NSString *)groupTaskUniqueIdentifier
{
    if (!groupTaskUniqueIdentifier || [groupTaskUniqueIdentifier isKindOfClass:[NSNull class]] || groupTaskUniqueIdentifier.length == 0 || [groupTaskUniqueIdentifier isEqualToString:@""]) {
        return;
    }
    
    NSArray *groupTaskArray = [self groupTaskByUniqueIdentifier:groupTaskUniqueIdentifier];
    if (groupTaskArray.count == 0) {
        return;
    }
    
    for (GJCFFileDownloadTask *task in groupTaskArray) {
        
        /* 移除任务的所有观察者block */
        [task.taskObservers enumerateObjectsUsingBlock:^(NSString *observerIdentifier, NSUInteger idx, BOOL *stop) {
            
            [self clearTaskBlockForObserver:observerIdentifier];
            
        }];
        
        //网络组件退出请求
        [[ZYNetWorkManager shareManager]cancelGroupTask:groupTaskUniqueIdentifier];
        
    }

}

- (void)cancelTaskWithCompletion:(NSString *)taskUniqueIdentifier
{
    if (GJCFStringIsNull(taskUniqueIdentifier)) {
        return;
    }
    
    NSInteger taskIndex = [self taskIndexForUniqueIdentifier:taskUniqueIdentifier];
    if (taskIndex == NSNotFound) {
        return;
    }
    GJCFFileDownloadTask *task = [self.taskArray objectAtIndex:taskIndex];
    
    /* 退出任务 */
    NSDictionary *userInfoValues = @{
                                     @"taskIdentifier":taskUniqueIdentifier,
                                     };
    
    [[ZYNetWorkManager shareManager] cancelTaskByUserInfoValues:userInfoValues];
    
    /* 如果任务设定了存储路径 */
    BOOL cacheState = YES;
    NSData *downloadData = [NSData dataWithContentsOfFile:task.cachePath];
    
    [task.taskObservers enumerateObjectsUsingBlock:^(NSString *observeUniqueIdentifier, NSUInteger idx, BOOL *stop) {
        
        NSMutableDictionary *actionDict = [self.taskOberverAction objectForKey:observeUniqueIdentifier];
        
        //        NSLog(@"GJCFFileDownloadManager 找到响应任务block:%@",actionDict);
        
        if (actionDict) {
            
            GJCFFileDownloadManagerCompletionBlock completionBlcok = [actionDict objectForKey:kGJCFFileDownloadManagerCompletionBlockKey];
            
            if (completionBlcok) {
                
                completionBlcok(task,downloadData,cacheState);
            }
            
        }
        
    }];
    
    /* 移除任务的所有观察者block */
    [task.taskObservers enumerateObjectsUsingBlock:^(NSString *observerIdentifier, NSUInteger idx, BOOL *stop) {
        
        [self clearTaskBlockForObserver:observerIdentifier];
        
    }];
    
    [self.taskArray removeObjectAtIndex:taskIndex];
    
}

- (void)cancelSameUrlDownloadTaskForTask:(GJCFFileDownloadTask *)task
{
    for (GJCFFileDownloadTask *dTask in self.taskArray) {
        
        if ([task isEqualToTask:dTask]) {
            
            [self cancelTaskWithCompletion:dTask.taskUniqueIdentifier];
        }
    }
}

@end
