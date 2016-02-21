//
//  GameViewController.m
//  HeadsUpper
//
//  Created by Diana Elezaj on 2/21/16.
//  Copyright © 2016 Michael Kavouras. All rights reserved.
//

#import "GameViewController.h"
#import "ZoomInOutAnimation.h"
#import <AVFoundation/AVFoundation.h>

@interface GameViewController ()
@property (weak, nonatomic) IBOutlet UIView *cameraView;
@property (nonatomic) NSInteger timerCount;
@property (nonatomic) NSInteger getReadyTimerCount;
@property (weak, nonatomic) IBOutlet UIView *getReadyView;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *guessItLabel;
@property (nonatomic) NSInteger pointsTotal;
@property (nonatomic) NSMutableArray *generatedNumbers;
@property (nonatomic) NSTimer *readyTimer;
@property (nonatomic) NSTimer *startGameTimer;

@end

@implementation GameViewController

#pragma mark - Lifecycle methods

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.title = self.selectedCategory [@"title"];
    [self setupGestureRecognizer];
    [self getReadyTimer];
    [self startLiveVideo];
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.timeLabel.hidden = YES;
    
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(deviceOrientationDidChangeNotification:)
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
    [_readyTimer invalidate];
    [_startGameTimer invalidate];
}

-(void)startLiveVideo{
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        AVCaptureSession *session = [[AVCaptureSession alloc] init];
        session.sessionPreset = AVCaptureSessionPresetHigh;
        
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
        NSError *error = nil;
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        [session addInput:input];
        
        AVCaptureVideoPreviewLayer *newCaptureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
        newCaptureVideoPreviewLayer.frame = self.cameraView.bounds;
        
        [self.cameraView.layer addSublayer:newCaptureVideoPreviewLayer];
        
        [session startRunning];
        
    }
}

#pragma mark - Get Ready

-(void)getReadyTimer{
    
    [ZoomInOutAnimation pulseView:self.getReadyView from:1.0 to:2.5 withDuration:0.5 repeats:CGFLOAT_MAX];

    _readyTimer =  [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(getReadyTimerFired:) userInfo:nil repeats:YES];
    self.getReadyTimerCount = 5;
    [_readyTimer fire];
    [[NSRunLoop currentRunLoop] addTimer:_readyTimer forMode:NSRunLoopCommonModes];
}

-(void)getReadyTimerFired:(NSTimer *)timer{
    
    self.getReadyTimerCount --;
    NSString *convertedString = [[NSNumber numberWithInteger:self.getReadyTimerCount] stringValue];
    if (self.getReadyTimerCount < 4) {
    self.guessItLabel.text = convertedString;
    }
    else {
        self.guessItLabel.text = @"Get Ready!";
    }
    if (self.getReadyTimerCount == 0) {
        [timer invalidate];
        [ZoomInOutAnimation stopZoomingView:self.getReadyView];
        [self startGame];
    }
}

#pragma mark - Start Game

-(void)startGame{
    self.timeLabel.hidden = NO;
    self.pointsTotal = 0;
    self.guessItLabel.text = self.subjectsArray[[self generateRandomNumber]];
    [self setupTimer];
}

-(void)setupTimer{
    
    _startGameTimer =  [NSTimer timerWithTimeInterval:1.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
    
    self.timerCount = 9;
    [_startGameTimer fire];
    
    [[NSRunLoop currentRunLoop] addTimer:_startGameTimer forMode:NSRunLoopCommonModes];
}

-(void)timerFired:(NSTimer *)timer{
 
    self.timerCount --;
    if (self.timerCount == 0) {
         [timer invalidate];
        [self gamesOverAlertView];
    }
    
    NSString *convertedString = [[NSNumber numberWithInteger:self.timerCount] stringValue];
    self.timeLabel.text = convertedString;
    
}

#pragma mark - Gesture Recognizers

-(void)setupGestureRecognizer{
    
    UISwipeGestureRecognizer *leftSwipeSkip = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    leftSwipeSkip.direction = UISwipeGestureRecognizerDirectionLeft;
    
    UISwipeGestureRecognizer *rightSwipeCorrect = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipe:)];
    
    rightSwipeCorrect.direction = UISwipeGestureRecognizerDirectionRight;
    
    [self.view addGestureRecognizer:leftSwipeSkip];
    [self.view addGestureRecognizer:rightSwipeCorrect];
    
}

-(void)handleSwipe:(UISwipeGestureRecognizer *)gesture {
    if (self.timerCount != 0) {
        switch (gesture.direction) {
            case UISwipeGestureRecognizerDirectionLeft:
                [self skipIt];
                break;
                
            case UISwipeGestureRecognizerDirectionRight:
                [self correctAnswer];
                break;
                
            default:
                break;
        }
    }
}

-(void)correctAnswer{
    [self animateViewWithColor:[UIColor greenColor]];
    self.guessItLabel.text = self.subjectsArray[[self generateRandomNumber ]];
    self.pointsTotal ++;
}

-(void)skipIt{
    [self animateViewWithColor:[UIColor redColor]];
    self.guessItLabel.text = self.subjectsArray[[self generateRandomNumber]];
}

- (void)deviceOrientationDidChangeNotification:(NSNotification*)note
{
    if (self.timerCount != 0) {
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        //Face Up
        if (orientation == UIDeviceOrientationFaceDown)
        {
            [self correctAnswer];
        }
        // Face down
        else if (orientation == UIDeviceOrientationFaceUp)
        {
            [self skipIt];
        }
    }
}

#pragma mark - Animations

-(void)animateViewWithColor:(UIColor *)color {
    [UIView animateWithDuration:0 animations:^{
        self.view.backgroundColor = color;
    }];
    [UIView animateWithDuration:0.35 animations:^{
        self.view.backgroundColor = [UIColor whiteColor];
    }];
}

#pragma mark - Alert View

-(void)gamesOverAlertView{
    
    NSString *message = [NSString stringWithFormat:@"%ld/%ld",(long)self.pointsTotal, (long)self.generatedNumbers.count-1];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Game's over"
                                                message:message
                                               delegate:self
                                      cancelButtonTitle:@"OK"
                                      otherButtonTitles:nil];
        [alert show];

}

-(NSInteger) generateRandomNumber {
    NSInteger randomNumber = (NSInteger) arc4random_uniform(self.subjectsArray.count-2); //because the last one shouldn't be counted
    if ([self.mutableArrayContainingNumbers containsObject: [NSNumber numberWithInteger:randomNumber]]) {
        [self generateRandomNumber];
    } else {
        [self.mutableArrayContainingNumbers addObject: [NSNumber numberWithInteger:randomNumber]];
    }
    return randomNumber;
}


-(NSMutableArray *) mutableArrayContainingNumbers
{
    if (!_generatedNumbers)
        _generatedNumbers = [[NSMutableArray alloc] init];
    
    return _generatedNumbers;
}



@end
