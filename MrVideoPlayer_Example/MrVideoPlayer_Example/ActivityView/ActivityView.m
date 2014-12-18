//
//  ActivityView.m
//  VideoPlayer
//
//  Created by Roy on 12/12/14.
//  Copyright (c) 2014 InApp Inc. All rights reserved.
//

#import "ActivityView.h"

#define ADJUST_WIDTH_HEIGHT

#ifdef ADJUST_WIDTH_HEIGHT
const CGFloat margin = 10.0;
#endif

@interface ActivityView()
{
    NSLayoutConstraint *widthConstraint;
    NSLayoutConstraint *heightConstraint;
}
@property (strong, nonatomic) UIActivityIndicatorView *activityindicator;
@property (strong, nonatomic) UILabel *mesglabel;
@property (readonly) BOOL isActivityViewVisible;
@end

@implementation ActivityView

-(instancetype)init
{
    self = [super init];
    if(!self.activityindicator)
    {
        self.activityindicator = [[UIActivityIndicatorView alloc]init];
    }
    if(!self.mesglabel)
    {
        self.mesglabel = [[UILabel alloc]init];
    }
    [self addSubview:self.activityindicator];
    [self addSubview:self.mesglabel];
    [self setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.5]];
    [self setConstraints];
    
    
    [ActivityView setBorderForView:self
                   withBorderWidth:1.0
                       BorderColor:[UIColor blackColor]
                      cornerRadius:5.0];
    return self;
}

-(void)setConstraints
{
    [self.activityindicator setTranslatesAutoresizingMaskIntoConstraints:NO];
    [self.mesglabel setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    NSDictionary *viewsDic = @{@"hud":self.activityindicator,@"mesg":self.mesglabel};
    NSDictionary *metrics = @{@"topDist":@8, @"margin":[NSNumber numberWithFloat:margin]};
    
    NSArray *view_constraints_V = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-topDist-[hud]-8-[mesg]-|"
                                                                          options:NSLayoutFormatAlignAllCenterX
                                                                          metrics:metrics
                                                                            views:viewsDic];
    
    [self addConstraints:view_constraints_V];
    
    NSArray *mesgL_constraints_H = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-margin-[mesg]-margin-|"
                                                                           options:NSLayoutFormatAlignAllCenterX
                                                                           metrics:metrics
                                                                             views:viewsDic];
    [self addConstraints:mesgL_constraints_H];
    
    NSLayoutConstraint *horizontalCenterConstraint =
    [NSLayoutConstraint constraintWithItem:self.activityindicator
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.0 constant:0];
    
    [self addConstraint:horizontalCenterConstraint];
    
    //Width and Height Constraints
    widthConstraint = [NSLayoutConstraint constraintWithItem:self
                                                   attribute:NSLayoutAttributeWidth
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:nil
                                                  multiplier:1.0
                                                    constant:0];
    
    heightConstraint =[NSLayoutConstraint constraintWithItem:self
                                                   attribute:NSLayoutAttributeHeight
                                                   relatedBy:NSLayoutRelationEqual
                                                      toItem:nil
                                                   attribute:nil
                                                  multiplier:1.0
                                                    constant:0];
    
    [widthConstraint setPriority:800];
    [heightConstraint setPriority:800];
    
    [self addConstraint:widthConstraint];
    [self addConstraint:heightConstraint];
}

-(void)setConstraintsInSuperView:(UIView *)view
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

#ifndef ADJUST_WIDTH_HEIGHT
    CGSize size = [[self mesglabel]sizeThatFits:view.frame.size];
    size.width = (size.width + 20 < view.frame.size.width)?size.width:(view.frame.size.width - 26);
    
    [widthConstraint setConstant:size.width];
    [heightConstraint setConstant:70.0];
#endif

    //Constaints for aligning it in center
    NSLayoutConstraint *horizontalCenterConstraint =
    [NSLayoutConstraint constraintWithItem:self
                                 attribute:NSLayoutAttributeCenterX
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeCenterX
                                multiplier:1.0 constant:0];
    
    NSLayoutConstraint *verticalCenterConstraint =
    [NSLayoutConstraint constraintWithItem:self
                                 attribute:NSLayoutAttributeCenterY
                                 relatedBy:NSLayoutRelationEqual
                                    toItem:view
                                 attribute:NSLayoutAttributeCenterY
                                multiplier:1.0 constant:0];
    
    [view addConstraint:horizontalCenterConstraint];
    [view addConstraint:verticalCenterConstraint];
    
