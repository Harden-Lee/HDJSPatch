//
//  HDLoad.m
//  JSPatchExample
//
//  Created by Harden.L on 2020/2/16.
//  Copyright © 2020 Harden.L. All rights reserved.
//

#import "HDLoad.h"
#import "SHXMLParser.h"
#import "MJExtension.h"
#include <CommonCrypto/CommonDigest.h>
//#import "AGCryptorTools.h"

@implementation HDLoad

static HDLoad *instance = nil;

+ (HDLoad *)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[HDLoad alloc] init];
    });
    return instance;
}

-(instancetype)initWithBaseUrl:(NSString *)baseUrl {
    if (self = [super init]) {
        self.baseUrl = baseUrl;
    }
    return self;
}

- (NSString *)loadLocalJavaScript:(NSString *)JSUrl {
    // 1、获取JS文件路径，根据上一步中创建本地JS路径的方法来获取
    NSString * filePath = [self JSFilePath:JSUrl];
    // 2、根据本地JS路径创建script
    NSString *script = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    
    // 3、判断JS对象并返回
    if (script != nil) {
        return script;
    }
    return nil;
}

- (NSString *)JSFilePath:(NSString *)JSUrl {
    // 1、获取document文件夹路径
    NSString * documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    // 2、创建DownloadJS文件夹
    NSString * downloadJSPath = [documentPath stringByAppendingPathComponent:@"DownloadJS"];
    
    // 3、创建文件管理器对象
    NSFileManager * fileManager = [NSFileManager defaultManager];
    
    // 4、判断文件夹是否存在
    if (![fileManager fileExistsAtPath:downloadJSPath])
    {
        [fileManager createDirectoryAtPath:downloadJSPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // 5、拼接JS在沙盒中的路径
    NSString * JSName  = [JSUrl stringByReplacingOccurrencesOfString:@"/" withString:@"_"];
    NSString * JSFilePath = [downloadJSPath stringByAppendingPathComponent:JSName];
    
    // 6、返回文件路径
    return JSFilePath;
}

- (void)requestJSUrl:(NSString *)JSUrl force:(BOOL)bForce successBlock:(JSLoadSuccess)successBlock errorBlock:(JSLoadError)errorBlock {
    
//    self.successBlock = successBlock;
//    self.errorBlock = errorBlock;
    
    if (!bForce) {//强制从网络下载
        // 下载JS之前先检查本地是否已经有JS
        NSString * script = [self loadLocalJavaScript:JSUrl];
        //如果JS存在直接跳出；不用下载了
        if (script) {
            successBlock(script);
            return;
        }
    }
    // 没有本地JS
    // 创建URL对象
    NSString *JSPath = [NSString stringWithFormat:@"%@%@",self.baseUrl,JSUrl];
    NSURL *url = [NSURL URLWithString:[JSPath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    // 创建request对象
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 使用URLSession来进行网络请求
    // 创建会话配置对象
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    // 创建会话对象
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    // 创建会话任务对象
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            // 将下载的数据转换成javaScript字符串
            NSString *script = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            // 下载完成，将JS数据保存到本地
            [data writeToFile:[self JSFilePath:JSUrl] atomically:YES];
            //回调
            successBlock(script);
        }
        if (error) {
            errorBlock(error);
        }
    }];
    
    // 创建的task都是挂起状态，需要resume才能执行
    [task resume];
}

- (void)requestHotUpdate:(NSString *)hotUpdate successBlock:(hotUpdateLoadSuccess)successBlock errorBlock:(JSLoadError)errorBlock {
    // 创建URL对象
    NSString *hotUpdatePath = [NSString stringWithFormat:@"%@%@",self.baseUrl,hotUpdate];
    NSURL *url = [NSURL URLWithString:[hotUpdatePath stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    // 创建request对象
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 使用URLSession来进行网络请求
    // 创建会话配置对象
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    // 创建会话对象
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    // 创建会话任务对象
    NSURLSessionTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data) {
            NSString *resultStr = [self dataToString:data];
            if(resultStr.length) {
                SHXMLParser *xmlparser = [[SHXMLParser alloc]init];
                NSDictionary *xmldic = [xmlparser parseData:[resultStr dataUsingEncoding:NSUTF8StringEncoding]];
                HDHotUpdateInfo *info = [[HDHotUpdateInfo alloc]init];
                NSDictionary *updateInfo = [SHXMLParser getDataAtPath:@"update" fromResultObject:xmldic];
                info = [HDHotUpdateInfo mj_objectWithKeyValues:updateInfo];
                //回调
                successBlock(info);
            }
        }
        if (error) {
            errorBlock(error);
        }
    }];
    
    // 创建的task都是挂起状态，需要resume才能执行
    [task resume];
}

- (NSString *)dataToString:(NSData *)sourceData {
    if (!sourceData) {
        return @"";
    }
    NSString *desString = [[NSString alloc] initWithData:sourceData encoding:NSUTF8StringEncoding];
    
    if (!desString) {
        //如果sourceData中有乱码，解析失败，则一个一个字节的重新解析，并去掉乱码部分
        NSData *newData = nil;
        NSString *roomStr = @"";
        for (int count = 0; count < sourceData.length; count ++) {
            newData = [sourceData subdataWithRange:NSMakeRange(count, 1)];
            NSString *tempStr = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
            if (tempStr) {
                roomStr = [roomStr stringByAppendingString:tempStr];
            }
        }
        return roomStr;
    }
    return desString;
}

@end
