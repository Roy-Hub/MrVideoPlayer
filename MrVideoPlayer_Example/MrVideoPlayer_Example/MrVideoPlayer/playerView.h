//
//  playerView.h
//  VideoPlayer
//
//  Created by Roy on 04/03/14.
//  Copyright (c) 2014 InApp Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@class AVPlayer;

@interface playerView : UIView

@property(nonatomic, strong) AVPlayer * player;

- (AVPlayer *) player;
- (void)setPlayer:(AVPlayer*)player;
- (void)setVideoFillMode:(NSString *)fillMode;

@end
