//
//  SMSoundPlayer.m
//  SMILES
//
//  Created by wang chenglei on 3/28/14.
//  Copyright (c) 2014 asepmoels. All rights reserved.
//

#import "SMSoundPlayer.h"
#import <AVFoundation/AVFoundation.h>

@interface SMSoundPlayer () <AVAudioPlayerDelegate>
{
    IBOutlet UILabel *playedTime;
    IBOutlet UILabel *remainTime;
    IBOutlet UISlider *timeSlider;
    IBOutlet UIButton *playButton;
    IBOutlet UIButton *stopButton;

    AVAudioPlayer *m_audioPlayer;
    NSTimer *m_soundTimer;
}

- (IBAction)doPlaySound:(id)sender;
- (IBAction)doStopSound:(id)sender;
- (IBAction)doCancel:(id)sender;

@end

@implementation SMSoundPlayer

@synthesize soundData;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.

    self.view.backgroundColor = [UIColor clearColor];
    self.view.alpha = 0.;
    self.view.frame = [UIScreen mainScreen].bounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)doPlaySound:(id)sender {
    
    if (m_audioPlayer == nil) {
        return;
    }
    
    if (m_audioPlayer.isPlaying) {
        // pause player
        [m_audioPlayer pause];
        [playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    } else {
        // play player
        [m_audioPlayer play];
        [playButton setImage:[UIImage imageNamed:@"pause.png"] forState:UIControlStateNormal];
        [stopButton setEnabled:YES];
        
        if (m_soundTimer == nil) {
            m_soundTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updatePlayTime) userInfo:nil repeats:YES];
        }
    }
}

- (IBAction)doStopSound:(id)sender {

    if (m_audioPlayer) {
        [m_audioPlayer stop];
        m_audioPlayer.currentTime = 0;
    }
    
    if (m_soundTimer) {
        [m_soundTimer invalidate];
        m_soundTimer = nil;
    }
    
    [timeSlider setValue: 0 animated: YES];
    [playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    [stopButton setEnabled:NO];
    [playedTime setText:@"00:00"];
    [remainTime setText:[NSString stringWithFormat:@"-%@", [self getStringFromTimeLength:m_audioPlayer.duration]]];
}

- (IBAction)doCancel:(id)sender {
    
    [self hide];

    if (m_soundTimer) {
        [m_soundTimer invalidate];
        m_soundTimer = NULL;
    }
    
    if (m_audioPlayer) {
        [m_audioPlayer stop];
        m_audioPlayer = nil;
    }
}

- (void)reset {
    NSError *error = nil;
    m_audioPlayer = [[AVAudioPlayer alloc] initWithData:soundData error:&error];
    m_audioPlayer.delegate = self;
    
    [playedTime setText:@"00:00"];
    [remainTime setText:[NSString stringWithFormat:@"-%@", [self getStringFromTimeLength:m_audioPlayer.duration]]];
    [timeSlider setValue:0];
    [timeSlider setMinimumValue:0];
    [timeSlider setMaximumValue:m_audioPlayer.duration];
    
    if (m_soundTimer == nil) {
        m_soundTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f target:self selector:@selector(updatePlayTime) userInfo:nil repeats:YES];
    }
    
    [timeSlider addTarget:self action:@selector(startPlayTimeDrag:) forControlEvents:UIControlEventTouchDown];
    [timeSlider addTarget:self action:@selector(updatePlayTimeThumb:) forControlEvents:UIControlEventValueChanged];
    [timeSlider addTarget:self action:@selector(endPlayTimeDrag:) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    [playButton setImage:[UIImage imageNamed:@"play.png"] forState:UIControlStateNormal];
    [stopButton setImage:[UIImage imageNamed:@"stop.png"] forState:UIControlStateNormal];
    [stopButton setEnabled:NO];
    
    [self doPlaySound:nil];
}

- (NSString*) getStringFromTimeLength: (float) length
{
    int minutes = (int) floor(length / 60);
    int seconds = (int) length - (minutes * 60);
    
    NSString* strMinutes = [NSString stringWithFormat: @"%.2d", minutes];
    NSString* strSeconds = [NSString stringWithFormat: @"%.2d", seconds];
    
    NSString *strTime = [NSString stringWithFormat: @"%@:%@", strMinutes, strSeconds];
    return strTime;
}

- (void)updatePlayTime
{
    if([m_audioPlayer isPlaying])
    {
        NSString* strPlayedTime = [self getStringFromTimeLength:m_audioPlayer.currentTime];
        
        float fRemainTime = m_audioPlayer.duration - m_audioPlayer.currentTime;
        NSString* strRemainTime = [NSString stringWithFormat: @"-%@", [self getStringFromTimeLength: fRemainTime]];
        
        [timeSlider setValue: m_audioPlayer.currentTime animated:YES];
        [playedTime setText: strPlayedTime];
        [remainTime setText: strRemainTime];
    }
}

- (void)show {
    
    CGRect frame = self.view.frame;
    frame.origin.y = 100;
    
    self.view.alpha = 0.;
    self.view.frame = frame;
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.25];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(showBG)];
    
    frame.origin.y = 0;
    self.view.frame = frame;
    self.view.alpha = 1.0;
    
    [UIView commitAnimations];
}

- (void)showBG {
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:.5];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:.85];
    
    [UIView commitAnimations];
}

- (void)hide {
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:.5];
    
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(removeMe)];
    
    self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:.0];
    
    [UIView commitAnimations];
}

- (void)removeMe {
    
    CGRect frame = self.view.frame;
    
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:0.25];
    
    [UIView setAnimationDelegate:self.view];
    [UIView setAnimationDidStopSelector:@selector(removeFromSuperview)];
    
    frame.origin.y = 100;
    self.view.frame = frame;
    self.view.alpha = .0;
    
    [UIView commitAnimations];
}

#pragma mark - Slider operation

- (void)startPlayTimeDrag:(id)sender {
    
    if (m_audioPlayer == nil) {
        return;
    }
    
    if (m_audioPlayer.isPlaying) {
        [self doStopSound:nil];
    }
}

- (void)updatePlayTimeThumb:(id)sender {
    
    if (m_audioPlayer == nil) {
        return;
    }
    
    UISlider *slider = (UISlider *)sender;
    float newPlayTime = slider.value;
    [playedTime setText:[self getStringFromTimeLength:newPlayTime]];
    
    float remainPlayTime = m_audioPlayer.duration-newPlayTime;
    if (remainPlayTime < 0) remainPlayTime = 0;
    [remainTime setText:[NSString stringWithFormat:@"-%@", [self getStringFromTimeLength:remainPlayTime]]];
    
    timeSlider.value = newPlayTime;
    [m_audioPlayer setCurrentTime:newPlayTime];
}

- (void)endPlayTimeDrag:(id)sender {
    
    if (m_audioPlayer == nil) {
        return;
    }
    
    [self doPlaySound:nil];
}

- (void)updateVolumeThumb:(id)sender {
    
}

#pragma mark - AVAudioPlayerDelegate

-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    [self doStopSound:nil];
}

@end
