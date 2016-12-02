//
//  MovieEngine.h
//  Flippy
//
//  Created by 白鹤 on 16/10/17.
//  Copyright © 2016年 江山如画. All rights reserved.
//
#import <UIKit/UIKit.h>

typedef void(^ImageArr)(NSArray *result);

typedef void(^completion)(id result);

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>

#import "ImageEngine.h"


@interface MovieEngine : NSObject

/**
 获得视频的每一帧

 @param urlPath     视频的路径
 @param toFace      是否变成脸的形状
 @param fps         帧率
 @param value       总帧数
 @param resultImage 成功的回调
 */
+ (void)getEveryBufferWithMovie:(NSString *)urlPath toFace:(BOOL)toFace FPS:(NSInteger)fps value:(NSInteger)value completion:(ImageArr)resultImage;


/**
 获取视频的一帧

 @param time     获取视频第几帧的图片
 @param fps      视频的帧率

 */
+ (void) imageForVideoPath:(NSString *)videoPath atTime:(NSInteger)time FPS:(int32_t)fps completion:(ImageArr)resultImage;

/**
 将第一个视频的声音合成到第二个视频上

 @param audioMoviePath 提供音频的视频路径
 @param moviePath      提供视频的音频路径
 @param fps            合成后的视频的帧率
 @param result         结束回调
 */
+ (void)combineMovieAudio:(NSString *)audioMoviePath toMovie:(NSString *)moviePath MovieFPS:(NSInteger)fps completion:(completion)result;


/**
 获取音频 所代表 的 数据
 
 @param url 视频或音频的 URL

 @return  音频所包含的数据
 */
+ (NSData *)getRecorderDataFromURL:(NSURL *)url;



/**
 将音频数据 分为几段 保存当前段落里的最大值

 @param data        音频数据
 @param sampleCount 要分成几段

 @return 包含每段最大值的数据
 */
+ (NSArray *)cutAudioData:(NSData *)data Count:(NSInteger)sampleCount;

/**
 *  将视频保存到相簿中
 *
 *  @param outputFileURL 视频的地址
 */
//+ (void)saveVideoToAlbumOutputFileStr:(NSString *)outputFileURL;





@end
