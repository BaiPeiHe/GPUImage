//
//  MovieEngine.m
//  Flippy
//
//  Created by 白鹤 on 16/10/17.
//  Copyright © 2016年 江山如画. All rights reserved.
//

#import "MovieEngine.h"

@implementation MovieEngine



#pragma mark 将一组图片插入到视频中

- (void) writeImages:(NSArray *)imagesArray ToMovieAtPath:(NSString *) path withSize:(CGSize) size
          inDuration:(float)duration byFPS:(int32_t)fps{
    //Wire the writer:
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:[NSURL fileURLWithPath:path]
                                                           fileType:AVFileTypeQuickTimeMovie
                                                              error:&error];
    NSParameterAssert(videoWriter);
    
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];
    
    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput
                                            assetWriterInputWithMediaType:AVMediaTypeVideo
                                            outputSettings:videoSettings];
    
    
    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:nil];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    [videoWriter addInput:videoWriterInput];
    
    //Start a session:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];
    
    //Write some samples:
    CVPixelBufferRef buffer = NULL;
    
    int frameCount = 0;
    
    NSInteger imagesCount = [imagesArray count];
    float averageTime = duration/imagesCount;
    int averageFrame = (int)(averageTime * fps);
    
    for(UIImage * img in imagesArray)
    {
        buffer = [self pixelBufferFromCGImage:[img CGImage] andSize:size];
        
        BOOL append_ok = NO;
        int j = 0;
        while (!append_ok && j < 30)
        {
            if (adaptor.assetWriterInput.readyForMoreMediaData)
            {
                printf("appending %d attemp %d\n", frameCount, j);
                
                CMTime frameTime = CMTimeMake(frameCount,(int32_t) fps);
                float frameSeconds = CMTimeGetSeconds(frameTime);
                NSLog(@"frameCount:%d,kRecordingFPS:%d,frameSeconds:%f",frameCount,fps,frameSeconds);
                append_ok = [adaptor appendPixelBuffer:buffer withPresentationTime:frameTime];
                
                if(buffer)
                    [NSThread sleepForTimeInterval:0.05];
            }
            else
            {
                printf("adaptor not ready %d, %d\n", frameCount, j);
                [NSThread sleepForTimeInterval:0.1];
            }
            j++;
        }
        if (!append_ok) {
            printf("error appending image %d times %d\n", frameCount, j);
        }
        
        frameCount = frameCount + averageFrame;
    }
    
    //Finish the session:
    [videoWriterInput markAsFinished];
    [videoWriter finishWritingWithCompletionHandler:^{
        
        
    }];
    NSLog(@"finishWriting");
}

#pragma mark CGImageRef 

- (CVPixelBufferRef) pixelBufferFromCGImage: (CGImageRef) image andSize:(CGSize) size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey,
                             nil];
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width,
                                          size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options,
                                          &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);
    
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width,
                                                 size.height, 8, 4*size.width, rgbColorSpace,
                                                 kCGImageAlphaNoneSkipFirst);
    NSParameterAssert(context);
    CGContextConcatCTM(context, CGAffineTransformMakeRotation(0));
    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image),
                                           CGImageGetHeight(image)), image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CGImageRelease(image);
    
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

#pragma mark 获得视频的每一帧

