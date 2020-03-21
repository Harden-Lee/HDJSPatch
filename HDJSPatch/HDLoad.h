//
//  HDLoad.h
//  JSPatchExample
//
//  Created by Harden.L on 2020/2/16.
//  Copyright © 2020 Harden.L. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDHotUpdateInfo.h"

//声明了一个下载成功的block类型
typedef void (^JSLoadSuccess) (NSString *);
//声明一个失败的block类型
typedef void (^JSLoadError) (NSError *);

typedef void (^hotUpdateLoadSuccess) (HDHotUpdateInfo *);

@interface HDLoad : NSObject

@property (nonatomic, strong)NSString *baseUrl;

/**
 * 创建一个Load管理器
 * @return HDLoad单例 @see HDLoad
 */
+ (HDLoad *)sharedInstance;

/**
 * 创建一个Load类
 * @param baseUrl load网址
 * @return HDLoad实例 @see HDLoad
 */
- (instancetype)initWithBaseUrl:(NSString *)baseUrl;

/**
 * 获取下载下来的Js文件路径
 * @param JSUrl JsUrl地址
 * @return JS文件路径
 */
- (NSString *)JSFilePath:(NSString *)JSUrl;

/**
 * 请求JS文件数据
 * @param JSUrl JS下载地址
 * @param bForce 强制从网络下载
 * @param successBlock 成功回调 @see JSLoadSuccess
 * @param errorBlock   失败回调 @see JSLoadError
 */
- (void)requestJSUrl:(NSString *)JSUrl force:(BOOL)bForce successBlock:(JSLoadSuccess)successBlock errorBlock:(JSLoadError)errorBlock;

/**
 * 请求hotUpdate文件数据
 * @param hotUpdate hotUpdate下载地址
 * @param successBlock 成功回调 @see hotUpdateLoadSuccess
 * @param errorBlock   失败回调 @see JSLoadError
 */
- (void)requestHotUpdate:(NSString *)hotUpdate successBlock:(hotUpdateLoadSuccess)successBlock errorBlock:(JSLoadError)errorBlock;

@end
