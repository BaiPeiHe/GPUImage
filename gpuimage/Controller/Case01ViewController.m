//
//  Case01ViewController.m
//  gpuimage
//
//  Created by 白鹤 on 16/12/2.
//  Copyright © 2016年 白鹤. All rights reserved.
//

#import "Case01ViewController.h"

#import "GPUImage.h"
#import "GPUImageBeautifyFilter.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import "ImageEngine.h"


@interface Case01ViewController ()

@property (nonatomic, strong) GPUImageVideoCamera *videoCamera;
@property (nonatomic, strong) GPUImageView *filterView;
@property (nonatomic, strong) UIButton *beautifyButton;

@property (nonatomic, strong) UIImage *beautieImage;

@property (nonatomic, assign) BOOL isRecording;

@property (nonatomic, assign) NSInteger imageIndex;
@property (nonatomic, assign) NSInteger combineIndex;
@property (nonatomic, assign) CGFloat rorate;

@end

@implementation Case01ViewController
{
    GPUImageMovie *movieFile;
    GPUImageOutput<GPUImageInput> *filter;
    GPUImageMovieWriter *gpumovieWriter;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.isRecording  = NO;
    self.imageIndex = 0;
    self.combineIndex = 0;
    self.rorate = 0;
    
    [self createUpView];
    
    [self createDownView];
    
    [self createButton];
    
}

- (void)createUpView{
    
    
    self.videoCamera = [[GPUImageVideoCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionFront];
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    self.filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height / 2, self.view.frame.size.width, self.view.frame.size.height / 2)];
    
    [self.view addSubview:self.filterView];
    
    GPUImageBeautifyFilter *beautifyFilter = [[GPUImageBeautifyFilter alloc] init];
    [self.videoCamera addTarget:beautifyFilter];
    [beautifyFilter addTarget:self.filterView];
    
    
    [beautifyFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        
        if(self.isRecording){
            
            @autoreleasepool {
                
                CGImageRef imageRef = [output newCGImageFromCurrentlyProcessedOutput];
                
                UIImage *image = [UIImage imageWithCGImage:imageRef];
                CGImageRelease(imageRef);
                self.beautieImage = image;
                
                NSLog(@"imageIndex = %ld",self.imageIndex++);
            }
        }
        
        [output useNextFrameForImageCapture];
    }];
    
    [self.videoCamera startCameraCapture];
    
}


- (void)createDownView{
    
    
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/ 2)];
    [self.view addSubview:filterView];
    
    // 滤镜
    filter = [[GPUImageAlphaBlendFilter alloc] init];
    [(GPUImageAlphaBlendFilter *)filter setMix:1];
    
    // 播放
    NSURL *sampleURL = [[NSBundle mainBundle] URLForResource:@"WeChatSight1" withExtension:@"mp4"];
    AVAsset *asset = [AVAsset assetWithURL:sampleURL];
    CGSize size = CGSizeMake(500, 500);
    movieFile = [[GPUImageMovie alloc] initWithAsset:asset];
    movieFile.runBenchmark = NO;
    movieFile.playAtActualSpeed = YES;
    
    // 水印
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"watermark.png"]];
    
    UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    subView.backgroundColor = [UIColor clearColor];
    imageView.center = CGPointMake(subView.bounds.size.width / 2, subView.bounds.size.height / 2);
    [subView addSubview:imageView];
    
    
    GPUImageUIElement *uielement = [[GPUImageUIElement alloc] initWithView:subView];
    
    //    GPUImageTransformFilter 动画的filter
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.m4v"];
    unlink([pathToMovie UTF8String]);
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    
    gpumovieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:CGSizeMake(500, 500)];
    
    GPUImageFilter* progressFilter = [[GPUImageFilter alloc] init];
    [movieFile addTarget:progressFilter];
    [progressFilter addTarget:filter];
    [uielement addTarget:filter];
    gpumovieWriter.shouldPassthroughAudio = YES;
    movieFile.audioEncodingTarget = gpumovieWriter;
    [movieFile enableSynchronizedEncodingUsingMovieWriter:gpumovieWriter];
    // 显示到界面
    [filter addTarget:filterView];
    [filter addTarget:gpumovieWriter];
    
    __weak typeof(self) weakSelf = self;
    
    [progressFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
        
        imageView.image = weakSelf.beautieImage;
        
        imageView.layer.anchorPoint = CGPointMake(0.5, 1.0);
        
        imageView.bounds = CGRectMake(0, 0, 144, 192);
        
        [weakSelf drawFaceShapeInLayer:imageView.layer];
        
        [uielement updateWithTimestamp:time];
        
        NSLog(@"combineIndex = %ld",self.combineIndex++);
        
        if(self.combineIndex % 100 == 0){
            [gpumovieWriter setPaused:YES];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.002 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                
                [gpumovieWriter setPaused:NO];
                
            });
        }
    }];
    
    
    
    [gpumovieWriter setCompletionBlock:^{
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf->filter removeTarget:strongSelf->gpumovieWriter];
        [strongSelf->gpumovieWriter finishRecording];
        
        strongSelf.isRecording = NO;
        
        [[GPUImageContext sharedImageProcessingContext].framebufferCache purgeAllUnassignedFramebuffers];
        
        NSLog(@"结束时间 = %f",[[NSDate date] timeIntervalSince1970]);
        
        
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(pathToMovie))
        {
            [library writeVideoAtPathToSavedPhotosAlbum:movieURL completionBlock:^(NSURL *assetURL, NSError *error)
             {
                 dispatch_async(dispatch_get_main_queue(), ^{
                     
                     if (error) {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存失败" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     } else {
                         UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"视频保存成功" message:nil
                                                                        delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                         [alert show];
                     }
                 });
             }];
        }
        else {
            NSLog(@"error mssg)");
        }
    }];
}