#ifdef ADJUST_WIDTH_HEIGHT
    //horizontal Constrains for limiting width of hud
    NSLayoutConstraint *trailingMarginConstraint =
    [NSLayoutConstraint constraintWithItem:view
                                 attribute:NSLayoutAttributeTrailing
                                 relatedBy:NSLayoutRelationGreaterThanOrEqual
                                    toItem:self
                                 attribute:NSLayoutAttributeTrailing
                                multiplier:1.0
                                  constant:8.0];

    [view addConstraint:trailingMarginConstraint];
#endif
}

#ifdef ADJUST_WIDTH_HEIGHT
/**
 *  Adjusts width and height of ActivityView (self) accoding to the width of text
 */
-(void)adjustWidthAndHeight
{
    CGSize maxSize = CGSizeMake(CGFLOAT_MAX, 70);
    CGSize size = [[self mesglabel]sizeThatFits:maxSize];

    [widthConstraint setConstant:size.width + 2.0 * margin];
    [heightConstraint setConstant:70.0];
}
#endif
+(void)setBorderForView:(UIView *)view
        withBorderWidth:(CGFloat)borderWidth
            BorderColor:(UIColor *)borderColor
           cornerRadius:(CGFloat)radius
{
    [[view layer] setBorderWidth:borderWidth];
    [[view layer] setBorderColor:borderColor.CGColor];
    [[view layer] setCornerRadius:radius];
}

+(CGRect)activityFrameForFrame:(CGRect)vidFrame
{
    return [[ActivityView sharedView]activityFrameForFrame:vidFrame];
}

-(CGRect)activityFrameForFrame:(CGRect)vidFrame
{
    CGSize size = [[self mesglabel]sizeThatFits:vidFrame.size];
    size.width = (size.width + 20 < vidFrame.size.width)?size.width:(vidFrame.size.width - 26);
    CGSize activitySize = CGSizeMake(size.width + 20, 70);
    CGPoint center = CGPointMake(CGRectGetMidX(vidFrame), CGRectGetMidY(vidFrame));
    CGPoint activityOrigin = CGPointMake(center.x - activitySize.width/2.0, center.y - activitySize.height/2.0);
    CGRect activityFrame;
    activityFrame.origin = activityOrigin;
    activityFrame.size   = activitySize;
    return activityFrame;
}

+ (ActivityView*)sharedView
{
    static dispatch_once_t once;
    static ActivityView *sharedView;
    dispatch_once(&once, ^ { sharedView = [[self alloc] init]; });
    return sharedView;
}

#pragma mark - Setters
+(void)setBackgroundColour:(UIColor *)colour
{
    [[self sharedView]setBackgroundColor:colour];
}

+(void)setFont:(UIFont *)font
{
    [[ActivityView sharedView]setFont:font];
}
-(void)setFont:(UIFont *)font
{
    if(font)
    {
        [[self mesglabel]setFont:font];
    }
}


#pragma mark - Show Hide Methods

+(void)showActivityInView:(UIView *)view withText:(NSString *)string
{
    [[ActivityView sharedView]showActivityInView:view withText:string];
}

-(void)showActivityInView:(UIView *)view withText:(NSString *)string
{
    [self.mesglabel setText:string];
    
    [self showInView:view];
#ifdef ADJUST_WIDTH_HEIGHT
    [self adjustWidthAndHeight];
#endif
    [self setConstraintsInSuperView:view];
    
    _isActivityViewVisible = YES;
    [self layoutIfNeeded];
    [[self activityindicator] startAnimating];
    [self setHidden:NO];
}

+(void)hideActivity
{
    [[self sharedView]hideActivity];
}

-(void)hideActivity
{
    [[self activityindicator]stopAnimating];
    [self setHidden:YES];
    [self removeFromSuperview];
    _isActivityViewVisible = NO;
}

-(void)showInView:(UIView *)superView
{
    CGAffineTransform theTransform = superView.transform;
    superView.transform = CGAffineTransformIdentity;
    [superView addSubview:self];
    [superView setTransform:theTransform];
}
#pragma mark - Status
+(BOOL)isVisible
{
    return [[ActivityView sharedView]isVisible];
}

-(BOOL)isVisible
{
    return [self isActivityViewVisible];
}
@end
