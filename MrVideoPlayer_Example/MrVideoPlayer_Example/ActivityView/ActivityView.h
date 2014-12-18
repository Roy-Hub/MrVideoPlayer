//
//  ActivityView.h
//  VideoPlayer
//
//  Created by Roy on 12/12/14.
//  Copyright (c) 2014 InApp Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ActivityView : UIView

+(void)showActivityInView:(UIView *)view withText:(NSString *)string;
-(void)showActivityInView:(UIView *)view withText:(NSString *)string;

+(void)hideActivity;
-(void)hideActivity;

+(void)setBackgroundColour:(UIColor *)colour;

+(void)setFont:(UIFont *)font;
-(void)setFont:(UIFont *)font;

+(BOOL)isVisible;
-(BOOL)isVisible;

+(CGRect)activityFrameForFrame:(CGRect)vidFrame;
-(CGRect)activityFrameForFrame:(CGRect)vidFrame;

@end