+ (void)getEveryBufferWithMovie:(NSString *)urlPath toFace:(BOOL)toFace FPS:(NSInteger)fps value:(NSInteger)value completion:(ImageArr)resultImage{
    
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    NSURL *url = [NSURL fileURLWithPath:urlPath];
    
    AVURLAsset *myAsset = [[AVURLAsset alloc] initWithURL:url options:opts];
//    
//    //    value为  总帧数，timescale为  fps
//    NSInteger value = myAsset.duration.value;
//    float timescale = myAsset.duration.timescale;
//    // 获取视频总时长,单位秒
//    float second = value / timescale;
//    
//    Float64 durationSeconds = CMTimeGetSeconds([myAsset duration]);
//    // 获取视频总时长,单位秒
//    NSLog(@"%f~!~!~!~",durationSeconds);
    
//    timescale = fps;
    
//    value = (NSInteger)timescale * durationSeconds;
    
    AVAssetImageGenerator *myImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:myAsset];
    
    myImageGenerator.appliesPreferredTrackTransform = YES;
    //解决 时间不准确问题
    myImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
    myImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    NSMutableArray *imagesArr = [NSMutableArray array];
    


    if(/* DISABLES CODE */ (NO)){
        
        // 创建一个并行多线程
        dispatch_queue_t queue = dispatch_queue_create("FilterQueue", DISPATCH_QUEUE_CONCURRENT);
        // 使用自定义线程
        dispatch_async(queue, ^{
            
            for(NSInteger i = 0; i < value ; i++){
                
                CGImageRef imageRef = [myImageGenerator copyCGImageAtTime:CMTimeMake(i, (int32_t)fps) actualTime:nil error:nil];
                
                UIImage *image = [UIImage imageWithCGImage: imageRef];
                
                // 旋转
                image = [ImageEngine rotateImage:image rotation:UIImageRotateOrientationRight];
                // 获得脸型
                image = [ImageEngine circularScaleAndCropImage:image size:image.size];
                
                [imagesArr addObject:image];
                
                CGImageRelease(imageRef);
            }
            
            resultImage(imagesArr);
            
        });
        
    }
    else{
        
        
        NSMutableArray *times = [NSMutableArray array];
        
        for(NSInteger i = 0; i < value ; i++){
            
            NSValue *v = [NSValue valueWithCMTime:CMTimeMake(i, (int32_t)fps)];
            
            [times addObject:v];
        }
        
        
        [myImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
            
            //        NSString *requestedTimeString = (NSString *)
            //        CFBridgingRelease(CMTimeCopyDescription(NULL, requestedTime));
            //        NSString *actualTimeString = (NSString *)
            //        CFBridgingRelease(CMTimeCopyDescription(NULL, actualTime));
            //
            //        NSLog(@"Requested: %@; actual %@", requestedTimeString, actualTimeString);
            
            if (result == AVAssetImageGeneratorSucceeded) {
                // Do something interesting with the image.
                //            NSLog(@"asdfasdgtryer4563464");
                
                UIImage *image1 = [UIImage imageWithCGImage: image];
                
                if(toFace){
                    // 旋转
                    image1 = [ImageEngine rotateImage:image1 rotation:UIImageRotateOrientationRight];
                    // 获得脸型
                    image1 = [ImageEngine circularScaleAndCropImage:image1 size:image1.size];
                    
                }
                
                [imagesArr addObject:image1];
                
                if(imagesArr.count == times.count){
                    
                    //                NSLog(@"%ld",imagesArr.count);
                    
                    
                    
                    resultImage(imagesArr);
                    
                    // 退出当前 ,不然会一直占用 CPU 资源
                    [myImageGenerator cancelAllCGImageGeneration];
                    
                }
            }
            
            else if (result == AVAssetImageGeneratorFailed) {
                NSLog(@"Failed with error: %@", [error localizedDescription]);
            }
            else if (result == AVAssetImageGeneratorCancelled) {
                NSLog(@"Canceled");
            }
            
            
        }];
    }
}

