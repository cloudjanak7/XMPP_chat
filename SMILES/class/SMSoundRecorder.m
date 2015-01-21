//
//  SMSoundRecorder.m
//  SMILES
//
//  Created by asepmoels on 8/24/13.
//  Copyright (c) 2013 asepmoels. All rights reserved.
//

#import "SMSoundRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface SMSoundRecorder () <AVAudioPlayerDelegate>{
    IBOutlet UIButton *playButton;
    IBOutlet UIButton *recordButton;
    IBOutlet UIButton *cancelButton;
    IBOutlet UIButton *useButton;
    IBOutlet UIButton *retakeButton;
    IBOutlet UILabel *timerLabel;
    IBOutlet UIView *backgroundView;
    
    AVAudioRecorder *recorder;
    AVAudioPlayer *player;
    NSTimer *durationTimer;
}

-(IBAction)startStopRecord:(id)sender;
-(IBAction)startStopPlay:(id)sender;
-(IBAction)use:(id)sender;
-(IBAction)cancel:(id)sender;
-(IBAction)retake:(id)sender;

@end

@implementation SMSoundRecorder

@synthesize data, delegate;

- (void)dealloc
{
    [recorder release];
    [player release];
    [data release];
    [super dealloc];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor clearColor];
    self.view.alpha = 0.;
    [self prepare];
    
    self.view.frame = [UIScreen mainScreen].bounds;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - Action
-(void)prepare{
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *err = nil;
    
    [audioSession setCategory :AVAudioSessionCategoryPlayAndRecord error:&err];
    if(err){
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }
    
    [audioSession setActive:YES error:&err];
    err = nil;
    if(err){
        NSLog(@"audioSession: %@ %ld %@", [err domain], (long)[err code], [[err userInfo] description]);
        return;
    }

    NSString *soundFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"myRecord.wav"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    NSDictionary *recordSettings = [[NSMutableDictionary alloc] init];
    
    // We can use kAudioFormatAppleIMA4 (4:1 compression) or kAudioFormatLinearPCM for nocompression
    [recordSettings setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
    
    // We can use 44100, 32000, 24000, 16000 or 12000 depending on sound quality
    [recordSettings setValue:[NSNumber numberWithFloat:44100.0] forKey:AVSampleRateKey];
    
    // We can use 2(if using additional h/w) or 1 (iPhone only has one microphone)
    [recordSettings setValue:[NSNumber numberWithInt: 1] forKey:AVNumberOfChannelsKey];
    
    // These settings are used if we are using kAudioFormatLinearPCM format
    //[recordSetting setValue :[NSNumber numberWithInt:16] forKey:AVLinearPCMBitDepthKey];
    //[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsBigEndianKey];
    //[recordSetting setValue :[NSNumber numberWithBool:NO] forKey:AVLinearPCMIsFloatKey];
    
//    NSDictionary *recordSettings = [NSDictionary dictionaryWithObjectsAndKeys:
//                                    [ NSNumber numberWithFloat:44100.0], AVSampleRateKey,
//                                    [ NSNumber numberWithInt:1], AVNumberOfChannelsKey,
//                                    [ NSNumber numberWithInt:16], AVLinearPCMBitDepthKey,
//                                    [ NSNumber numberWithInt:kAudioFormatLinearPCM], AVFormatIDKey,
//                                    [ NSNumber numberWithBool:NO], AVLinearPCMIsFloatKey,
//                                    [ NSNumber numberWithBool:0], AVLinearPCMIsBigEndianKey,
//                                    [ NSNumber numberWithBool:NO], AVLinearPCMIsNonInterleaved,
//                                    [ NSData data], AVChannelLayoutKey, nil ];
    
    NSData *audioData = [NSData dataWithContentsOfFile:[soundFileURL path] options: 0 error:&err];
    if(audioData)
    {
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm removeItemAtPath:[soundFileURL path] error:&err];
    }

    NSError *error = nil;
    
    recorder = [[AVAudioRecorder alloc] initWithURL:soundFileURL settings:recordSettings error:&error];
    
    if (error){
        NSLog(@"error: %@", [error localizedDescription]);
    } else {
        [recorder prepareToRecord];
        recorder.meteringEnabled = YES;
    }
    
    BOOL audioHWAvailable = audioSession.inputIsAvailable;
    if (! audioHWAvailable) {
        UIAlertView *cantRecordAlert = [[UIAlertView alloc] initWithTitle: @"Warning"
                                                                  message: @"Audio input hardware not available"
                                                                 delegate: nil
                                                        cancelButtonTitle:@"OK"
                                                        otherButtonTitles:nil];
        [cantRecordAlert show];
        return;
    }
}

