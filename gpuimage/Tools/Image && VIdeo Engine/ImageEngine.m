//
//  ImageEngine.m
//  Flippy
//
//  Created by 白鹤 on 16/10/18.
//  Copyright © 2016年 江山如画. All rights reserved.
//



#import "ImageEngine.h"

@implementation ImageEngine

#pragma mark 保存到相册
+ (void)savetoAlbum:(UIImage *)image{
    
    UIViewController *vc = [UIApplication sharedApplication].keyWindow.rootViewController;
    
    UIImageWriteToSavedPhotosAlbum(image, vc, nil, nil);
}

#pragma mark 通过sampleBuffer创建一个UIImage对象
+ (UIImage *)turnCMSampleBufferRefIntoUIImage:(CMSampleBufferRef)sampleBuffer{
    
    //  CMSampleBufferRef 转为NSData
    
    //制作 CVImageBufferRef
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    
    //从 CVImageBufferRef 取得影像的细部信息
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    //利用取得影像细部信息格式化 CGContextRef
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    //透过 CGImageRef 将 CGContextRef 转换成 UIImage
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
    
    
    return image;
}

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // 为媒体数据设置一个CMSampleBuffer的Core Video图像缓存对象
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // 锁定pixel buffer的基地址
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    
    // 得到pixel buffer的基地址
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    
    // 得到pixel buffer的行字节数
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // 得到pixel buffer的宽和高
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    // 创建一个依赖于设备的RGB颜色空间
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    // 用抽样缓存的数据创建一个位图格式的图形上下文（graphics context）对象
    CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
                                                 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // 根据这个位图context中的像素数据创建一个Quartz image对象
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // 解锁pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer,0);
    
    // 释放context和颜色空间
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // 用Quartz image创建一个UIImage对象image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];
    
    // 释放Quartz image对象
    CGImageRelease(quartzImage);
    
    return (image);
}



#define clamp(a) (a>255?255:(a<0?0:a))

#pragma mark 将 YUV Samplebuffer 转化为 UIImage
+ (UIImage *)imageFromYUVSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    @autoreleasepool {
        
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        uint8_t *yBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        size_t yPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 0);
        uint8_t *cbCrBuffer = CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
        size_t cbCrPitch = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, 1);
        
        int bytesPerPixel = 4;
        uint8_t *rgbBuffer = malloc(width * height * bytesPerPixel);
        
        for(int y = 0; y < height; y++) {
            uint8_t *rgbBufferLine = &rgbBuffer[y * width * bytesPerPixel];
            uint8_t *yBufferLine = &yBuffer[y * yPitch];
            uint8_t *cbCrBufferLine = &cbCrBuffer[(y >> 1) * cbCrPitch];
            
            for(int x = 0; x < width; x++) {
                int16_t y = yBufferLine[x];
                int16_t cb = cbCrBufferLine[x & ~1] - 128;
                int16_t cr = cbCrBufferLine[x | 1] - 128;
                
                uint8_t *rgbOutput = &rgbBufferLine[x*bytesPerPixel];
                
                int16_t r = (int16_t)roundf( y + cr *  1.4 );
                int16_t g = (int16_t)roundf( y + cb * -0.343 + cr * -0.711 );
                int16_t b = (int16_t)roundf( y + cb *  1.765);
                
                rgbOutput[0] = 0xff;
                rgbOutput[1] = clamp(b);
                rgbOutput[2] = clamp(g);
                rgbOutput[3] = clamp(r);
            }
        }
        
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef context = CGBitmapContextCreate(rgbBuffer, width, height, 8, width * bytesPerPixel, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
        CGImageRef quartzImage = CGBitmapContextCreateImage(context);
        // 一般
        //    UIImage *image = [UIImage imageWithCGImage:quartzImage];
        // 向右转90度
//        UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationRight];
        // 取消镜像,左转90度
        UIImage *image = [UIImage imageWithCGImage:quartzImage scale:1.0 orientation:UIImageOrientationLeftMirrored];
        
        CGContextRelease(context);
        CGColorSpaceRelease(colorSpace);
        CGImageRelease(quartzImage);
        free(rgbBuffer);
        
        CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
        
        return image;
    }
}

