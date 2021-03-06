//
//  GJCFAsyncImageView.m
//  GJCommonFoundation
//
//  Created by ZYVincent on 14-10-30.
//  Copyright (c) 2014年 ZYProSoft. All rights reserved.
//

#import "GJCUAsyncImageView.h"
#import "GJCFFileDownloadManager.h"
#import "GJCFCachePathManager.h"


@interface GJCUAsyncImageView ()

@property (nonatomic,assign)BOOL isDownloadSuccess;

@property (nonatomic,copy)GJCUAsyncImageViewDownloadTaskProgressBlock taskProgressBlock;

@property (nonatomic,copy)GJCUAsyncImageViewDownloadTaskCompletionBlock taskCompletionBlock;

@end

@implementation GJCUAsyncImageView

- (instancetype)initWithImage:(UIImage *)image highlightedImage:(UIImage *)highlightedImage
{
    if (self = [super initWithImage:image highlightedImage:highlightedImage]) {
        
        [self initStateConfig];
    }
    return self;
}

- (instancetype)initWithImage:(UIImage *)image
{
    if (self = [super initWithImage:image]) {
        
        [self initStateConfig];
    }
    return self;
}

- (instancetype)init
{
    if (self = [super init]) {
        
        [self initStateConfig];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        [self initStateConfig];
    }
    return self;
}

- (void)dealloc
{
    if (self.taskProgressBlock) {
        self.taskProgressBlock = nil;
    }
    if (self.isAutoCancel) {
        [self cancelDownload];
    }
    [[GJCFFileDownloadManager shareDownloadManager]clearTaskBlockForObserver:self];
}

#pragma mark - 内部接口

- (void)initStateConfig
{
    GJCFWeakSelf weakSelf = self;
    
    /* 完成下载 */
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadCompletionBlock:^(GJCFFileDownloadTask *task, NSData *fileData, BOOL isFinishCache) {
        
        if ([task.downloadUrl isEqualToString:weakSelf.url]) {
            
            [weakSelf downloadCompletion:fileData cacheState:isFinishCache];
            
        }
        
    } forObserver:self];
    
    /* 下载失败 */
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadFaildBlock:^(GJCFFileDownloadTask *task, NSError *error) {
        
        if ([task.downloadUrl isEqualToString:weakSelf.url]) {
            
            [weakSelf downloadFaild:error];

        }
        
    } forObserver:self];
    
    /* 下载进度 */
    [[GJCFFileDownloadManager shareDownloadManager]setDownloadProgressBlock:^(GJCFFileDownloadTask *task, CGFloat progress) {
        
        if ([task.downloadUrl isEqualToString:weakSelf.url]) {
            
            [weakSelf downloadProgress:progress];

        }
        
    } forObserver:self];
    
    /* indicator */
    self.indicatorView = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    self.indicatorView.frame = (CGRect){0,0,50,50};
    self.indicatorView.center = self.center;
    [self addSubview:self.indicatorView];
    self.indicatorView.hidden = YES;
    
}

- (void)downloadCompletion:(NSData *)fileData cacheState:(BOOL)finish
{
    self.image = [UIImage imageWithData:fileData];
    self.isDownloadSuccess = YES;
    
    if (self.showDownloadIndicator) {
        [self.indicatorView stopAnimating];
        self.indicatorView.hidden = YES;
    }
    
    if (self.taskCompletionBlock) {
        self.taskCompletionBlock(self,YES);
    }
}

- (void)downloadFaild:(NSError *)error
{
    _downloadProgress = 0.f;
    self.indicatorView.hidden = YES;
    
    if (self.taskCompletionBlock) {
        self.taskCompletionBlock(self,NO);
    }
}

- (void)downloadProgress:(CGFloat)progress
{
    _downloadProgress = progress;
    
    if (self.taskProgressBlock) {
        self.taskProgressBlock(self,progress);
    }
}

#pragma mark - 属性设置

- (NSString *)imageUrlToDefaultCachePath:(NSString *)url
{
    if (GJCFStringIsNull(url)) {
        return nil;
    }
    
    return [[GJCFCachePathManager shareManager]mainImageCacheFilePathForUrl:url];
}

- (BOOL)checkIfCacheImageExist:(NSString *)url
{
    return GJCFFileIsExist([self imageUrlToDefaultCachePath:url]);
}

