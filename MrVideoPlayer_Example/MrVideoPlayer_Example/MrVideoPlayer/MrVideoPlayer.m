//
//  multiVideoPlayer.m
//  MultiVideo
//
//  Created by Roy on 10/10/13.
//  Copyright (c) 2013 InApp Inc. All rights reserved.
//


//#define SHOW_HUD_PLAY

#import "MrVideoPlayer.h"
#import "ActivityView.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#import "playerView.h"

const unsigned int kmuteUnmuteBtnSide = 27;
const unsigned int kplayPauseBtnSide  = 27;

//#define PresiseSeekTRIAL

@interface multiVideoPlayer()
{
    NSTimer *TimerForSeekBar;
    int pendingHide;
    int cancelHides;
    NSURL *videoURl;
    BOOL URLset;
    Float32 hardwareVolume;
    UIImage *muteImage;
    UIImage *unmuteImage;
    NSNotificationCenter *avPlayerNotification;
#ifdef PresiseSeekTRIAL
    BOOL freezeSlider;
#endif
    BOOL isAssetSet;
    BOOL isCustomButtonExists;
    BOOL isMuteBtnVisible;
    CGFloat customBtnWidth;
    NSMutableArray *lineViewAray;
    BOOL isToolBarAttached;
    BOOL titleSet;
    BOOL shouldStartFromBegining;
    UIView *toolBarView;
    UIView *toolBarView_line1;
    UIView *toolBarView_line2;
    UIView *toolBarView_line3;
    UIImage *playIcon;
    UIImage *pauseIcon;
    UIView *titleView;
    NSString *playerTitle;
#ifdef SUPPORT_STREAMING
    ActivityView *activity;
#endif
}
-(IBAction)muteOrUnmuteBtnAction:(id)sender;
-(void)playPauseBtnAction:(id)sender;
-(void)playerItemDidReachEnd:(NSNotification *)notification;
-(void)hideSliderInternal;
-(void)getHardwareVolume;

-(CGRect)frame_ToolBarViewForPlayerFrame:(CGRect)playerFrame;
-(CGRect)frame_VideoSilderForToolbarFrame:(CGRect)toolbarFrame;

-(CGRect)frame_PlayPauseBtnInToolbarFrame:(CGRect)toolbarFrame;
-(CGRect)frame_muteOrUnmuteBtnInToolbarFrame:(CGRect)toolbarFrame;
-(CGRect)frame_customBtnInToolbarFrame:(CGRect)toolbarFrame;
-(void)customBtnPressed;
-(CGRect)frame_line:(int)lineNumber toolbarFrame:(CGRect)toolbarFrame;

-(void)changePlayerFrame:(CGRect)newFrame;

-(CGRect)adjustedFrameForOrientation:(videoOrientation)newOrientation
                       originalFrame:(CGRect)originalFrame;

-(void)setupToolbarUIForPlayerFrame:(CGRect)playerFrame;
-(void)setupToolbarUIForToolbarFrame:(CGRect)toolBarFrame;
-(void)removeAllSubViewsFromView:(UIView *)viewWithSubviews;

-(void)populateLineViewArrayForToolbarFrame:(CGRect)toolbarFrame;

-(void)rotateVideoView:(videoOrientation)mode;

@end


@implementation multiVideoPlayer

@synthesize duration;
@synthesize playerItem;
@synthesize player;
@synthesize asset;

-(id)init
{
    pendingHide          = 0;
    cancelHides          = 0;
    playing              = NO;
    self.duration        = 0.0;
    URLset               = NO;
    self.displayingVideo = NO;
    self.videoMuted      = NO;

    _Orinetation         = videoOrientation_portrait;

#ifdef PresiseSeekTRIAL
    freezeSlider = YES;
#endif
    _isToolbarSeparatorsVisibile = YES;

    isToolBarAttached = YES;
    isAssetSet = NO;
    _autohideToolbar = NO;
    titleSet = NO;
    shouldStartFromBegining = NO;
    playIcon  = [UIImage imageNamed:@"MVP-bt-play.png"];
    pauseIcon = [UIImage imageNamed:@"MVP-bt-pause.png"];
    muteImage   = [UIImage imageNamed:@"mute_grey.png"];
    unmuteImage = [UIImage imageNamed:@"unmute_grey.png"];
    return self;
}

#pragma mark setter Methods

