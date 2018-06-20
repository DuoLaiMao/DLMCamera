//
//  DLMCameraViewController.m
//  DLMCamera
//
//  Created by YangJian on 2018/6/20.
//  Copyright © 2018年 DLM. All rights reserved.
//

#import "DLMCameraViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <Masonry/Masonry.h>

@interface DLMCameraViewController ()

//设备，包括前后摄像头，麦克等
@property (strong, nonatomic) AVCaptureDevice *device;
//输入设备
@property (strong, nonatomic) AVCaptureInput *input;
//开启摄像头后的输出
@property (strong, nonatomic) AVCaptureOutput *output;
//session：由他把输入输出结合在一起，并开始启动捕获设备（摄像头）
@property (strong, nonatomic) AVCaptureSession *session;
//图像预览层，实时显示捕获的图像
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
//照片输出流
@property (strong, nonatomic) AVCaptureStillImageOutput *imageOutput;

//界面布局，图片预览
@property (strong, nonatomic) UIImageView *previewView;
//底部操作区
@property (strong, nonatomic) UIView *bottomView;
//拍照按钮
@property (strong, nonatomic) UIButton *captureButton;
//重拍按钮
@property (strong, nonatomic) UIButton *recaptureButton;
//确认按钮，拍下一张
@property (strong, nonatomic) UIButton *newcaptureButton;

@end

@implementation DLMCameraViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self.view addSubview:self.previewView];
    [self.view addSubview:self.bottomView];
    
    if (@available(iOS 11.0, *)) {
        [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view.mas_safeAreaLayoutGuideTop);
            make.left.right.offset(0);
            make.bottom.equalTo(self.bottomView.mas_top);
        }];
        [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.bottom.equalTo(self.view.mas_safeAreaLayoutGuideBottom);
            make.height.mas_equalTo(130);
        }];
    }
    else {
        [self.previewView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.view);
            make.left.right.offset(0);
            make.bottom.equalTo(self.bottomView.mas_top);
        }];
        [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.offset(0);
            make.bottom.equalTo(self.view);
            make.height.mas_equalTo(130);
        }];
    }
    
    if ([self checkCameraPermission]) {
        [self performSelector:@selector(configCamera) withObject:nil afterDelay:1.0];
    }
}

- (BOOL)prefersStatusBarHidden
{
    return true;
}

//检查相机权限
- (BOOL)checkCameraPermission
{
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (AVAuthorizationStatusDenied == authStatus) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"请打开相机权限" message:@"设置-隐私-相机" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:@"设置" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL * url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
            if([[UIApplication sharedApplication] canOpenURL:url]) {
                [[UIApplication sharedApplication] openURL:url];
            }
        }]];
        [self presentViewController:alert animated:true completion:nil];
        
        return false;
    }
    
    return true;
}

//相机配置
- (void)configCamera
{
    //使用AVMediaTypeVideo 指明self.device代表视频，
    self.device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    //使用设备初始化输入
    self.input = [[AVCaptureDeviceInput alloc]initWithDevice:self.device error:nil];
    //生成输出对象
    self.output = [[AVCaptureMetadataOutput alloc]init];
    self.imageOutput = [[AVCaptureStillImageOutput alloc]init];
    //生成会话，用来结合输入输出
    self.session = [[AVCaptureSession alloc]init];
    [self.session setSessionPreset:AVCaptureSessionPreset1920x1080];
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
        
    }
    if ([self.session canAddOutput:self.imageOutput]) {
        [self.session addOutput:self.imageOutput];
    }
    
    //使用self.session，初始化预览层，self.session负责驱动input进行信息的采集，layer负责把图像渲染显示
    self.previewLayer = [[AVCaptureVideoPreviewLayer alloc]initWithSession:self.session];
    self.previewLayer.frame = self.previewView.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.previewView.layer addSublayer:self.previewLayer];
    
    //开始启动
    [self.session startRunning];
    
    //修改设备的属性，先加锁
    if ([self.device lockForConfiguration:nil]) {
        //关闭闪光灯
        if ([self.device isFlashModeSupported:AVCaptureFlashModeOff]) {
            [self.device setFlashMode:AVCaptureFlashModeAuto];
        }
        
        //自动白平衡
        if ([self.device isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeAutoWhiteBalance]) {
            [self.device setWhiteBalanceMode:AVCaptureWhiteBalanceModeAutoWhiteBalance];
        }
        
        //解锁
        [self.device unlockForConfiguration];
    }
}
#pragma mark - private 拍照预览照片
- (void)captureFinishWithImage:(UIImage *)image
{
    CGSize size0 = image.size;
    CGSize size1 = self.previewView.bounds.size;
    CGFloat height = (size1.height * size0.width) / size1.width;
    size1.height = height;
    size1.width = size0.width;
    
    //因为拍照后的imageOrientation与实际不一致，所以宽高对调
    CGRect rect = CGRectMake((size0.height - size1.height) / 2, 0, size1.height, size1.width);
    CGImageRef cgRef0 = image.CGImage;
    
    CGImageRef cgRef1 = CGImageCreateWithImageInRect(cgRef0, rect);
    UIImage *scaleImage = [UIImage imageWithCGImage:cgRef1 scale:1.0 orientation:image.imageOrientation];
    CGImageRelease(cgRef1);
    
    self.previewLayer.hidden = true;
    self.previewView.image = scaleImage;
}