#pragma mark 获取视频的一帧
+ (void) imageForVideoPath:(NSString *)videoPath atTime:(NSInteger)time FPS:(int32_t)fps completion:(ImageArr)resultImage{
    
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    NSURL *url = [NSURL fileURLWithPath:videoPath];
    
    AVURLAsset *myAsset = [[AVURLAsset alloc] initWithURL:url options:opts];
    //
    //    //    value为  总帧数，timescale为  fps
    //    NSInteger value = myAsset.duration.value;
    //    float timescale = myAsset.duration.timescale;
    //    // 获取视频总时长,单位秒
    //    float second = value / timescale;
    //
    //    Float64 durationSeconds = CMTimeGetSeconds([myAsset duration]);
    //    // 获取视频总时长,单位秒
    //    NSLog(@"%f~!~!~!~",durationSeconds);
    
    //    timescale = fps;
    
    //    value = (NSInteger)timescale * durationSeconds;
    
    AVAssetImageGenerator *myImageGenerator = [[AVAssetImageGenerator alloc] initWithAsset:myAsset];
    
    myImageGenerator.appliesPreferredTrackTransform = YES;
    //解决 时间不准确问题
//    myImageGenerator.requestedTimeToleranceBefore = kCMTimeZero;
//    myImageGenerator.requestedTimeToleranceAfter = kCMTimeZero;
    
    
    NSMutableArray *times = [NSMutableArray array];
    
    NSValue *v = [NSValue valueWithCMTime:CMTimeMake(time, (int32_t)fps)];
    
    [times addObject:v];
    
    
    
    [myImageGenerator generateCGImagesAsynchronouslyForTimes:times completionHandler:^(CMTime requestedTime, CGImageRef  _Nullable image, CMTime actualTime, AVAssetImageGeneratorResult result, NSError * _Nullable error) {
        
//        NSString *requestedTimeString = (NSString *)
//        CFBridgingRelease(CMTimeCopyDescription(NULL, requestedTime));
//        NSString *actualTimeString = (NSString *)
//        CFBridgingRelease(CMTimeCopyDescription(NULL, actualTime));
//        NSLog(@"Requested: %@; actual %@", requestedTimeString, actualTimeString);
        
        if (result == AVAssetImageGeneratorSucceeded) {
            // Do something interesting with the image.
//            NSLog(@"asdfasdgtryer4563464");
            
            UIImage *image1 = [UIImage imageWithCGImage: image];
            
            // 退出当前 ,不然会一直占用 CPU 资源
            [myImageGenerator cancelAllCGImageGeneration];
            
            resultImage([NSArray arrayWithObjects:image1, nil]);
        }
        
        if (result == AVAssetImageGeneratorFailed) {
            NSLog(@"Failed with error: %@", [error localizedDescription]);
        }
        if (result == AVAssetImageGeneratorCancelled) {
            NSLog(@"Canceled");
        }
    }];
}

#pragma mark 将第一个视频的声音合成到第二个视频上

+ (void)combineMovieAudio:(NSString *)audioMoviePath toMovie:(NSString *)moviePath MovieFPS:(NSInteger)fps completion:(completion)result{
    
    
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
    
//    dispatch_async(dispatch_get_main_queue(), ^{
    
        // 提供音频的视频
        AVAsset *audioMovieAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:audioMoviePath]];
        // 接受音频的视频
        AVAsset *movieAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath: moviePath]];
        
        AVMutableComposition* mixComposition = [[AVMutableComposition alloc] init];
        
        // 第二个视频 的 视频轨道
        AVMutableCompositionTrack *movieTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
        [movieTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, movieAsset.duration) ofTrack:[[movieAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        
        // 第一个视频 的 音频轨道
        AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];
        
        [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, audioMovieAsset.duration) ofTrack:[[audioMovieAsset tracksWithMediaType:AVMediaTypeAudio] objectAtIndex:0] atTime:kCMTimeZero error:nil];
        
        // 设置视频尺寸
        CGSize naturalSize = CGSizeMake(movieTrack.naturalSize.width, movieTrack.naturalSize.height);
        
        
        AVMutableVideoCompositionInstruction * MainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        
        // 设置两条视频最长时长为合并之后视频的总时长
        if (CMTimeGetSeconds(movieAsset.duration) > CMTimeGetSeconds(audioMovieAsset.duration)) {
            MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, movieAsset.duration);
        }else {
            MainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, audioMovieAsset.duration);
        }
        
        // 将视频文件添加进去
        AVMutableVideoCompositionLayerInstruction *movielayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:movieTrack];
        
        MainInstruction.layerInstructions = [NSArray arrayWithObjects:movielayerInstruction,nil];;
        
        AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];
        
        mainCompositionInst.instructions = [NSArray arrayWithObject:MainInstruction];
        mainCompositionInst.frameDuration = CMTimeMake(1, (int32_t)fps);
        mainCompositionInst.renderSize = CGSizeMake(naturalSize.width + 1, naturalSize.height + 1);
        
        AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                          presetName:AVAssetExportPresetMediumQuality];
        
        NSString *outputFilePath = moviePath;
        
        unlink([outputFilePath UTF8String]);
        
        exporter.outputURL= [NSURL fileURLWithPath:outputFilePath];
        
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        exporter.videoComposition = mainCompositionInst;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            
            result(outputFilePath);
            
        }];
    });
}

