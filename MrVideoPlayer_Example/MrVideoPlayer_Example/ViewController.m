//
//  ViewController.m
//  MrVideoPlayer_Example
//
//  Created by Roy on 18/12/14.
//  Copyright (c) 2014 InApp. All rights reserved.
//

#import "ViewController.h"

#define STREAM_ONLINE

@interface ViewController ()
{
    CGFloat width_MAX;
    CGFloat height_MAX;
}

@property (strong, nonatomic) IBOutlet UIView *videoContainerView;

@property (strong, nonatomic) IBOutlet UISlider *widthSlider;
@property (strong, nonatomic) IBOutlet UISlider *heightSlider;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self showVideo];
}
-(void)viewDidAppear:(BOOL)animated
{
    [self setupSliders];
    [self updateSliderValues];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
#pragma mark UI Methods
-(void)setupSliders
{
    CGRect videoContainerFrame = [self.videoContainerView bounds];
    
    width_MAX = CGRectGetWidth(videoContainerFrame);
    height_MAX = CGRectGetHeight(videoContainerFrame);
    
    [self.widthSlider setMinimumValue:50.0];
    [self.heightSlider setMinimumValue:70.0];
    
    [self.widthSlider setMaximumValue:width_MAX];
    [self.heightSlider setMaximumValue:height_MAX];
}

-(void)updateSliderValues
{
    if(self.myPlayer)
    {
        [self.widthSlider  setValue:CGRectGetWidth ([self.myPlayer getPlayerFrame]) animated:YES];
        [self.heightSlider setValue:CGRectGetHeight([self.myPlayer getPlayerFrame]) animated:YES];
    }
}
#pragma mark Internal Methods
-(void)initPlayer
{
    if(!self.myPlayer)
    {
        self.myPlayer = [[MrVideoPlayer alloc]init];
        [self.myPlayer setDelegate:self];
    }
}
-(void)showVideo
{
    [self initPlayer];
#ifdef STREAM_ONLINE
    NSURL *streamUrl = [NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"];
    [self.myPlayer setURL:streamUrl];
#else
#endif
    [self.myPlayer setMuteUnbuteButtonVisible:YES];
    [self.myPlayer displayPlayerinView:self.videoContainerView inframe:CGRectMake(0, 0, 300, 300)];
    [self.myPlayer setBackgroundColorforPlayer:[UIColor colorWithWhite:0.9 alpha:0.85]];
    [self.myPlayer customiseToolbarViewWithBackgroundColour:[UIColor colorWithWhite:0.2 alpha:0.8] borderThickness:1.0 borderColor:[UIColor blackColor] cornerRadius:3];
    [self.myPlayer setAutohideToolbar:YES];
}
#pragma mark MrVideoPlayerDelegate
-(void)playerDidPlayToEnd:(id)sender
{
    
}

#pragma mark - IBOutlet Methods
- (IBAction)randomiseBtnAction:(id)sender
{
}

- (IBAction)pBtnAction:(id)sender
{
    [self.myPlayer setOrinetation:videoOrientation_portrait];
}
- (IBAction)UDBtnAction:(id)sender
{
    [self.myPlayer setOrinetation:videoOrientation_upsideDown];
}
- (IBAction)LandscapeLeftBtnAction:(id)sender
{
    [self.myPlayer setOrinetation:videoOrientation_landscapeLeft];
}
- (IBAction)LandscapeRightBtnAction:(id)sender
{
    [self.myPlayer setOrinetation:videoOrientation_landscapeRight];
}

- (IBAction)widthSliderValueChanged:(id)sender
{
    CGRect mFrame = [self.myPlayer getPlayerFrame];
    mFrame.size.width =  [(UISlider *)sender value];
    [self.myPlayer changePlayerFrametoFrame:mFrame animated:NO];
}

- (IBAction)heightSliderValueChanged:(id)sender
{
    CGRect mFrame = [self.myPlayer getPlayerFrame];
    mFrame.size.height =  [(UISlider *)sender value];
    [self.myPlayer changePlayerFrametoFrame:mFrame animated:NO];
}
#pragma mark - Touches
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [[event allTouches] anyObject];
    CGPoint touchLocation = [touch locationInView:self.videoContainerView];
        if (CGRectContainsPoint(self.videoContainerView.frame, touchLocation))
        {
            [self.myPlayer showSlider];
            [self.myPlayer hideSliderAfter:2.0];
        }
}
@end