-(void)show{
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

-(void)showBG{
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:.5];
    self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:.85];
    [UIView commitAnimations];
}

-(void)hide{
    [UIView beginAnimations:@"" context:nil];
    [UIView setAnimationDuration:.5];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(removeMe)];
    self.view.backgroundColor = [UIColor colorWithWhite:0. alpha:.0];
    [UIView commitAnimations];
}

-(void)removeMe{
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

-(void)cancel:(id)sender{
    [self hide];
    [self startStopPlay:nil];
    [self startStopRecord:nil];
}

-(IBAction)startStopRecord:(id)sender{
    
    UIButton *button = (UIButton *)sender;
    if(!recorder.isRecording){
        timerLabel.text = @"00:00";
        [recorder record];
        button.selected = YES;
        [self startTimer];
    }else{
        [recorder stop];
        button.selected = NO;
        button.hidden = YES;
        playButton.hidden = NO;
        [self stopTimer];
        [self initiatePlayer];
    }
}

- (IBAction)startStopPlay:(id)sender {
    
    UIButton *button = (UIButton *)sender;
    if(!player.isPlaying){
        timerLabel.text = @"00:00";
        [player play];
        button.selected = YES;
        [self startTimer];
    }else{
        [self stopPlayer];
    }
}

-(void)tick{;
    if(playButton.hidden){
        timerLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int) recorder.currentTime / 60, ((int)recorder.currentTime) % 60];
    }else{
        timerLabel.text = [NSString stringWithFormat:@"%02d:%02d", (int) player.currentTime / 60, ((int)player.currentTime) % 60];
    }
}

-(void)startTimer{
    if(durationTimer)
        [self stopTimer];
    
    durationTimer = [[NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(tick) userInfo:nil repeats:YES] retain];
}

-(void)stopTimer{
    [durationTimer invalidate];
    [durationTimer release];
    durationTimer = nil;
}

-(void)initiatePlayer{
    NSString *soundFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"myRecord.wav"];
    NSURL *soundFileURL = [NSURL fileURLWithPath:soundFilePath];
    
    if(player){
        [player release];
    }
    
    NSError *error = nil;
    player = [[AVAudioPlayer alloc] initWithContentsOfURL:soundFileURL error:&error];
    player.delegate = self;
    
    useButton.hidden = NO;
    retakeButton.hidden = NO;
}

-(void)reset{
    playButton.hidden = YES;
    recordButton.hidden = NO;
    retakeButton.hidden = YES;
    playButton.selected = NO;
    recordButton.selected = NO;
    useButton.hidden = YES;
    timerLabel.text = @"00:00";
}

-(void)use:(id)sender{
    NSString *soundFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"myRecord.wav"];
    [self hide];
    
    self.data = [NSData dataWithContentsOfFile:soundFilePath];
    if(self.delegate){
        [self.delegate soundDidRecorded];
    }
}

-(void)retake:(id)sender{
    [self reset];
}

#pragma mark - delegate player
-(void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)_player successfully:(BOOL)flag{
    [self stopPlayer];
}

-(void)stopPlayer{
    [player stop];
    playButton.selected = NO;
    [self stopTimer];
}

@end