#pragma mark 将音频数据 分为几段 保存当前段落里的最大值
+ (NSArray *)cutAudioData:(NSData *)data Count:(NSInteger)sampleCount {
    
    NSMutableArray *filteredSamplesMA = [NSMutableArray array];
    
    // 将数据分段的间隔
    NSUInteger binSize = data.length / sampleCount;
    
    SInt16 *bytes = (SInt16 *)data.bytes; //总的数据个数
    SInt16 maxSample = 0; //sint16两个字节的空间
    
    //以binSize为一个样本。每个样本中取一个最大数。也就是在固定范围取一个最大的数据保存，达到缩减目的
    for (NSUInteger i= 0; i < sampleCount; i += binSize) {
        //在sampleCount（所有数据）个数据中抽样，抽样方法为在binSize个数据为一个样本，在样本中选取一个数据
        SInt16 sampleBin[binSize];
        for (NSUInteger j = 0; j < binSize; j++) {//先将每次抽样样本的binSize个数据遍历出来
            
            sampleBin[j] = CFSwapInt16LittleToHost(bytes[i + j]);
            
        }
        //选取样本数据中最大的一个数据
        SInt16 value = [[self class] maxValueInArray:sampleBin ofSize:binSize];
        //保存数据
        [filteredSamplesMA addObject:@(value)];
        //将所有数据中的最大数据保存，作为一个参考。可以根据情况对所有数据进行“缩放”
        if (value > maxSample) {
            maxSample = value;
        }
    }
    
    return filteredSamplesMA;
}

//比较大小的方法，返回最大值
+ (SInt16)maxValueInArray:(SInt16[])values ofSize:(NSUInteger)size {
    SInt16 maxvalue = 0;
    for (int i = 0; i < size; i++) {
        
        if (abs(values[i] > maxvalue)) {
            
            maxvalue = abs(values[i]);
        }
    }
    return maxvalue;
}


