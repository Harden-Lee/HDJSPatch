//
//  HDHotUpdateInfo.h
//  JSPatchExample
//
//  Created by Harden.L on 2020/2/16.
//  Copyright © 2020 Harden.L. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HDHotUpdateInfo : NSObject

//是否有热更新 0 没有 1 有
@property (nonatomic,assign)NSInteger bHaveHot;

//热更新迭代版本号
@property (nonatomic,assign)NSInteger hotJSVersion;

//热更新文件名（main.js）
@property (nonatomic,strong)NSString *JSPath;

//RSA加密后的热更新文件（main.js）的MD5值
@property (nonatomic,strong)NSString *JSRSAMD5;

@end