#pragma mark - action
- (void)captureButtonAction
{
    self.captureButton.hidden = true;
    self.recaptureButton.hidden = false;
    self.newcaptureButton.hidden = false;
    
    AVCaptureConnection * videoConnection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (videoConnection ==  nil) {
        return;
    }
    if (videoConnection.isVideoOrientationSupported) {
        videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:videoConnection completionHandler:^(CMSampleBufferRef  _Nullable imageDataSampleBuffer, NSError * _Nullable error) {
        if (imageDataSampleBuffer == nil) {
            return ;
        }
        __strong typeof(weakSelf) self = weakSelf;
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        [self captureFinishWithImage:[UIImage imageWithData:imageData]];
    }];
}

- (void)recaptureButtonAction
{
    self.captureButton.hidden = false;
    self.recaptureButton.hidden = true;
    self.newcaptureButton.hidden = true;
    
    self.previewLayer.hidden = false;
}

- (void)newcaptureButtonAction
{
    self.captureButton.hidden = false;
    self.recaptureButton.hidden = true;
    self.newcaptureButton.hidden = true;
    
    self.previewLayer.hidden = false;
    //TODO:这里可以做图片处理，例如保存到相册，上传至服务器等
}

#pragma mark - setter && getter
- (UIImageView *)previewView
{
    if (!_previewView) {
        _previewView = [[UIImageView alloc] init];
        _previewView.backgroundColor = [UIColor blackColor];
    }
    
    return _previewView;
}
- (UIView *)bottomView
{
    if (!_bottomView) {
        _bottomView = [[UIView alloc] init];
        _bottomView.backgroundColor = [UIColor blackColor];
        [_bottomView addSubview:self.captureButton];
        [_bottomView addSubview:self.recaptureButton];
        [_bottomView addSubview:self.newcaptureButton];
        [self.captureButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.offset(0);
        }];
        [self.recaptureButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.offset(0);
            make.centerX.offset(-50);
            make.size.mas_equalTo(CGSizeMake(56, 56));
        }];
        [self.newcaptureButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerY.offset(0);
            make.centerX.offset(50);
            make.size.mas_equalTo(CGSizeMake(56, 56));
        }];
    }
    return _bottomView;
}
- (UIButton *)captureButton
{
    if (!_captureButton) {
        _captureButton = [UIButton new];
        [_captureButton setImage:[UIImage imageNamed:@"capture"] forState:UIControlStateNormal];
        [_captureButton addTarget:self action:@selector(captureButtonAction)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _captureButton;
}

- (UIButton *)recaptureButton
{
    if (!_recaptureButton) {
        _recaptureButton = [UIButton new];
        _recaptureButton.hidden = true;
        _recaptureButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.48];
        _recaptureButton.layer.masksToBounds = true;
        _recaptureButton.layer.cornerRadius = 28;
        [_recaptureButton setTitle:@"重拍" forState:UIControlStateNormal];
        [_recaptureButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_recaptureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_recaptureButton addTarget:self action:@selector(recaptureButtonAction)
                 forControlEvents:UIControlEventTouchUpInside];
    }
    return _recaptureButton;
}

- (UIButton *)newcaptureButton
{
    if (!_newcaptureButton) {
        _newcaptureButton = [UIButton new];
        _newcaptureButton.hidden = true;
        _newcaptureButton.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.48];
        _newcaptureButton.layer.masksToBounds = true;
        _newcaptureButton.layer.cornerRadius = 28;
        [_newcaptureButton setTitle:@"确认" forState:UIControlStateNormal];
        [_newcaptureButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
        [_newcaptureButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [_newcaptureButton addTarget:self action:@selector(newcaptureButtonAction)
                   forControlEvents:UIControlEventTouchUpInside];
    }
    return _newcaptureButton;
}
@end