- (void)updateProgress
{
    
}

- (void)beautify:(UIButton *)sender {
    
    NSLog(@"点击");
    
    
    [gpumovieWriter startRecording];
    [movieFile startProcessing];
    
    self.isRecording = YES;
    NSLog(@"开始时间 = %f",[[NSDate date] timeIntervalSince1970]);
    
}


- (NSString *)filePathOfMergedVideoOutputPath {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory = [paths lastObject];
    // 时间戳命名文件
    NSDate *date = [NSDate date];
    NSString *timeSp = [NSString stringWithFormat:@"%.0f",[date timeIntervalSince1970]];
    
    NSString *myPathDocs =  [documentDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"Merged%@%@.mp4",timeSp,@"234"]];
    
    
    return myPathDocs;
}


- (void)createButton{
    
    self.beautifyButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.beautifyButton.backgroundColor = [UIColor whiteColor];
    [self.beautifyButton setTitle:@"开启" forState:UIControlStateNormal];
    [self.beautifyButton setTitle:@"关闭" forState:UIControlStateSelected];
    [self.beautifyButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
    [self.beautifyButton addTarget:self action:@selector(beautify:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.beautifyButton];
    
    self.beautifyButton.frame = CGRectMake(0, 0, 100, 40);
    self.beautifyButton.center = CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height - 40);
}


- (void)drawFaceShapeInLayer:(CALayer *)layer{
    
    /*
     // 画人脸形状 （方案三）
     CGFloat scale = kScale; // 调节取景框大小
     CGFloat center_X = layer.bounds.size.width / 2;
     CGFloat radius = center_X * scale;
     CGFloat center_Y = layer.bounds.size.height / 2;
     
     CGPoint center_1 = CGPointMake(center_X, center_Y);
     
     CGFloat angle = M_PI/17;
     UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center_1 radius:radius startAngle:angle endAngle:M_PI - angle clockwise:NO];
     
     CGFloat offsetXScale = 1/10.0;   // 收缩颧骨宽度
     
     CGFloat toPoint_Y = center_Y + 71/105.0 * radius;
     CGFloat angle2 = M_PI/15;
     
     [path addArcWithCenter:CGPointMake(center_X, toPoint_Y) radius:(1 - offsetXScale) * radius startAngle:M_PI - angle2 endAngle:angle2 clockwise:NO];
     
     CAShapeLayer *faceLayer = [CAShapeLayer layer];
     
     faceLayer.path = path.CGPath;
     
     layer.mask = faceLayer;
     */
    
    /*
     // 画人脸形状
     CGFloat center_1_X = layer.bounds.size.width / 2;
     CGFloat radius = center_1_X;
     CGFloat center_1_Y = layer.bounds.size.height / 2 - radius/3;
     
     CGPoint center_1 = CGPointMake(center_1_X, center_1_Y);
     
     CGFloat angle = M_PI/18;
     UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center_1 radius:radius startAngle:angle endAngle:M_PI - angle clockwise:NO];
     
     CGPoint center_2 = CGPointMake(center_1.x, center_1.y + radius/1.5);
     [path addArcWithCenter:center_2 radius:radius * 0.93 startAngle:M_PI - angle endAngle:angle clockwise:NO];
     
     CAShapeLayer *faceLayer = [CAShapeLayer layer];
     
     faceLayer.path = path.CGPath;
     
     layer.mask = faceLayer;
     */
    
    
    // 画人脸形状 (方案二)
    CGFloat center_1_X = layer.bounds.size.width / 2;
    CGFloat radius = center_1_X;
    CGFloat center_1_Y = layer.bounds.size.height / 2 - radius/3;
    
    CGPoint center_1 = CGPointMake(center_1_X, center_1_Y);
    
    CGFloat angle = M_PI/17;
    UIBezierPath *path = [UIBezierPath bezierPathWithArcCenter:center_1 radius:radius startAngle:angle endAngle:M_PI - angle clockwise:NO];
    
    CGFloat offsetX = 1/10.0;   // 收缩颧骨宽度
    CGFloat offsetY = 1.79 * radius; // 调颧骨长
    [path addLineToPoint:CGPointMake(offsetX*radius, offsetY)];
    
    CGFloat controlPoint_Y = 8.55/3.0*radius; // 调节脸长
    CGFloat scaleOffsetX = 2.5; // 调下巴宽度
    [path addCurveToPoint:CGPointMake((2-offsetX)*radius, offsetY) controlPoint1:CGPointMake(scaleOffsetX*offsetX*radius, controlPoint_Y) controlPoint2:CGPointMake((2-scaleOffsetX*offsetX)*radius, controlPoint_Y)];
    
    [path addLineToPoint:CGPointMake((2 - offsetX)*radius, offsetY)];
    
    CAShapeLayer *faceLayer = [CAShapeLayer layer];
    
    faceLayer.path = path.CGPath;
    
    layer.mask = faceLayer;
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