-(void)setIsToolbarSeparatorsVisibile:(BOOL)toolbarSeparatorValue
{
    _isToolbarSeparatorsVisibile = toolbarSeparatorValue;
    if(toolBarView)
    {
        CGAffineTransform currentTransform = toolBarView.transform;
        [toolBarView setTransform:CGAffineTransformIdentity];
        [self setupToolbarUIForToolbarFrame:toolBarView.frame];
        [toolBarView setTransform:currentTransform];
    }
}
-(void)setURL:(NSURL *)theUrl
{
    videoURl = theUrl;
    URLset = YES;
}

-(void)setAsset:(AVAsset *)newAsset
{
    isAssetSet = NO;
    URLset     = NO;
    if(newAsset == asset)
    {
        isAssetSet = YES;
        if(!self.playerItem)
            self.playerItem = [[AVPlayerItem alloc]initWithAsset:self.asset];
    }
    else if(newAsset != nil)
    {
        asset = newAsset;
        isAssetSet = YES;
        self.playerItem = [[AVPlayerItem alloc]initWithAsset:self.asset];
        self.player     = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
    }
}

-(void)setOrinetation:(videoOrientation)Orinetation
{
    if(_Orinetation != Orinetation)
    {
        NSLog(@"New Orientation %d", Orinetation);
        if(_videoPlayerView)
        {
            CGRect adjustedFrame = [self adjustedFrameForOrientation:Orinetation
                                                       originalFrame:_videoPlayerView.frame];
            
            [UIView animateWithDuration:0.2 animations:^{
                [self changePlayerFrame:adjustedFrame];
                [self rotateVideoView:Orinetation];
            }];
        }
        _Orinetation = Orinetation;
    }
}

-(void)setTitle:(char)Caption
{
    playerTitle = [NSString stringWithFormat:@"%c", Caption];
    titleView   = [[UIView alloc]init];
    titleSet    = YES;
}

-(void)setPlayButtonImage:(UIImage *)playImage andPauseButtonImage:(UIImage *)pauseImage
{
    playIcon  = playImage;
    pauseIcon = pauseImage;
}

-(void)setBackgroundColorforPlayer:(UIColor *)BgColor
{
    [_videoPlayerView setBackgroundColor:BgColor];
}

-(void)setAutohideToolbar:(BOOL)autohideToolbar
{
    _autohideToolbar = autohideToolbar;
}