#pragma mark 获得脸型图片
+ (UIImage*)circularScaleAndCropImage:(UIImage*)image size:(CGSize)size {
    @autoreleasepool {
        
        //Create the bitmap graphics context
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), NO, 0.0);
        CGContextRef context = UIGraphicsGetCurrentContext();
        
        //Get the width and heights
        CGFloat imageWidth = image.size.width;
        CGFloat imageHeight = image.size.height;
        CGFloat rectWidth = size.width;
        CGFloat rectHeight = size.height;
        
        
        CGContextBeginPath (context);
        
        /*
        // 画人脸形状 （方案一）
        CGFloat center_1_X = imageWidth/ 2;
        CGFloat radius = center_1_X * 0.8;
        CGFloat center_1_Y = imageHeight/ 2 - radius/3;
        
        CGPoint center_1 = CGPointMake(center_1_X, center_1_Y);
        
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center_1 radius:radius startAngle:M_PI/18 endAngle:M_PI - M_PI/18 clockwise:NO];
        
        CGPoint center_2 = CGPointMake(center_1.x, center_1.y + radius/1.5);
        [path addArcWithCenter:center_2 radius:radius * 0.93 startAngle:M_PI - M_PI/18 endAngle:M_PI/18 clockwise:NO];
         */
        
        
        // 画人脸形状 （方案二）
        CGFloat center_1_X = imageWidth/ 2;
        CGFloat radius = center_1_X * 0.1;
        CGFloat center_1_Y = imageHeight/ 2 - radius*3.4;
        
        CGPoint center_1 = CGPointMake(center_1_X, center_1_Y);
        
        radius = radius/0.1;
        CGFloat angle = M_PI/17;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center_1 radius:radius startAngle:angle endAngle:M_PI - angle clockwise:NO];
        
        CGFloat offsetX = 1/10.0;   // 收缩颧骨宽度
        CGFloat offsetY = (1.7) * radius; // 调颧骨长
        [path addLineToPoint:CGPointMake(offsetX*radius, offsetY)];
        
        CGFloat controlPoint_Y = 8.5/3.0*radius; // 调节脸长
        CGFloat scaleOffsetX = 2.5; // 调下巴宽度
        [path addCurveToPoint:CGPointMake((2-offsetX)*radius, offsetY) controlPoint1:CGPointMake(scaleOffsetX*offsetX*radius, controlPoint_Y) controlPoint2:CGPointMake((2-scaleOffsetX*offsetX)*radius, controlPoint_Y)];
        
        [path addLineToPoint:CGPointMake((2-offsetX)*radius, offsetY)];
         
        
        /*
         // 画人脸形状 （方案三）
        CGFloat scale = kScale; // 调节取景框大小
        CGFloat center_X = imageWidth / 2;
        CGFloat radius = center_X * scale;
        CGFloat center_Y = imageHeight / 2;
        
        CGPoint center_1 = CGPointMake(center_X, center_Y);
        
        CGFloat angle = M_PI/17;
        UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center_1 radius:radius startAngle:angle endAngle:M_PI - angle clockwise:NO];
        
        CGFloat offsetXScale = 1/10.0;   // 收缩颧骨宽度
        
        CGFloat toPoint_Y = center_Y + 71/105.0 * radius;
        CGFloat angle2 = M_PI/15;
        
        [path addArcWithCenter:CGPointMake(center_X, toPoint_Y) radius:(1 - offsetXScale) * radius startAngle:M_PI - angle2 endAngle:angle2 clockwise:NO];
        */
         
        CGContextAddPath(context, path.CGPath);
        CGContextClosePath (context);
        CGContextClip (context);
        CGContextScaleCTM(context, 1.0, 1.0);
        // Draw the IMAGE
        CGRect myRect = CGRectMake(0, 0, rectWidth, rectHeight);
        [image drawInRect:myRect];
        
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        
        
        UIGraphicsEndImageContext();
        //    CGContextRelease(context);
        
        return newImage;
    }
}



