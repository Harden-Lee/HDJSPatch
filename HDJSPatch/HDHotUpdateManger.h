//
//  HDHotUpdateManger.h
//  JSPatchExample
//
//  Created by Harden.L on 2020/2/16.
//  Copyright © 2020 Harden.L. All rights reserved.
//

#import <Foundation/Foundation.h>

#define HOT_UPDATE_BASE_URL @"https://www01-388cc.firebaseapp.com/hotUpdate/"

//热更新回调，update = NO，没有热更新 update = YES 有热更新
typedef void (^completed) (BOOL update);

@interface HDHotUpdateManger : NSObject

/**
 * 初始化热更新处理类
 * @param url 热更新下载地址 如果url = nil，那热更新就为默认地址：HOT_UPDATE_BASE_URL @see HOT_UPDATE_BASE_URL
 * @return AGHotUpdateManger @see AGHotUpdateManger
 */
- (instancetype)initWithBaseUrl:(NSString *)url;

/**
 * 检查热更新
 * @param hotFileName 热更新控制文件名
 * @param complete 热更新完成回调 @see completed
 */
- (void)checkHotUpdate:(NSString *)hotFileName comp:(completed)complete;

/**
 * 获取热更新图片地址
 * @param imgName 图片名称
 * @return 图片地址
 */
+ (NSString *)getImageUrlWithName:(NSString *)imgName;

@end
