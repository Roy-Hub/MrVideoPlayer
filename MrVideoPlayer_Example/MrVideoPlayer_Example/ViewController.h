//
//  ViewController.h
//  MrVideoPlayer_Example
//
//  Created by Roy on 18/12/14.
//  Copyright (c) 2014 InApp. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MrVideoPlayer.h"
@interface ViewController : UIViewController<MrVideoPlayerDeligate>
@property (strong,nonatomic)MrVideoPlayer *myPlayer;
@end