#pragma mark 旋转图片 按方向
+ (UIImage *)rotateImage:(UIImage *)image rotation:(UIImageRotateOrientation)orientation{
    
    long double rotate = 0.0;
    CGRect rect;
    float translateX = 0;
    float translateY = 0;
    float scaleX = 1.0;
    float scaleY = 1.0;
    
    switch (orientation) {
        case UIImageRotateOrientationLeft:
            rotate = M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = 0;
            translateY = -rect.size.width;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageRotateOrientationRight:
            rotate = 3 * M_PI_2;
            rect = CGRectMake(0, 0, image.size.height, image.size.width);
            translateX = -rect.size.height;
            translateY = 0;
            scaleY = rect.size.width/rect.size.height;
            scaleX = rect.size.height/rect.size.width;
            break;
        case UIImageRotateOrientationDown:
            rotate = M_PI;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = -rect.size.width;
            translateY = -rect.size.height;
            break;
        default:
            rotate = 0.0;
            rect = CGRectMake(0, 0, image.size.width, image.size.height);
            translateX = 0;
            translateY = 0;
            break;
    }
    
    UIGraphicsBeginImageContext(rect.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    //做CTM变换
    CGContextTranslateCTM(context, 0.0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextRotateCTM(context, rotate);
    CGContextTranslateCTM(context, translateX, translateY);
    
    CGContextScaleCTM(context, scaleX, scaleY);
    //绘制图片
    CGContextDrawImage(context, CGRectMake(0, 0, rect.size.width, rect.size.height), image.CGImage);
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
//    CGContextRelease(context);
    
    return newPic;
}
#pragma mark 旋转图片 按角度 不会出现被切掉,但是会等比缩小一倍
+ (UIImage *)rotateImage:(UIImage *)image angel:(CGFloat)angle{
    
//    NSLog(@"%f",angle);
    
    angle = -angle / 180 * M_PI;
    
    
    
    CGRect rect = CGRectMake(image.size.height, image.size.height,image.size.height * 2,image.size.height * 2);
    
    
    UIGraphicsBeginImageContext(rect.size);
    
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    // 因为默认是反转的 所以 旋转到正的位置
    // 设置 坐标系的原点的位置
    CGContextTranslateCTM(context, rect.size.width / 2, rect.size.height / 2);
    // 设置 放大缩小的 比例
    CGContextScaleCTM(context, 1.0, -1.0);
    
    // 旋转角度
    CGContextRotateCTM(context, angle);
    
    // 设置绘制的内容的参数,位置 尺寸
    // 实现围绕下底的中心点旋转
    CGContextDrawImage(context, CGRectMake(-image.size.width / 2, 0, image.size.width, image.size.height), image.CGImage);
    
//    CGContextSaveGState(context);
    
    
    UIImage *newPic = UIGraphicsGetImageFromCurrentImageContext();
    
    
    UIGraphicsEndImageContext();
//    CGContextRelease(context);
    
    return newPic;
}


#pragma mark 加半透明水印
+ (UIImage *)addMaskImage:(UIImage *)maskImage toImage:(UIImage *)useImage msakRect:(CGRect)rect{
    @autoreleasepool {
        
        UIGraphicsBeginImageContext(useImage.size);
        
        [useImage drawInRect:CGRectMake(0, 0, useImage.size.width, useImage.size.height)];
        
        //四个参数为水印图片的位置
        [maskImage drawInRect:rect];
        
        UIImage *resultingImage = UIGraphicsGetImageFromCurrentImageContext();
        
        UIGraphicsEndImageContext();
        
        return resultingImage;
    }
}

#pragma mark 将图片数组合成视频
+ (void)combineImagesArr:(NSArray *)imagesArr toMoviePath:(NSString *)moviePath withSize:(CGSize)size FPS:(int32_t)fps completion:(completion)result{
    
//    NSLog(@"开始");
    
    
    NSError *error =nil;
    
    unlink([moviePath UTF8String]);
//    NSLog(@"path->%@",moviePath);
    //—-initialize compression engine
    AVAssetWriter *videoWriter =[[AVAssetWriter alloc]initWithURL:[NSURL fileURLWithPath:moviePath]
                                                         fileType:AVFileTypeQuickTimeMovie
                                                            error:&error];
    NSParameterAssert(videoWriter);
    if(error)
        NSLog(@"error =%@", [error localizedDescription]);
    
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:AVVideoCodecH264,AVVideoCodecKey,
                                  [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                  [NSNumber numberWithInt:size.height],AVVideoHeightKey,nil];
    AVAssetWriterInput *writerInput =[AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoSettings];
    
    NSDictionary*sourcePixelBufferAttributesDictionary =[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:kCVPixelFormatType_32ARGB],kCVPixelBufferPixelFormatTypeKey,nil];
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:writerInput sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(writerInput);
    NSParameterAssert([videoWriter canAddInput:writerInput]);
    
    
    
    [videoWriter addInput:writerInput];
    
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //合成多张图片为一个视频文件
    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue",NULL);
    int __block frame =0;
    
    [writerInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{
        while([writerInput isReadyForMoreMediaData])
        {
            if(++frame >=[imagesArr count])
            {
                [writerInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{
                    
                    NSLog(@"结束了");
                    
                    result(@"结束了");
                }];
                
                break;
            }
            
            CVPixelBufferRef buffer =NULL;
            
            
//            NSLog(@"frame==%d",frame);
            
            UIImage *img = imagesArr[frame];
            buffer = [[self class] pixelBufferFromCGImage:img.CGImage size:size];
            
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame,fps)]){
//                    NSLog(@"FAIL");
                }
                else
//                    NSLog(@"OK");
                
                CFRelease(buffer);
            }
        }
    }];
}