- (GJCFFileDownloadTask *)createTaskForUrl:(NSString *)url forCachePath:(NSString *)cachePath
{
    NSString *taskIdentifier;
    GJCFFileDownloadTask *downloadTask = [GJCFFileDownloadTask taskWithDownloadUrl:url withCachePath:cachePath withObserver:self getTaskIdentifer:&taskIdentifier];
    _downloadTaskUniqueIdentifier = taskIdentifier;
    
    return downloadTask;
}
- (void)setUrl:(NSString *)url
{
    if (GJCFStringIsNull(url)) {
        return;
    }
    
    self.cachePath = nil;

    /* 检测缓存路径有没有这个文件 */
    if (GJCFFileIsExist(self.cachePath)) {
        self.image = GJCFQuickImageByFilePath(self.cachePath);
        self.isDownloadSuccess = YES;
        if (self.taskCompletionBlock) {
            self.taskCompletionBlock(self,YES);
        }
        return;
    }
    
    /* 检测默认缓存是否有这个图片 */
    if ([self checkIfCacheImageExist:url]) {
        self.image = GJCFQuickImageByFilePath([self imageUrlToDefaultCachePath:url]);
        self.isDownloadSuccess = YES;
        if (self.taskCompletionBlock) {
            self.taskCompletionBlock(self,YES);
        }
        return;
    }
    
    _url = nil;
    _url = [url copy];
    
    [self startDownload];
}

- (UIImage *)cachedImage
{
    if (GJCFStringIsNull(self.cachePath) && GJCFStringIsNull(self.url)) {
        return nil;
    }
    
    /* 检测缓存路径有没有这个文件 */
    if (GJCFFileIsExist(self.cachePath)) {
        
        self.isDownloadSuccess = YES;
        
        return  GJCFQuickImageByFilePath(self.cachePath);
    }
    
    /* 检测默认缓存是否有这个图片 */
    if ([self checkIfCacheImageExist:self.url]) {
        
        self.isDownloadSuccess = YES;

        return GJCFQuickImageByFilePath([self imageUrlToDefaultCachePath:self.url]);
    }
    
    return nil;
}

#pragma mark - 外部接口

- (void)startDownload
{
    if (!self.cachePath) {
        self.cachePath = [self imageUrlToDefaultCachePath:self.url];
    }
    GJCFFileDownloadTask *downloadTask = [self createTaskForUrl:self.url forCachePath:self.cachePath];
    downloadTask.groupTaskIdentifier = self.groupDownloadTaskIdentifier;
    [[GJCFFileDownloadManager shareDownloadManager]addTask:downloadTask];
    
    /* indicator */
    if (self.showDownloadIndicator) {
        self.indicatorView.hidden = NO;
        [self.indicatorView startAnimating];
    }
}

- (void)cancelDownload
{
    if (self.downloadTaskUniqueIdentifier) {
        [[GJCFFileDownloadManager shareDownloadManager]cancelTask:self.downloadTaskUniqueIdentifier];
        
        if (self.taskCompletionBlock) {
            self.taskCompletionBlock(self,NO);
        }
    }
}

+ (void)cancelGroupDownloadTask:(NSString *)groupTaskIdentifier
{
    [[GJCFFileDownloadManager shareDownloadManager]cancelGroupTask:groupTaskIdentifier];
}

/**
 *  观察下载任务完成
 *
 *  @param completionBlock 观察者
 */
- (void)configDownloadTaskProgressBlock:(GJCUAsyncImageViewDownloadTaskProgressBlock)progressBlock
{
    if (self.taskProgressBlock) {
        self.taskProgressBlock = nil;
    }
    self.taskProgressBlock = progressBlock;
}

- (void)configDownloadTaskCompletionBlock:(GJCUAsyncImageViewDownloadTaskCompletionBlock)completionBlock
{
    if (self.taskCompletionBlock) {
        self.taskCompletionBlock = nil;
    }
    self.taskCompletionBlock = completionBlock;
}

- (void)adjustIndicatorPosition
{
    self.indicatorView.gjcf_centerX = self.gjcf_width/2;
    self.indicatorView.gjcf_centerY = self.gjcf_height/2;
}

@end
