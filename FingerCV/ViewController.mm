//
//  ViewController.m
//  FingerCV
//
//  Created by Rahul Sundararaman on 10/15/15.
//  Copyright © 2015 Rahul Sundararaman. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/highgui/highgui.hpp>
#include <opencv2/video/background_segm.hpp>
#include <opencv2/imgcodecs.hpp>
#include <opencv2/videoio.hpp>
#include <opencv2/core/core.hpp>
#include <opencv2/video.hpp>
#include <iostream>
#include <sstream>
#include <stdio.h>
#include <stdlib.h>
@interface ViewController ()

@end

@implementation ViewController
cv::Mat canny_output;
cv::Mat src;
cv::Mat src_gray;
cv::RNG rng(12345);
float blue, green, red;
UIImage *tobesaved;
- (void)viewDidLoad {
    [super viewDidLoad];
    self.videoCamera = [[CvVideoCamera alloc] initWithParentView:_ImageView];
    self.videoCamera.delegate = self;
    self.videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionFront;
    self.videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPreset352x288;
    self.videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortraitUpsideDown;
    self.videoCamera.defaultFPS = 30;
    self.videoCamera.rotateVideo = YES;
    [self.videoCamera start];
    _contourimg.transform = CGAffineTransformMakeRotation(M_PI);
    _ImageView.transform = CGAffineTransformMakeRotation((M_PI*3)/2);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark – Actions
- (IBAction)flip:(id)sender {
    [self.videoCamera switchCameras];
}
- (IBAction)click:(id)sender {
    UIImageWriteToSavedPhotosAlbum(tobesaved, nil, nil, nil);
    
}
#pragma mark – Protocol CvVideoCameraDelegate

#ifdef __cplusplus
-(void)processImage:(cv::Mat &)image
{
    std::vector<std::vector<cv::Point> > contours;
    std::vector<cv::Vec4i> hierarchy;
    int thresh = 120-(floor(self.slider.value*100)+20);
    src = image;
    cvtColor( src, src_gray, CV_BGR2GRAY );
    blur( src_gray, src_gray, cvSize(3, 3));
    Canny( src_gray, canny_output, thresh, thresh*2, 3 );
    findContours( canny_output, contours, hierarchy, CV_RETR_CCOMP, CV_CHAIN_APPROX_SIMPLE);
    cv::Mat drawing = cv::Mat::zeros( canny_output.size(), CV_8UC3 );
    std::vector<std::vector<cv::Point> >hull( contours.size() );
    std::vector<cv::Vec4i>convexdef;
    //    for( int i = 0; i < contours.size(); i++ )
    //    {
    //         convexHull( cv::Mat(contours[i]), hull[i], false, true);
    //    }
    for( int i = 0; i< contours.size(); i++ )
    {
        cv::Scalar color = cvScalar( 255.0, 255.0, 255.0);
        drawContours( drawing, contours, i, color, CV_FILLED,  8, hierarchy);
    }
    
    UIImage *imag = [self UIImageFromCVMat:image];
    tobesaved = imag;
    dispatch_async(dispatch_get_main_queue(), ^{
        [_contourimg setImage:imag];
    });
    
    NSString *ohgodno = [self returnFingerCoordinates:imag];
    
    
    //    CvContourScanner thisscanner = cvStartFindContours(&image, connectedCompStorage);
    //    cv::findContours( image, contours, hierarchy, cv::RETR_CCOMP, cv::CHAIN_APPROX_TC89_KCOS);
    //    for ( size_t i=0; i<contours.size(); ++i )
    //    {
    //        cv::drawContours( image, contours, i, cvScalar(200,0,0), 1, 8, hierarchy, 0 );
    //        cv::Rect brect = cv::boundingRect(contours[i]);
    //        cv::rectangle(image, brect, cvScalar(255,0,0));
    //    }
    //    CGFloat red, green, blue, alpha;
    //    for(int x = 0; x<thisimage.size.width; x++){
    //        for(int y=0; y<thisimage.size.height; y++){
    //            NSArray *thisarray = [self getRGBAsFromImage:thisimage atX:x andY:y count:1];
    //            UIColor *redColor = thisarray[0];
    //            [redColor getRed: &red green: &green blue: &blue alpha: &alpha];
    //
    //        }
    //    }
}
#endif
#pragma mark – Helper Methods
-(NSArray *)returnColors:(int)xval y:(int)yval{
    NSMutableArray *colors;
    cv::Vec3f intensity = src.at<cv::Vec3f>(xval, yval);
    blue = intensity.val[0];
    green = intensity.val[1];
    red = intensity.val[2];
    [colors addObject:[NSNumber numberWithFloat:blue]];
    [colors addObject:[NSNumber numberWithFloat:green]];
    [colors addObject:[NSNumber numberWithFloat:red]];
    return colors;
}
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    if ( cvMat.elemSize() == 1 ) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    }
    else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    CGDataProviderRef provider = CGDataProviderCreateWithCFData( (__bridge CFDataRef)data );
    CGImageRef imageRef = CGImageCreate( cvMat.cols, cvMat.rows, 8, 8 * cvMat.elemSize(), cvMat.step[0], colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault, provider, NULL, false, kCGRenderingIntentDefault );
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease( imageRef );
    CGDataProviderRelease( provider );
    CGColorSpaceRelease( colorSpace );
    return finalImage;
}
- (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}
- (NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)xp andY:(int)yp count:(int)count
{
    NSMutableArray *resultColor = [NSMutableArray array];
    CGImageRef imageRef = [image CGImage];
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned char *rawData = (unsigned char*) calloc(height * width * 4, sizeof(unsigned char));
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
    // Now your rawData contains the image data in the RGBA8888 pixel format.
    int byteIndex = (bytesPerRow * yp) + xp * bytesPerPixel;
    CGFloat red   = (rawData[byteIndex]     * 1.0) /255.0;
    CGFloat green = (rawData[byteIndex + 1] * 1.0)/255.0 ;
    CGFloat blue  = (rawData[byteIndex + 2] * 1.0)/255.0 ;
    CGFloat alpha = (rawData[byteIndex + 3] * 1.0) /255.0;
    byteIndex += 4;
    UIColor *color = [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
    [resultColor addObject:color];
    //NSLog(@"width:%i hight:%i Color:%@",width,height,[color description]);
    free(rawData);
    return resultColor;
}
-(NSString *)returnFingerCoordinates:(UIImage *)ima{
    NSString *coor = @"";
    CGFloat red, green, blue;
    int width = ima.size.width;
    int height = ima.size.height;
    //Create coordinate matrix
    for(int x = 0; x<width; x++){
        for(int y=0; y<height; y++){
            cv::Mat greyMat;
            greyMat = [self cvMatFromUIImage:ima];
            cv::Vec3f intensity = greyMat.at<cv::Vec3f>(x, y);
            blue = intensity.val[0];
            green = intensity.val[1];
            red = intensity.val[2];
            NSLog(@"%f %f %f", blue, green, red);
            //            NSLog(@"%i", width);
            //             NSLog(@"%i", height);
            NSArray *thisarray = [self returnColors:x y:y];
            NSLog(@"%f %f %f", thisarray[0],  thisarray[1], thisarray[2]);
            //UIColor *redColor = thisarray[0];
            //[redColor getRed: &red green: &green blue: &blue alpha: &alpha];
            //NSLog(@"%f %f %f", red, green, blue);
            //            if(red>0 && blue>0 && green>0){
            //                [spot addObject:[NSNumber numberWithBool:true]];
            //            }
            //            else{
            //                [spot addObject:[NSNumber numberWithBool:false]];
            //            }
            //            [coordinates addObject: spot];
        }
        //NSLog(@"done with first loop");
    }
    //Get straight lines and corresponding r values
    //    int minthresh = 100;
    //    int occthresh = 200;
    //    for(int xx = 0; xx<width; xx++){
    //        NSArray *plot = [self returnResidualPlot:coordinates line:xx width:width height:height];
    //        if([[plot objectAtIndex:0] integerValue]<minthresh){
    //            if([[plot objectAtIndex:1] integerValue]<occthresh){
    //                NSLog(@"%i", xx);
    //            }
    //            else{
    //                NSLog(@"no");
    //            }
    //        }
    //        else{
    //            NSLog(@"not even here");
    //        }
    //        //[values addObject: [NSNumber numberWithInt:plot]];
    //    }
    //Get smallest and second smallest values in array
    return coor;
}
-(NSArray *)returnResidualPlot:(NSArray *)coor line:(int)myline width:(int)mywidth height:(int)myheight{
    NSMutableArray *fincount;
    int occurances = 0;
    int spacecount = 0;
    for(int b = 0; b<myheight; b++){
        //BOOL tf = [[[coor objectAtIndex:b] objectAtIndex:0] boolValue];
        int c = 0;
        int a = 0;
        while(c<10){
            if(myline+c > mywidth){
                if([[coor objectAtIndex:myline-c] objectAtIndex:b]){
                    spacecount+=c;
                }
                else{
                    a++;
                }
            }
            else if(myline-c < 0){
                if([[coor objectAtIndex:myline+c] objectAtIndex:b]){
                    spacecount+=c;
                }
                else{
                    a++;
                }
            }
            else{
                if([[coor objectAtIndex:myline+c] objectAtIndex:b]){
                    spacecount+=c;
                }
                else if([[coor objectAtIndex:myline-c] objectAtIndex:b]){
                    spacecount+=c;
                }
                else{
                    a++;
                }
            }
            c++;
        }
        if(a>=9){
            occurances++;
        }
    }
    [fincount addObject:[NSNumber numberWithInteger:spacecount]];
    [fincount addObject:[NSNumber numberWithInteger:occurances]];
    return fincount;
}
-(BOOL)doesImageWork:(UIImage *)ima{
    BOOL tf = false;
    return tf;
}
@end