#pragma mark 将图片数组合成视频 第二种方法
+ (void)combineImages:(NSArray *)imagesArray ToMovieAtPath:(NSString *) path withSize:(CGSize)size inDuration:(float)duration byFPS:(int32_t)fps completion:(completion)result{
    //Wire the writer:
    NSError *error =nil;
    AVAssetWriter *videoWriter =[[AVAssetWriter alloc]initWithURL:[NSURL fileURLWithPath:path] fileType:AVFileTypeQuickTimeMovie error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings =[NSDictionary dictionaryWithObjectsAndKeys:
                                  AVVideoCodecH264,AVVideoCodecKey,
                                  [NSNumber numberWithInt:size.width],AVVideoWidthKey,
                                  [NSNumber numberWithInt:size.height],AVVideoHeightKey,nil];
    
    AVAssetWriterInput* videoWriterInput =[AVAssetWriterInput
                                           assetWriterInputWithMediaType:AVMediaTypeVideo
                                           outputSettings:videoSettings];
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor =[AVAssetWriterInputPixelBufferAdaptor
                                                    assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                    sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //Write some samples:
    CVPixelBufferRef buffer =NULL;
    
    int frameCount =0;
    
    
    for(UIImage *img in imagesArray)
    {
        buffer = [[self class] pixelBufferFromCGImage:[img CGImage] size:size];
        
        double numberOfSecondsPerFrame  = duration / imagesArray.count;
        double frameDuration            = fps * numberOfSecondsPerFrame;
        
        BOOL append_ok = NO;
        int j = 0;
        
        while (!append_ok && j < 2) // !append_ok&& j < 30
        {
            if(adaptor.assetWriterInput.readyForMoreMediaData)
            {
                printf("appending %d attemp%d\n", frameCount, j);
                
                CMTime frameTime = CMTimeMake(frameCount * frameDuration,(int32_t) fps);
                
                NSLog(@"Frame Time  : %f", CMTimeGetSeconds(frameTime));
                
                float frameSeconds =CMTimeGetSeconds(frameTime);
                
                NSLog(@"frameCount:%d,kRecordingFPS:%d,frameSeconds:%f",frameCount,fps,frameSeconds);
                
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                
                if(buffer)
                    [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                printf("adaptor not ready %d,%d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok){
            printf("error appendingimage %d times %d\n", frameCount, j);
        }
        
        frameCount++;
    }
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        
        NSLog(@"结束了");
        
        result(@"结束了");
    }];
    
}

#pragma mark 将 Image 转化为 pixelBuffer
+ (CVPixelBufferRef)pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size{
    NSDictionary *options =[NSDictionary dictionaryWithObjectsAndKeys:
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGImageCompatibilityKey,
                            [NSNumber numberWithBool:YES],kCVPixelBufferCGBitmapContextCompatibilityKey,nil];
    CVPixelBufferRef pxbuffer =NULL;
    CVReturn status =CVPixelBufferCreate(kCFAllocatorDefault,size.width,size.height,kCVPixelFormatType_32ARGB,(__bridge CFDictionaryRef) options,&pxbuffer);
    
    NSParameterAssert(status ==kCVReturnSuccess && pxbuffer !=NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer,0);
    void *pxdata =CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata !=NULL);
    
    CGColorSpaceRef rgbColorSpace=CGColorSpaceCreateDeviceRGB();
    CGContextRef context =CGBitmapContextCreate(pxdata,size.width,size.height,8,CVPixelBufferGetBytesPerRow(pxbuffer),rgbColorSpace,kCGImageAlphaPremultipliedFirst);
    
    NSParameterAssert(context);
    
    CGContextDrawImage(context,CGRectMake(0,0,CGImageGetWidth(image),CGImageGetHeight(image)), image);
    
    CGColorSpaceRelease(rgbColorSpace);
    
    CGContextRelease(context);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer,0);
    
    return pxbuffer;
}

@end
