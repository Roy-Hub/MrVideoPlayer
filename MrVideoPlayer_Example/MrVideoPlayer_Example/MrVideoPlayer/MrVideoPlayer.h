//
//  multiVideoPlayer.h
//  MultiVideo
//
//  Created by Roy on 10/10/13.
//  Copyright (c) 2013 InApp Inc. All rights reserved.
//

//#define VIDEO_FRAME

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>

typedef enum
{
    videoOrientation_portrait,
    videoOrientation_upsideDown,
    videoOrientation_landscapeLeft,
    videoOrientation_landscapeRight
} videoOrientation;

@class playerView;

@protocol MrVideoPlayerDeligate <NSObject>
@optional
- (void)playerShouldPause;
- (void)playerShouldResume;
- (void)playerPaused:(id)sender;
- (void)playerStartedPlaying:(id)sender;
- (void)sliderMoved:(id)sender;
- (void)playerDidPlayToEnd:(id)sender;
- (void)DidPressCustomBtn:(UIButton *)CustBtn sender:(id)sender;

@end

@interface MrVideoPlayer : NSObject
{
    BOOL playing;
    UISlider *videoSlider;
    UIButton *muteOrUnmute;
    UIButton *playPause;
}

-(void)setURL:(NSURL*)theUrl;
-(void)setTitle:(char)Caption;
-(BOOL)displayPlayerinView:(UIView*)theView inframe:(CGRect)frame;
-(void)setBackgroundColorforPlayer:(UIColor *)BgColor;
-(void)removePlayerFromView;
-(void)PlayorPause;
-(void)play;
-(void)pause;
-(void)seekToTime:(double)Seconds;
-(void)setVolume:(Float32)VolumeFloat;
-(void)muteAudio;
-(void)unmuteAudio;

-(void)videoSliderTouchDown;
-(void)videoSliderTouchUp;
-(void)videoSliderValueChanged;
-(void)updateSlider;

-(void)hideSliderAfter:(float)Seconds;
-(void)showSlider;
-(void)hideSlider;

-(double)smoothSlider;
-(BOOL)willSliderHide;
-(BOOL)isPlaying;

-(void)changePlayerFrametoFrame:(CGRect)newFrame animated:(BOOL)animate;
-(CGRect)getPlayerFrame;
-(void)customiseToolbarViewWithBackgroundColour:(UIColor *)BackgndColor
                                borderThickness:(float)thickness
                                   borderColor :(UIColor *)borderColor
                                   cornerRadius:(float) cornerRadius;
-(void)setPlayButtonImage:(UIImage *)playImage andPauseButtonImage:(UIImage *)pauseImage;
-(void)setMuteUnbuteButtonVisible:(BOOL)visible;
-(void)setCustomButtonInToolbarNamed:(NSString *)BtnName andWidth:(CGFloat)BtnWidth;
-(UISlider *) getVideoSlider;
#ifdef VIDEO_FRAME
-(CGRect)getVideoRect;
#endif
-(BOOL)isToolbarAttachedToPlayer;
-(void)detatchToolbarFromPlayer:(BOOL)detatch;
-(UIView *)getToolbarView;
-(UIView *)gettoolbarViewForToolBarFrame:(CGRect)toolbarFrame;

@property (nonatomic) BOOL autohideToolbar;
@property (nonatomic) BOOL videoMuted;
@property (nonatomic) BOOL displayingVideo;
@property (nonatomic) BOOL isToolbarSeparatorsVisibile;

@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVAsset *asset;

@property (nonatomic) double duration;
@property (strong, nonatomic) playerView *videoPlayerView;
@property (nonatomic) videoOrientation Orinetation;
@property (nonatomic, strong) UIButton *customBtn;
@property (nonatomic, strong) id<MrVideoPlayerDeligate> delegate;

@end
