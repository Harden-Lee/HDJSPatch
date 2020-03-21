//
//  HDTools.h
//  JSPatchExample
//
//  Created by Harden.L on 2020/2/16.
//  Copyright © 2020 Harden.L. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HDTools : NSObject

/**
 * @brief 获取应用的版本号
 * @return app版本 如:1.0.9
 */
+ (NSString *)appVersion;


/**
 * @brief 获取应用 build 版本号
 * @return app build版本 如:9
 */
+ (NSString *)appBuildVersion;
@end
