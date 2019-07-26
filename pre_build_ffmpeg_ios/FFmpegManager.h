//
//  FFmpegManager.h
//  ZJHVideoProcessing
//
//  Created by  guogh on 2019/3/11.
//  Copyright © 2019  guogh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FFmpegManager : NSObject

+ (FFmpegManager *)sharedManager;



/**
 执行命令

 @param commandStr ffmpeg完整命令
 */
- (void)runCmd:(NSString *)commandStr
    completionBlock:(void(^)(NSError *error))compleBlock;


/**
 转换视频

 @param inputPath 输入视频路径
 @param outpath 输出视频路径
 @param processBlock 进度回调
 @param completionBlock 结束回调
 */
- (void)converWithInputPath:(NSString *)inputPath
                 outputPath:(NSString *)outpath
               processBlock:(void (^)(float process))processBlock
            completionBlock:(void (^)(NSError *error))completionBlock;

// 设置总时长
+ (void)setDuration:(long long)time;

// 设置当前时间
+ (void)setCurrentTime:(long long)time;

// 转换停止
+ (void)stopRuning;

@end