-(BOOL)displayPlayerinView:(UIView *)theView inframe:(CGRect)frame
{
#ifdef SUPPORT_STREAMING
    [self removeObservers];
#endif
   if(URLset || isAssetSet)
    {
        if(!isAssetSet)
        {
            NSDictionary *options = @{ AVURLAssetPreferPreciseDurationAndTimingKey : @YES };
            self.asset      = [[AVURLAsset alloc]initWithURL:videoURl options:options];
            self.playerItem = [[AVPlayerItem alloc]initWithAsset:self.asset];
            self.player     = [[AVPlayer alloc]initWithPlayerItem:self.playerItem];
        }
#ifdef SUPPORT_STREAMING
        if(!activity)
            activity = [[ActivityView alloc]init];
        [self addObservers];
#endif
        self.player.actionAtItemEnd = AVPlayerActionAtItemEndNone;
        
        avPlayerNotification = [NSNotificationCenter defaultCenter];
        [avPlayerNotification addObserver:self
                                 selector:@selector(playerItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
        if(!_videoPlayerView)
        {
            _videoPlayerView = [[playerView alloc]initWithFrame:frame];
        }
        
        [_videoPlayerView setFrame:frame];
        [_videoPlayerView setPlayer:self.player];
        [theView addSubview:_videoPlayerView];
        
        self.duration = CMTimeGetSeconds([self.asset duration]);
        
        if(!videoSlider)
            videoSlider = [[UISlider alloc]init];
        
        if(!playPause)
            playPause = [[UIButton alloc]init];
        
        if(!muteOrUnmute)
            muteOrUnmute = [[UIButton alloc]init];
        
        videoSlider.minimumValue = 0.0;
        videoSlider.maximumValue = self.duration;
        
        [videoSlider addTarget:self action:@selector(videoSliderTouchDown) forControlEvents:UIControlEventTouchDown];
        [videoSlider addTarget:self action:@selector(videoSliderTouchUp) forControlEvents:UIControlEventTouchUpInside];
        [videoSlider addTarget:self action:@selector(videoSliderValueChanged) forControlEvents:UIControlEventValueChanged];
        
        [playPause addTarget:self action:@selector(playPauseBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [playPause setImage:playIcon forState:UIControlStateNormal];
        
        [muteOrUnmute addTarget:self action:@selector(muteOrUnmuteBtnAction:) forControlEvents:UIControlEventTouchUpInside];
        [muteOrUnmute setImage:unmuteImage forState:UIControlStateNormal];
        
        
        [self setupToolbarUIForPlayerFrame:frame];
        [self customiseToolbarViewWithBackgroundColour:[UIColor colorWithWhite:0.2 alpha:0.5]
                                       borderThickness:1.0
                                           borderColor:[UIColor colorWithRed:0 green:0 blue:0 alpha:0.8]
                                          cornerRadius:8.0];
        if(titleSet)
        {
            titleView.frame = CGRectMake(0, toolBarView.frame.origin.y - toolBarView.frame.size.height, toolBarView.frame.size.height, toolBarView.frame.size.height);
            
            UILabel *TLabel = [[UILabel alloc]init];
            TLabel.frame = CGRectMake(0, 0, titleView.frame.size.width, titleView.frame.size.height);
            TLabel.text = playerTitle;
            TLabel.backgroundColor = [UIColor clearColor];
            TLabel.textColor = [UIColor whiteColor];
            [TLabel setTextAlignment:NSTextAlignmentCenter];
            [titleView addSubview:TLabel];
            [theView addSubview:titleView];
        }
        if(isToolBarAttached)
        {
            [_videoPlayerView addSubview:toolBarView];
        }
        self.displayingVideo = YES;
        
        return YES;
    }
    else
    {
        NSLog(@"multiVideoPlayer: URL not set");
        return NO;
    }
}

-(void)playerItemDidReachEnd:(NSNotification *)notification
{
    if([self.delegate respondsToSelector:@selector(playerDidPlayToEnd:)])
    {
        shouldStartFromBegining = YES;
        [playPause setImage:playIcon forState:UIControlStateNormal];
        playing = NO;
        [self.delegate playerDidPlayToEnd:self];
    }
}

-(void)setVolume:(Float32)VolumeFloat
{
    NSArray *audioTracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    
    // Mute all the audio tracks
    NSMutableArray *allAudioParams = [NSMutableArray array];
    for (AVAssetTrack *track in audioTracks) {
        AVMutableAudioMixInputParameters *audioInputParams =    [AVMutableAudioMixInputParameters audioMixInputParameters];
        [audioInputParams setVolume:VolumeFloat atTime:kCMTimeZero];
        [audioInputParams setTrackID:[track trackID]];
        [allAudioParams addObject:audioInputParams];
    }
    AVMutableAudioMix *audioZeroMix = [AVMutableAudioMix audioMix];
    [audioZeroMix setInputParameters:allAudioParams];
    
    [[self.player currentItem] setAudioMix:audioZeroMix];
    if(VolumeFloat == 0)
        self.videoMuted = YES;
    else
        self.videoMuted = NO;
}

-(void)muteAudio
{
    [self setVolume:0.0f];
}

-(void)getHardwareVolume
{
    
    UInt32 dataSize = sizeof(Float32);
    
    AudioSessionGetProperty (
                             kAudioSessionProperty_CurrentHardwareOutputVolume,
                             &dataSize,
                             &hardwareVolume
                             );
    NSLog(@"Current hardeware Volume = %f", hardwareVolume);
}


-(void)unmuteAudio
{
    [self getHardwareVolume];
    if(hardwareVolume)
        [self setVolume:1];
    else
        [self setVolume:0.0];
}

-(void)removePlayerFromView
{
    [toolBarView removeFromSuperview];
    [_videoPlayerView removeFromSuperview];
//    [layer removeFromSuperlayer];
    [avPlayerNotification removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:[self.player currentItem]];
    
    [self removeObservers];
    
    self.displayingVideo = NO;
}

-(void)videoSliderTouchDown
{
    if(playing)
    {
        if([self.delegate respondsToSelector:@selector(playerShouldPause)])
            [self.delegate playerShouldPause];
    }
    [self.player pause];
    [self showSlider];
}

-(void)videoSliderTouchUp
{
    if([self.delegate respondsToSelector:@selector(playerShouldResume)])
        [self.delegate playerShouldResume];
    if([self.delegate respondsToSelector:@selector(sliderMoved:)])
        [self.delegate sliderMoved:self];
    
    if(self.autohideToolbar) [self hideSliderAfter:2.0];
    

#ifdef PresiseSeekTRIAL
    if(videoSlider.value > CMTimeGetSeconds([self.player currentTime]))
    {
        freezeSlider = YES;
        double diff = videoSlider.value - CMTimeGetSeconds([self.player currentTime]) ;
        [self performSelector:@selector(pause) withObject:nil afterDelay:diff];
        [self play];
    }
#else
    if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
    {
        [UIView animateWithDuration:0.3 animations:^{
            [videoSlider setValue:CMTimeGetSeconds([self.player currentTime]) animated:YES];
        }];
    }
    else
    {
        [videoSlider setValue:CMTimeGetSeconds([self.player currentTime]) animated:YES];
    }
#endif
    if(playing)
        [self.player play];
}

-(void)videoSliderValueChanged
{
#ifdef PresiseSeekTRIAL
    [self.player seekToTime:CMTimeMakeWithSeconds(videoSlider.value, NSEC_PER_SEC) toleranceBefore:kCMTimeIndefinite toleranceAfter:kCMTimeZero];
    
#else
    [self.player seekToTime:CMTimeMakeWithSeconds(videoSlider.value, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeIndefinite];
#endif
    shouldStartFromBegining = NO;
}

-(void)updateSlider
{
#ifdef PresiseSeekTRIAL
    if(!freezeSlider)
        videoSlider.value = CMTimeGetSeconds([self.player currentTime]);
    
#else
    videoSlider.value = CMTimeGetSeconds([self.player currentTime]);
#endif
}

-(void)hideSliderAfter:(float)Seconds
{
    if(self.displayingVideo)
    {
        [self performSelector:@selector(hideSliderInternal) withObject:nil afterDelay:Seconds];
        pendingHide++;
    }
}

-(void)hideSlider
{
    if(self.displayingVideo)
    {
        [self performSelector:@selector(hideSliderInternal)];
        pendingHide++;
    }
}

-(void)hideSliderInternal
{
    if (cancelHides > 0)
    {
        cancelHides--;
    }
    else
    {
        [UIView animateWithDuration:0.2 animations:^{
            toolBarView.alpha = 0;
            if(titleSet)
                titleView.alpha = 0;
        }];
    }
    pendingHide--;
}

-(void)showSlider
{
    if(self.displayingVideo)
    {
        [UIView animateWithDuration:0.2 animations:^{
            toolBarView.alpha = 1;
            if(titleSet)
                titleView.alpha = 1;

        }];
        if(pendingHide)
        {
            cancelHides = pendingHide;
        }
    }
}

-(BOOL)willSliderHide
{
    if(pendingHide>0 || toolBarView.alpha ==0)
        return YES;
    return NO;
}

-(double)smoothSlider
{
    return videoSlider.maximumValue/videoSlider.frame.size.width;
}

-(void)play
{
    if(self.displayingVideo)
    {
#ifdef PresiseSeekTRIAL
        if(freezeSlider)
            [layer removeFromSuperlayer];
#endif
#ifdef SHOW_HUD_PLAY
        [activity showActivityInView:_videoPlayerView withText:@"Playing Test..."];
#endif
        playing = YES;
        [self.player play];
        [playPause setImage:pauseIcon forState:UIControlStateNormal];
        if(!TimerForSeekBar)
        {
            TimerForSeekBar = [NSTimer scheduledTimerWithTimeInterval:[self smoothSlider] target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
        }
    }
}

-(void)pause
{
    if(self.displayingVideo)
    {
#ifdef SUPPORT_STREAMING
        [activity hideActivity];
#endif
        playing = NO;
        [self.player pause];
        [playPause setImage:playIcon forState:UIControlStateNormal];
        if(TimerForSeekBar != nil)
        {
            [TimerForSeekBar invalidate];
            TimerForSeekBar = nil;
        }
    }
#ifdef PresiseSeekTRIAL
    if(freezeSlider)
    {
        freezeSlider = NO;
    }
#endif
}

-(void)PlayorPause
{
    if(self.displayingVideo)
    {
        if(playing)
            [self pause];
        else
            [self play];
    }
}

-(void)seekToTime:(double)Seconds
{
    if(self.displayingVideo)
    {
        if(Seconds < self.duration)
        {
            [self.player seekToTime:CMTimeMakeWithSeconds(Seconds, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeIndefinite];
        }
        else
            [self.player seekToTime:self.playerItem.duration toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeIndefinite];
        
        if(Seconds == 0.0)
            videoSlider.value = 0.0;
        else
            [videoSlider setValue:CMTimeGetSeconds([self.player currentTime]) animated:YES];
    }
}

-(void)muteOrUnmuteBtnAction:(id)sender
{
    if(self.videoMuted)
    {
        [self unmuteAudio];
        if(!self.videoMuted)
            [muteOrUnmute setImage:unmuteImage forState:UIControlStateNormal];
        else
            [muteOrUnmute setImage:muteImage forState:UIControlStateNormal];
    }
    else
    {
        [self muteAudio];
        [muteOrUnmute setImage:muteImage forState:UIControlStateNormal];
    }
}

-(BOOL)isPlaying
{
    if(playing)
        return YES;
    return NO;
}

-(void)playPauseBtnAction:(id)sender
{
    if([self willSliderHide])
    {
        [self showSlider];
        if(self.autohideToolbar)[self hideSliderAfter:2.0];

    }
    if(playing)
    {
        [self pause];
        if([self.delegate respondsToSelector:@selector(playerPaused:)])
        {
            [self.delegate playerPaused:self];
        }        
    }
    else
    {
        if(shouldStartFromBegining)
        {
            [self seekToTime:0.0];
            shouldStartFromBegining = NO;
        }
        [self play];
        if([self.delegate respondsToSelector:@selector(playerStartedPlaying:)])
        {
            [self.delegate playerStartedPlaying:self];
        }
    }
}
#pragma mark External Methods
-(void)changePlayerFrametoFrame:(CGRect)newFrame animated:(BOOL)animate
{
    CGRect adjFrame = [self adjustedFrameForOrientation:self.Orinetation originalFrame:newFrame];
    if(animate == YES)
    {
        [UIView animateWithDuration:0.3 animations:^{
            [self changePlayerFrame:adjFrame];
        }];
        [self rotateVideoView:self.Orinetation];
    }
    else
    {
        [self changePlayerFrame:adjFrame];
        [self rotateVideoView:self.Orinetation];
    }
}

-(CGRect)getPlayerFrame
{
    return [self.videoPlayerView frame];
}

-(void)customiseToolbarViewWithBackgroundColour:(UIColor *)BackgndColor borderThickness:(float)thickness borderColor:(UIColor *)borderColor cornerRadius:(float)cornerRadius
{
    if(toolBarView != nil)
    {
        [toolBarView.layer setCornerRadius:cornerRadius];
        [toolBarView.layer setBorderWidth:thickness];
        
        [toolBarView.layer setBorderColor:borderColor.CGColor];
        if(!toolBarView_line1)
            toolBarView_line1 = [[UIView alloc]init];
        
        if(!toolBarView_line2)
            toolBarView_line2 = [[UIView alloc]init];
        
        if(!toolBarView_line3)
            toolBarView_line3 = [[UIView alloc]init];
        [toolBarView_line3 setBackgroundColor:borderColor];
        [toolBarView_line1 setBackgroundColor:borderColor];
        [toolBarView_line2 setBackgroundColor:borderColor];
        
        toolBarView.layer.backgroundColor = CGColorCreateCopy(BackgndColor.CGColor);
    }
}
-(void)setCustomButtonInToolbarNamed:(NSString *)BtnName andWidth:(CGFloat)BtnWidth
{
    if(!_customBtn)
    {
        _customBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    }
    customBtnWidth = BtnWidth;
    [self.customBtn setTitle:BtnName forState:UIControlStateNormal];
    [self.customBtn removeTarget:self action:NULL forControlEvents:UIControlEventAllEvents];
    [self.customBtn addTarget:self action:@selector(customBtnPressed) forControlEvents:UIControlEventTouchUpInside];
    isCustomButtonExists = YES;
}
-(void)setMuteUnbuteButtonVisible:(BOOL)visible
{
    isMuteBtnVisible = visible;
}

-(UISlider *)getVideoSlider
{
    if(videoSlider)
        return videoSlider;
    else
        return nil;
}
#ifdef VIDEO_FRAME
-(CGRect)getVideoRect
{
    CGRect videoFrame = CGRectZero;
    AVPlayerLayer *avLayer = (AVPlayerLayer *)[_videoPlayerView layer];
    if([avLayer respondsToSelector:@selector(videoRect)])
    {
        NSLog(@"Yes, video rect Works");
        videoFrame = [avLayer videoRect];
        NSLog(@"Frame = %@", NSStringFromCGRect(videoFrame));
    }
    else
    {
        NSLog(@"No video rect, try  alternate methods");
    }
    return videoFrame;
}
-(NSString *)scaledSize:(CGSize)videoSize to:(CGSize)targetSize{
    CGFloat width = videoSize.width;
    CGFloat height = videoSize.height;
    
    CGFloat targetWidth = targetSize.width;
    CGFloat targetHeight = targetSize.height;
    
    CGFloat scaleFactor = 0.0;
    CGFloat scaledWidth = targetWidth;
    CGFloat scaledHeight = targetHeight;
    
    if (CGSizeEqualToSize(videoSize, targetSize) == NO) {
        CGFloat widthFactor = targetWidth / width;
        CGFloat heightFactor = targetHeight / height;
        
        if (widthFactor < heightFactor) scaleFactor = widthFactor;
        else scaleFactor = heightFactor;
        
        scaledWidth = width * scaleFactor;
        scaledHeight = height * scaleFactor;
    }
    return [NSString stringWithFormat:@"%f^%f^%f",scaledWidth, scaledHeight, scaleFactor];
}
#endif

-(void)detatchToolbarFromPlayer:(BOOL)detatch
{
    if(detatch)
    {
        [toolBarView removeFromSuperview];
    }
    else
    {
        [self setupToolbarUIForPlayerFrame:_videoPlayerView.frame];
        [_videoPlayerView addSubview:toolBarView];
    }
    isToolBarAttached = !detatch;
}
-(UIView *)getToolbarView
{
    return toolBarView;
}

-(UIView *)gettoolbarViewForToolBarFrame:(CGRect)toolbarFrame
{
    [self setupToolbarUIForToolbarFrame:toolbarFrame];
    return toolBarView;
}

-(BOOL)isToolbarAttachedToPlayer
{
    return isToolBarAttached;
}

#pragma mark Internal methods

-(CGRect)frame_ToolBarViewForPlayerFrame:(CGRect)playerFrame
{
    return CGRectMake(0, playerFrame.size.height - 42, playerFrame.size.width, 40);
}

-(CGRect)frame_VideoSilderForToolbarFrame:(CGRect)toolbarFrame
{
    CGFloat tb_height = CGRectGetHeight(toolbarFrame);
    CGFloat widthReductions = isMuteBtnVisible? (2.0 * tb_height):(tb_height+2);
    if(isCustomButtonExists)
    {
        widthReductions += (customBtnWidth);
    }
    return CGRectMake(CGRectGetHeight(toolBarView.frame) + 2, 0, toolbarFrame.size.width - widthReductions, tb_height);
}

-(CGRect)frame_PlayPauseBtnInToolbarFrame:(CGRect)toolbarFrame
{
    CGRect mFrame = CGRectMake(0, 0, kplayPauseBtnSide, kplayPauseBtnSide);
    CGPoint origin = CGPointMake(0, 0);
    CGFloat midY = CGRectGetHeight(toolbarFrame) / 2.0;
    origin.y = midY - ( CGRectGetHeight(mFrame) / 2.0 );
    origin.x = origin.y;
    mFrame.origin = origin;
    return mFrame;
}

-(CGRect)frame_muteOrUnmuteBtnInToolbarFrame:(CGRect)toolbarFrame
{
    CGRect mFrame = CGRectZero;
    CGFloat tempValue;
    if(isMuteBtnVisible)
    {
        mFrame = CGRectMake(0, 0, kmuteUnmuteBtnSide, kmuteUnmuteBtnSide);
        CGFloat midY = CGRectGetHeight(toolbarFrame) / 2.0;
        CGPoint origin;
        
        tempValue = midY + (kmuteUnmuteBtnSide / 2.0);
        origin.y = midY - ( CGRectGetHeight(mFrame) / 2.0);
        origin.x = CGRectGetWidth(toolbarFrame) - tempValue;

        if(isCustomButtonExists)
            origin.x -= customBtnWidth;
        mFrame.origin = origin;
    }
    return mFrame;
}
-(CGRect)frame_customBtnInToolbarFrame:(CGRect)toolbarFrame
{
    CGRect mFrame = CGRectZero;
    if(isCustomButtonExists)
    {
        CGSize btnSize = CGSizeMake(customBtnWidth, CGRectGetHeight(toolbarFrame));
        mFrame.origin = CGPointMake(CGRectGetWidth(toolbarFrame) - customBtnWidth, 0);
        mFrame.size   = btnSize;
    }
    return mFrame;
}
-(CGRect)frame_line:(int)lineNumber toolbarFrame:(CGRect)toolbarFrame
{
    CGRect mFrame    = CGRectZero;
    CGRect tempFrame = CGRectZero;
    mFrame.size = CGSizeMake(1, CGRectGetHeight(toolbarFrame));
    mFrame.origin = CGPointMake(0, 0);
    switch (lineNumber)
    {
        case 1:
            mFrame.origin = CGPointMake(CGRectGetHeight(toolbarFrame), 0);
            break;
            
        case 2:
            if(isMuteBtnVisible)
            {
                tempFrame = [self frame_VideoSilderForToolbarFrame:toolbarFrame];
                mFrame.origin =  CGPointMake(CGRectGetMaxX(tempFrame), 0.0);
            }
            else
                mFrame = CGRectZero;
            break;
            
        case 3:
            if(isCustomButtonExists)
            {
                tempFrame = [self frame_customBtnInToolbarFrame:toolbarFrame];
                mFrame.origin = CGPointMake(CGRectGetMinX(tempFrame) - 1, 0);
            }
            else
                mFrame = CGRectZero;
            break;
            
        default:
            NSLog(@"Undefined Line Number");
            break;
    }
    return mFrame;
}





-(void)removeAllSubViewsFromView:(UIView *)viewWithSubviews
{
    NSArray *viewsToRemove = [viewWithSubviews subviews];
    for (UIView *v in viewsToRemove)
    {
        [v removeFromSuperview];
    }
}

-(void)setupToolbarUIForPlayerFrame:(CGRect)playerFrame
{
    if(!toolBarView)
    {
        toolBarView = [[UIView alloc]init];
        [toolBarView setClipsToBounds:YES];
    }
    
    CGRect frameForToolbar = [self frame_ToolBarViewForPlayerFrame:playerFrame];
    [self setupToolbarUIForToolbarFrame:frameForToolbar];
}

-(void)setupToolbarUIForToolbarFrame:(CGRect)toolBarFrame
{
    [self removeAllSubViewsFromView:toolBarView];
    [toolBarView setFrame:toolBarFrame];
    [playPause setFrame:[self frame_PlayPauseBtnInToolbarFrame:toolBarView.frame]];
    if(isMuteBtnVisible)
    {
        [muteOrUnmute setFrame:[self frame_muteOrUnmuteBtnInToolbarFrame:toolBarView.frame]];
        [muteOrUnmute setHidden:NO];
    }
    else
    {
        [muteOrUnmute setHidden:YES];
    }
    if(isCustomButtonExists)
    {
        if(self.customBtn != nil)
        {
            [self.customBtn setFrame:[self frame_customBtnInToolbarFrame:toolBarView.frame]];
        }
    }
    if(videoSlider != nil)
        [videoSlider setFrame:[self frame_VideoSilderForToolbarFrame:toolBarView.frame]];
    
    [toolBarView addSubview:videoSlider];
    [toolBarView addSubview:playPause];
    if(isMuteBtnVisible) [toolBarView addSubview:muteOrUnmute];
    if(isCustomButtonExists && (self.customBtn != nil)) [toolBarView addSubview:self.customBtn];

    if(self.isToolbarSeparatorsVisibile)
    {
        [self populateLineViewArrayForToolbarFrame:toolBarView.frame];
        for (UIView *theLineView in lineViewAray)
        {
            [toolBarView addSubview:theLineView];
        }
    }

}

-(void)populateLineViewArrayForToolbarFrame:(CGRect)toolbarFrame
{
    if(!lineViewAray)
        lineViewAray = [[NSMutableArray alloc]init];
    [lineViewAray removeAllObjects];
    
    if(!toolBarView_line1)
        toolBarView_line1 = [[UIView alloc]init];
    if(!toolBarView_line2)
        toolBarView_line2 = [[UIView alloc]init];
    if(!toolBarView_line3)
        toolBarView_line3 = [[UIView alloc]init];
    
    toolBarView_line1.frame = [self frame_line:1 toolbarFrame:toolbarFrame];
    toolBarView_line2.frame = [self frame_line:2 toolbarFrame:toolbarFrame];
    toolBarView_line3.frame = [self frame_line:3 toolbarFrame:toolbarFrame];
    [lineViewAray addObject:toolBarView_line1];
    
    if(!CGRectEqualToRect(toolBarView_line2.frame, CGRectZero))
    {
        [lineViewAray addObject:toolBarView_line2];
    }
    if(!CGRectEqualToRect(toolBarView_line3.frame, CGRectZero))
    {
        [lineViewAray addObject:toolBarView_line3];
    }
}

-(void)changePlayerFrame:(CGRect)newFrame
{
    [_videoPlayerView setTransform:CGAffineTransformIdentity];
    [_videoPlayerView setFrame:newFrame];
    if(isToolBarAttached)
        [self setupToolbarUIForPlayerFrame:newFrame];

    if(playing && TimerForSeekBar)
    {
        [TimerForSeekBar invalidate];
        TimerForSeekBar = [NSTimer scheduledTimerWithTimeInterval:[self smoothSlider] target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
    }
}

-(void)rotateVideoView:(videoOrientation)mode
{
    CGAffineTransform theTransform = CGAffineTransformIdentity;
    switch (mode) {
        case videoOrientation_portrait:
            theTransform = CGAffineTransformIdentity;
            break;
            
        case videoOrientation_upsideDown:
            theTransform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(180));
            break;
            
        case videoOrientation_landscapeLeft:
            theTransform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(90));
            break;
            
        case videoOrientation_landscapeRight:
            theTransform = CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(270));
            break;
            
        default:
            NSLog(@"Unklnon orientation : %d", mode);
            break;
    }
    [_videoPlayerView setTransform:theTransform];
}
-(CGRect)adjustedFrameForOrientation:(videoOrientation)newOrientation
                       originalFrame:(CGRect)originalFrame
{
    CGFloat differenceInSize = CGRectGetWidth(originalFrame) - CGRectGetHeight(originalFrame);
    CGRect portraitFrame = originalFrame;
    CGRect adjustedFrame = originalFrame;
    CGPoint origin;
    CGSize size;

    switch (newOrientation)
    {
        case videoOrientation_portrait:
        case videoOrientation_upsideDown:
            adjustedFrame = portraitFrame;
            break;
            
        case videoOrientation_landscapeLeft:
        case videoOrientation_landscapeRight:
            size.height = CGRectGetWidth(portraitFrame);
            size.width  = CGRectGetHeight(portraitFrame);
            origin.x    = CGRectGetMinX(portraitFrame) + (differenceInSize/2.0);
            origin.y    = CGRectGetMinY(portraitFrame) - (differenceInSize/2.0);
            adjustedFrame.origin = origin;
            adjustedFrame.size = size;
            break;

        default:
            break;
    }
    return adjustedFrame;
}
-(void)customBtnPressed
{
    if([self.delegate respondsToSelector:@selector(DidPressCustomBtn:sender:)])
    {
        [self.delegate DidPressCustomBtn:self.customBtn sender:self];
    }
    if(self.autohideToolbar)[self hideSliderAfter:2.0];

}
#pragma mark Observer

#ifdef SUPPORT_STREAMING
/**
 *  Adds required observers to handle streaming
 */
-(void)addObservers
{
    [self.playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
    [self.player addObserver:self forKeyPath:@"status" options:0 context:nil];
}

/**
 *  removes observers attached by method addObservers
 */
-(void)removeObservers
{
    //If there are observers attached remove them.
    //Try-catch is required because removing an observer that doesnt exist will crash the app
    @try {
        [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
        [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
        [self.player removeObserver:self forKeyPath:@"status"];
    }
    @catch (NSException *exception)
    {
        NSLog(@"no observer attached");
    }
}
-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if (object == player && [keyPath isEqualToString:@"status"])
    {
        AVPlayerStatus playerStatus  = player.status;
        if (playerStatus == AVPlayerStatusFailed)
        {
            NSLog(@"AVPlayer Failed");
        }
        else if (playerStatus == AVPlayerStatusReadyToPlay)
        {
            NSLog(@"AVPlayerStatusReadyToPlay");
            if(playing)
            {
                [self play];
            }
        } else if (playerStatus == AVPlayerItemStatusUnknown) {
            NSLog(@"AVPlayer Unknown");
            
        }
    }
    else if (object == self.playerItem)
    {
        if([keyPath isEqualToString:@"playbackBufferEmpty"]) //buffer is empty, show buffering
        {
            if(self.playerItem.playbackBufferEmpty)
            {
                NSLog(@"Show Buffering");
                [activity showActivityInView:_videoPlayerView withText:@"Buffering ..."];
            }
        }
        else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"])
        {
            if (self.playerItem.playbackLikelyToKeepUp)
            {
                NSLog(@"Hide Buffering");
                [activity hideActivity];
                if(playing)
                    [self play];
            }
            
        }
        else
        {
            NSLog(@"Unhandled keyPath = %@", keyPath);
        }
    }
}
#endif
@end