#pragma mark 获取音频 所代表 的 数据
+ (NSData *)getRecorderDataFromURL:(NSURL *)url{
    NSMutableData *data = [[NSMutableData alloc]init]; //用于保存音频数据
    AVAsset *asset = [AVAsset assetWithURL:url];//获取文件
    
    NSError *error;
    AVAssetReader *reader = [[AVAssetReader alloc] initWithAsset:asset error:&error]; //创建读取
    if (!reader) {
        NSLog(@"%@",[error localizedDescription]);
    }
    
    AVAssetTrack *track = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];//从媒体中得到声音轨道
    //读取配置
    NSDictionary *dic = @{AVFormatIDKey :@(kAudioFormatLinearPCM),
                          AVLinearPCMIsBigEndianKey:@NO,    // 小端存储
                          AVLinearPCMIsFloatKey:@NO,    //采样信号是整数
                          AVLinearPCMBitDepthKey :@(16)  //采样位数默认 16
                          };
    //读取输出，在相应的轨道上输出对应格式的数据
    
    if (track == nil) {
        return nil;
    }
    
    AVAssetReaderTrackOutput *output = [[AVAssetReaderTrackOutput alloc]initWithTrack:track outputSettings:dic];
    
    //赋给读取并开启读取
    [reader addOutput:output];
    [reader startReading];
    
    //读取是一个持续的过程，每次只读取后面对应的大小的数据
    while (reader.status == AVAssetReaderStatusReading) {
        
        CMSampleBufferRef sampleBuffer = [output copyNextSampleBuffer]; //读取到数据
        if (sampleBuffer) {
            CMBlockBufferRef blockBUfferRef = CMSampleBufferGetDataBuffer(sampleBuffer);//取出数据
            size_t length = CMBlockBufferGetDataLength(blockBUfferRef); //返回一个大小，size_t针对不同的平台有不同的实现，扩展性更好
            SInt16 sampleBytes[length];
            CMBlockBufferCopyDataBytes(blockBUfferRef, 0, length, sampleBytes); //将数据放入数组
            [data appendBytes:sampleBytes length:length]; //将数据附加到data中
            CMSampleBufferInvalidate(sampleBuffer);//销毁
            CFRelease(sampleBuffer); //释放
        }
    }
    if (reader.status == AVAssetReaderStatusCompleted) {
        NSLog(@"获取成功");
        
        return data;
    }else{
        NSLog(@"获取音频数据失败");
        return nil;
    }
}

//将视频流存储到系统相册中。此步骤在视屏拍摄完成后掉用。调用位置为在AVCaptureFileOutputRecordingDelegate系统提供的代理方法中，实现保存功能
/*
+ (void)saveVideoToAssetsLibrary:(NSURL *)url {
    
    ALAssetsLibrary *libraty = [[ALAssetsLibrary alloc] init];
    
    if ([libraty videoAtPathIsCompatibleWithSavedPhotosAlbum:url]) {
        
        ALAssetsLibraryWriteImageCompletionBlock completionBlock;
        completionBlock = ^(NSURL *assetURL, NSError *error) {
            
            if (error) {
                
                NSLog(@"%@",[error localizedDescription]);
            }else {
                
                //根据视频流第一帧图片生成一张展示图
                [[self class] generateIamgeForViodeWithURL:url];
            }
        };
        
        [libraty writeVideoAtPathToSavedPhotosAlbum:url completionBlock:completionBlock];
        NSLog(@"保存方法");
    }
}
 */

//根据录制视频生成一张视频的展示图
+ (void)generateIamgeForViodeWithURL:(NSURL *)url {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        //容器，根据地址获取到视频流
        AVAsset *sesst = [AVAsset assetWithURL:url];
        AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:sesst];
        //图片大小
        generator.maximumSize = CGSizeMake(100, 0.0f);
        generator.appliesPreferredTrackTransform = YES;
        //转换
        CGImageRef imageRef = [generator copyCGImageAtTime:kCMTimeZero actualTime:NULL error:nil];
//        UIImage *image = [UIImage imageWithCGImage:imageRef];
        CGImageRelease(imageRef);
        dispatch_async(dispatch_get_main_queue(), ^{
            
            //保存图片到对应位置（私有方法）
//            [[self class] saveImageToAssetsLibraty:image];
            
            
            NSLog(@"缩略图生成");
        });
    });
}

/**
 *  将视频保存到相簿中
 *
 *  @param outputFileURL 视频的地址
 */
//+ (void)saveVideoToAlbumOutputFileStr:(NSString *)outputFileURL{
//    // 视频录入完成后在后台将视频存储到相簿
//    
//    
//    ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
//    [assetsLibrary writeVideoAtPathToSavedPhotosAlbum:outputFileURL completionBlock:^(NSURL *assetURL, NSError *error) {
//        
//        if(error){
//            NSLog(@"保存视频到相簿过程中发生错误,错误信息%@",error.localizedDescription);
//        }
//        
//        NSLog(@"成功保存视频到相簿.");
//    }];
//}


@end
