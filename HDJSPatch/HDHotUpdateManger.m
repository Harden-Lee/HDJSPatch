//
//  HDHotUpdateManger.m
//  JSPatchExample
//
//  Created by Harden.L on 2020/2/16.
//  Copyright © 2020 Harden.L. All rights reserved.
//

#import "HDHotUpdateManger.h"
#import "HDLoad.h"
#import "HDTools.h"
#import "HDCryptorTools.h"
#import "JPEngine.h"

@interface HDHotUpdateManger() {
    
}
@property (nonatomic,strong)HDHotUpdateInfo *updateInfo;
@end

@implementation HDHotUpdateManger

- (instancetype)initWithBaseUrl:(NSString *)url {
    if (self = [super init]) {
        [HDLoad sharedInstance].baseUrl = url?url:HOT_UPDATE_BASE_URL;
    }
    return self;
}

#pragma mark -- 检查是否需要热更新
- (void)checkHotUpdate:(NSString *)hotFileName comp:(completed)complete{
    if (![HDLoad sharedInstance].baseUrl) {
        [HDLoad sharedInstance].baseUrl = HOT_UPDATE_BASE_URL;
    }
    NSString *versionStr = [HDTools appVersion];
    NSString *catalogue = versionStr;
    NSString *hotUrl =[NSString stringWithFormat:@"%@/%@",catalogue,hotFileName];
    __weak typeof(self) weakSelf = self;
    [[HDLoad sharedInstance] requestHotUpdate:hotUrl successBlock:^(HDHotUpdateInfo * updateInfo) {
        weakSelf.updateInfo = updateInfo;
        if (updateInfo.bHaveHot) {
            BOOL bForce = NO;
            if([self hotJSversion] < updateInfo.hotJSVersion){
                [self setHotJSversion:updateInfo.hotJSVersion];
                bForce = YES;
            }
            [self executiveHotUpdateJS:[NSString stringWithFormat:@"%@/%@",catalogue,updateInfo.JSPath] force:bForce comp:complete];
        }else{
            complete(NO);
        }
    } errorBlock:^(NSError *error) {
        NSLog(@"检查失败");
        complete(NO);
    }];
}

#pragma mark -- 热更新JS版本号
NSString* const KHotJSversion = @"hotJSversion";
- (void)setHotJSversion:(NSInteger)hotJSversion {
    NSString *key = [NSString stringWithFormat:@"%@%@",KHotJSversion,[HDTools appBuildVersion]];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:hotJSversion] forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (NSInteger)hotJSversion {
    NSString *key = [NSString stringWithFormat:@"%@%@",KHotJSversion,[HDTools appBuildVersion]];
    return [[[NSUserDefaults standardUserDefaults] objectForKey:key] integerValue];
}

#pragma mark -- 加载JS
- (void)executiveHotUpdateJS:(NSString *)JSUrl force:(BOOL)bForce comp:(completed)complete{
    [JPEngine startEngine];
    [[HDLoad sharedInstance] requestJSUrl:JSUrl force:bForce successBlock:^(NSString * script) {
        if ([self checkFileMD5:[self md5HashOfPath:[[HDLoad sharedInstance] JSFilePath:JSUrl]]]) {
            [JPEngine evaluateScript:script];
            complete(YES);
        } else {
            NSLog(@"JS文件被串改");
            complete(NO);
        }
        
    } errorBlock:^(NSError * error) {
        NSLog(@"加载失败");
        complete(NO);
    }];
}

#pragma mark -- 检查文件是否被串改
- (BOOL)checkFileMD5:(NSString *)md5 {
    HDCryptorTools * tools = [[HDCryptorTools alloc] init];
    NSString *privatePath = [[NSBundle mainBundle] pathForResource:@"p.p12" ofType:nil];
    [tools loadPrivateKey:privatePath password:@"文件密码"];
    // 4. 使用私钥解密
    NSString *fileMD5 = [tools RSADecryptString:_updateInfo.JSRSAMD5];
    if ([md5 isEqualToString:fileMD5]) {
        return YES;
    }
    return NO;
}

#pragma mark -- 获取文件的MD5值
- (NSString *)md5HashOfPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Make sure the file exists
    if( [fileManager fileExistsAtPath:path isDirectory:nil] )
    {
        NSData *data = [NSData dataWithContentsOfFile:path];
        unsigned char digest[CC_MD5_DIGEST_LENGTH];
        CC_MD5( data.bytes, (CC_LONG)data.length, digest );
        
        NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
        
        for( int i = 0; i < CC_MD5_DIGEST_LENGTH; i++ )
        {
            [output appendFormat:@"%02x", digest[i]];
        }
        
        return output;
    }
    else
    {
        return @"";
    }
}

+ (NSString *)getImageUrlWithName:(NSString *)imgName {
   return [NSString stringWithFormat:@"%@%@/%@",HOT_UPDATE_BASE_URL,[HDTools appVersion],imgName];
}

@end
