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
@property (strong, nonatomic) IBOutlet UIView *toolbarView;

@property (strong, nonatomic) IBOutlet UISlider *widthSlider;
@property (strong, nonatomic) IBOutlet UISlider *heightSlider;

@property (strong, nonatomic) IBOutlet UIButton *attachToolbarBtn;
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
    
    [self.widthSlider setMinimumValue:90.0];
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

-(void)toggleToolbarDetach
{
    BOOL attached = [self.myPlayer isToolbarAttachedToPlayer];
    if(attached)
    {
        [self.myPlayer detatchToolbarFromPlayer:YES];
        UIView *toolBarView = [self.myPlayer gettoolbarViewForToolBarFrame:self.toolbarView.bounds];
        [self.toolbarView addSubview:toolBarView];
        [self.videoContainerView bringSubviewToFront:self.toolbarView];
    }
    else
    {
        [self.myPlayer detatchToolbarFromPlayer:NO];
    }
}

-(UIColor *)getRandomColour
{
    CGFloat red   = (CGFloat)(arc4random() % 256) / 256.0;
    CGFloat blue  = (CGFloat)(arc4random() % 256) / 256.0;
    CGFloat green = (CGFloat)(arc4random() % 256) / 256.0;
    CGFloat alpha = (CGFloat)(arc4random() % 256) / 256.0;
    NSLog(@"r = %f, g = %f, b = %f, a = %f", red,green,blue,alpha);
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}
#pragma mark MrVideoPlayerDelegate
-(void)playerDidPlayToEnd:(id)sender
{
    NSLog(@"Player played till end");
    [self.myPlayer play]; //Playing video again when video ends (Playing in loop)
}

-(void)playerShouldPause
{
    [self.myPlayer pause];
}
#pragma mark - IBOutlet Methods
- (IBAction)randomiseBtnAction:(id)sender
{
    int randWidth  = 100 + arc4random() % (int)width_MAX;
    int randHeight = 80 + arc4random() % (int)height_MAX;
    [self.myPlayer changePlayerFrametoFrame:CGRectMake(0, 0, randWidth, randHeight) animated:YES];
    [self.widthSlider setValue:randWidth];
    [self.heightSlider setValue:randHeight];
    [self.myPlayer setBackgroundColorforPlayer:[self getRandomColour]];
    
    [self.myPlayer customiseToolbarViewWithBackgroundColour:[self getRandomColour]
                                                borderThickness:1.0
                                                    borderColor:[self getRandomColour]
                                                   cornerRadius:arc4random() % 10];

}
- (IBAction)attachToolbarBtnAction:(id)sender
{
        BOOL attached = [self.myPlayer isToolbarAttachedToPlayer];
        NSString *titleStr = attached?@"Attach ToolBar":@"Detach Toolbar";
        [self.attachToolbarBtn setTitle:titleStr forState:UIControlStateNormal];
    [self toggleToolbarDetach];
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
