//
//  ImageEngine.h
//  Flippy
//
//  Created by 白鹤 on 16/10/18.
//  Copyright © 2016年 江山如画. All rights reserved.
//

#import <UIKit/UIKit.h>
// 旋转的方向
typedef NS_ENUM(NSInteger ,UIImageRotateOrientation){
    // 左转 90
    UIImageRotateOrientationLeft,
    // 右转 90
    UIImageRotateOrientationRight,
    // 水平旋转 180
    UIImageRotateOrientationDown,
};

typedef void(^completion)(id result);

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@interface ImageEngine : NSObject


/**
 保存到相册
 */
+ (void)savetoAlbum:(UIImage *)image;


/**
 普通SampleBuffer 转化为 UIImage
 */

+ (UIImage *)turnCMSampleBufferRefIntoUIImage:(CMSampleBufferRef)sampleBuffer;

+ (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;


/**
 YUV Samplebuffer 转化为 UIImage
 */
+ (UIImage *) imageFromYUVSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 获得脸型图片

 @param image 图片
 @param size  尺寸

 @return 处理后 的脸形状的 图片
 */
+ (UIImage*)circularScaleAndCropImage:(UIImage*)image size:(CGSize)size;


/**
 旋转图片 按方向

 @param image       图片
 @param orientation 旋转的方向

 @return 旋转后的图片
 */
+ (UIImage *)rotateImage:(UIImage *)image rotation:(UIImageRotateOrientation)orientation;

/**
 旋转图片 按角度 不会出现被切掉,但是会等比缩小

 @param image 图片
 @param angle 旋转的角度
 @return 旋转后的图片
 */
+ (UIImage *)rotateImage:(UIImage *)image angel:(CGFloat)angle;


/**
	加半透明水印
	@param useImage 水印的图片
	@returns 加好水印的图片
 */
+ (UIImage *)addMaskImage:(UIImage *)maskImage toImage:(UIImage *)useImage msakRect:(CGRect)rect;


/**
 将图片数组合成视频 有点瑕疵,线程不能停止

 @param imagesArr     图片数组
 @param moviePath     视频保存的路径
 @param size          尺寸
 @param fps           帧率
  @param result        回调
 */
+ (void)combineImagesArr:(NSArray *)imagesArr toMoviePath:(NSString *)moviePath withSize:(CGSize)size FPS:(int32_t)fps completion:(completion)result;
/**
 将图片数组合成视频 第二种方法 太耗费时间了 也可能是没有配置好参数

 @param imagesArray 图片数组
 @param path        保存的视频的 路径
 @param size        保存的视频的 尺寸
 @param duration    保存的视频的 总的时长
 @param fps         保存的视频的 帧率
 @param result      合成成功后的回调
 */
+ (void)combineImages:(NSArray *)imagesArray ToMovieAtPath:(NSString *) path withSize:(CGSize)size inDuration:(float)duration byFPS:(int32_t)fps completion:(completion)result;



/**
 将 Image 转化为 pixelBuffer

 @param image image
 @param size   尺寸

 @return 返回的 pixelBuffer
 */
+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size;

@end
