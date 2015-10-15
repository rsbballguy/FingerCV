//
//  ViewController.h
//  FingerCV
//
//  Created by Rahul Sundararaman on 10/15/15.
//  Copyright © 2015 Rahul Sundararaman. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <opencv2/videoio/cap_ios.h>
#include <opencv2/opencv.hpp>

@interface ViewController : UIViewController <CvVideoCameraDelegate>
@property (strong, nonatomic) IBOutlet UIImageView *ImageView;
@property (nonatomic, retain) CvVideoCamera* videoCamera;
@property (strong, nonatomic) IBOutlet UIImageView *contourimg;
@property (strong, nonatomic) IBOutlet UISlider *slider;
-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
-(NSArray*)getRGBAsFromImage:(UIImage*)image atX:(int)x andY:(int)y count:(int)count;
-(NSString *)returnFingerCoordinates:(UIImage *)ima;
- (cv::Mat)cvMatFromUIImage:(UIImage *)image;
-(NSArray *)returnResidualPlot:(NSArray *)coor line:(int)myline width:(int)mywidth height:(int)myheight;
-(BOOL)doesImageWork:(UIImage *)ima;
-(NSArray *)returnColors:(int)xval y:(int)yval
@end