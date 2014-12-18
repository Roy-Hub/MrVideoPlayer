//
//  playerView.m
//  VideoPlayer
//
//  Created by Roy on 04/03/14.
//  Copyright (c) 2014 InApp Inc. All rights reserved.
//

#import "playerView.h"
#import <AVFoundation/AVFoundation.h>


@implementation playerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
+ (Class)layerClass {
    return [AVPlayerLayer class];
}

-(AVPlayer *) player{
    return [(AVPlayerLayer *)[self layer] player];
}
- (void)setPlayer:(AVPlayer*)player {
    [(AVPlayerLayer*)[self layer] setPlayer:player];
}

- (void)setVideoFillMode:(NSString *)fillMode
{
    AVPlayerLayer *playerLayer = (AVPlayerLayer*)[self layer];
    playerLayer.videoGravity = fillMode;
}

@end
