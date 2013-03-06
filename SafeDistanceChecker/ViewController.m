//
//  ViewController.m
//  SafeDistanceChecker
//
//  Created by RyusukeHotta on 13/03/01.
//  Copyright (c) 2013年 RyusukeHotta. All rights reserved.

// for SmartTech award 2013
//
#include <stdio.h>
#include <stdlib.h>
#import "ViewController.h"
#import "CommunicateWithCar.h"

//NSString * const kServerURL = @"ws://192.168.7.102:10001/ws/";

#define CHECK_NUM   3
#define DEFAULT_MU  0.65     //ミューのデフォルト値
#define RAIN_MU     0.45     //ミュー（雨）

#define MYCAR_HEIGHT 197
#define MYCAR_POS   120

typedef enum
{
    DistanceCheckModeNotStart =0,
    DistanceCheckModeReady,
    DistanceCheckModeWaitForGreen,
    DistanceCheckModeWaitForPush,
    DistanceCheckModeStop,
    
    DistanceCheckModeFinished,
}DistanceCheckMode;

@interface ViewController ()<CommunicateWithCarDelegate>

@end

@implementation ViewController
{
    CommunicateWithCar* _car;
    UIView* _initView;
    UITextField* _address;
    UITextField* _port;
    UIButton* _btn;
    
    int _checkCount;
    DistanceCheckMode _mode;
    
    UIImageView* _bgImageView;
    UIImageView* _bgImageView_rain;
    
    UIImageView* _checkModeImage;
    NSDate *_startDate;
    
    UITextField* _textField[3];
    UITextField* _textFieldAverage;
    
    NSTimeInterval _timeSum;
    
    double _safetyDistance;
    double _obstacleDistance;
    
    UIImageView* _idleRunningDistanceBar;
    UIImageView* _safetyDistanceBar;
    UIImageView* _baseDistanceBar;
    //
    UILabel* _labelSpeed;
    
    UILabel* _labelIdleDistance;
    UILabel* _labelSafetyDistance;
    
    UIImageView* _imageCar;
    UIImageView* _imageObstacle;
    
    UIImageView* _imageWarn;
    
    CGFloat _mu;
}
- (void)startCheck
{
    
    [_checkModeImage setImage:[UIImage imageNamed:@"c2"]];
    _mode = DistanceCheckModeWaitForGreen;
    
    srand(time(nil));
    int add = rand() % 300;
    
    [self performSelector:@selector(tapWait:) withObject:nil afterDelay:1.0f + (float)add/100.0f];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if(_mode == DistanceCheckModeReady)
    {
        _timeSum= 0.0;
        [self startCheck];
    }
}

- (void)didBrakeDown {
   //CGPoint location = [[touches anyObject] locationInView:self.view];
   
    
    if(_mode == DistanceCheckModeWaitForPush)
    {
        
        NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:_startDate];
        _timeSum += interval;
        _textField[_checkCount].text = [NSString stringWithFormat:@"%d: %dms",_checkCount+1,(int)(interval*1000)];
        [_startDate release];
        
        _textFieldAverage.text = [NSString stringWithFormat:@"Average: %dms",(int)((_timeSum/(double)(_checkCount+1))*1000)];
        

        [_checkModeImage setImage:[UIImage imageNamed:@"c4"]];
        _mode = DistanceCheckModeStop;
        _checkCount ++;
    }
    
    
    
}
- (void)didBrakeUp
{
    if(_mode == DistanceCheckModeStop)
    {
        if(_checkCount <CHECK_NUM){
            //[_checkModeImage setImage:[UIImage imageNamed:@"c1"]];
            _mode = DistanceCheckModeReady;
            
            [self startCheck];
        }else{
            _mode = DistanceCheckModeFinished;
            
            
            _bgImageView = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"base"]] autorelease];
            _bgImageView_rain = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"base_rain"]] autorelease];
            _bgImageView_rain.alpha = 0.0f;
            [self.view addSubview:_bgImageView];
            [self.view addSubview:_bgImageView_rain];
            
            UIImageView* barBase = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_base"]] autorelease];
            barBase.frame = CGRectMake(0, 220, barBase.frame.size.width, barBase.frame.size.height);
            
            [self.view addSubview:barBase];
            
            
            _idleRunningDistanceBar = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_orange"]] autorelease];
            _safetyDistanceBar = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_red"]] autorelease];
            _baseDistanceBar= [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bar_back"]] autorelease];
            
            [barBase addSubview:_safetyDistanceBar];
            [barBase addSubview:_idleRunningDistanceBar];
            [barBase addSubview:_baseDistanceBar];
            
            
            _imageObstacle = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"obstacle"]] autorelease];
            _imageObstacle.center = CGPointMake(-300,MYCAR_HEIGHT);
            [self.view addSubview:_imageObstacle];
            
            _imageCar = [[[UIImageView alloc] initWithImage:[UIImage imageNamed:@"car"]] autorelease];
            _imageCar.center = CGPointMake(1500,MYCAR_HEIGHT);
            [self.view addSubview:_imageCar];
            
            
            //start meter
            _labelSpeed = [[[UILabel alloc] initWithFrame:CGRectMake(0, 0, 95, 70)] autorelease];
            _labelSpeed.font = [UIFont systemFontOfSize:40];
            _labelSpeed.textColor = [UIColor whiteColor];
            _labelSpeed.backgroundColor = [UIColor clearColor];
            _labelSpeed.shadowColor = [UIColor lightGrayColor];
            _labelSpeed.shadowOffset = CGSizeMake(0.f, 1.f);
            _labelSpeed.textAlignment = NSTextAlignmentRight;
            
            _labelIdleDistance = [[[UILabel alloc] initWithFrame:CGRectMake(35, 0, 70, 30)] autorelease];
            _labelIdleDistance.font = [UIFont systemFontOfSize:20];
            _labelIdleDistance.textColor = [UIColor whiteColor];
            _labelIdleDistance.backgroundColor = [UIColor clearColor];
            _labelIdleDistance.shadowColor = [UIColor lightGrayColor];
            _labelIdleDistance.shadowOffset = CGSizeMake(0.f, 1.f);
            [_idleRunningDistanceBar addSubview:_labelIdleDistance];
            
            _labelSafetyDistance = [[[UILabel alloc] initWithFrame:CGRectMake(35, 0, 70, 30)] autorelease];
            _labelSafetyDistance.font = [UIFont systemFontOfSize:20];
            _labelSafetyDistance.textColor = [UIColor whiteColor];
            _labelSafetyDistance.backgroundColor = [UIColor clearColor];
            _labelSafetyDistance.shadowColor = [UIColor lightGrayColor];
            _labelSafetyDistance.shadowOffset = CGSizeMake(0.f, 1.f);

            [_safetyDistanceBar addSubview:_labelSafetyDistance];
            
            [self.view addSubview:_labelSpeed];
            
            
            [self setBarPosition:60];
            
            
            [UIView animateWithDuration:0.3 animations:^{
                _checkModeImage.alpha = 0.0f;
                CGRect rect = _imageCar.frame;
                CGRect screenRect = [UIScreen mainScreen].bounds;
                rect.origin.x = screenRect.size.height - MYCAR_POS;
                _imageCar.frame = rect;
                
                
            }completion:^(BOOL finished){
                
                [_checkModeImage removeFromSuperview];
                _checkModeImage = nil;
                
            }];
            
        }
    }
}



#define IMAGE_LEFT_MARGIN   38
#define MAX_DISTANCE    120

- (void)setBarPosition:(NSInteger)speed
{
    
    

    
    
    if(!_idleRunningDistanceBar || !_safetyDistanceBar ||!_baseDistanceBar) return;
    
    CGFloat distIdle;
    CGFloat distSafety;
    
    

    
    //空走距離 ＝ 反応時間 × 制動前の車速
    double checkTime = ((_timeSum/(double)(_checkCount+1)));
    double reactionTime;
#define MIN_CHECK_TIME  0.4
#define MAX_CHECK_TIME  1.0
#define MIN_REACTION_TIME   0.75
#define MAX_REACTION_TIME   1.5
    
    if(checkTime < MIN_CHECK_TIME){
        reactionTime = MIN_REACTION_TIME;
    }else if(checkTime > MAX_CHECK_TIME){
        reactionTime = MAX_REACTION_TIME;
    }else
    {
        reactionTime = MIN_REACTION_TIME + (checkTime-MIN_CHECK_TIME) / (MAX_REACTION_TIME - MIN_REACTION_TIME);
    }
    distIdle = reactionTime * (speed * 1000.0 / 3600.0);
    
    
    //制動前の時速[km/h] ^2 ÷（２５４×μ）
    distSafety = distIdle + (float)speed * (float)speed / (254.0 * _mu);
    _safetyDistance = distSafety;
    
    _labelIdleDistance.text = [NSString stringWithFormat:@"%dm",(int)distIdle];
    _labelSafetyDistance.text = [NSString stringWithFormat:@"%dm",(int)distSafety];
    
    if(distIdle > MAX_DISTANCE) distIdle = MAX_DISTANCE;
    if(distSafety > MAX_DISTANCE) distSafety = MAX_DISTANCE;
    
    
    CGRect rectDistanceBar = _idleRunningDistanceBar.frame;
    CGRect rectSafetyDistaneBar = _safetyDistanceBar.frame;
    CGRect rectBaseDistanceBar = _baseDistanceBar.frame;
    

    //NSLog(@"distSafety=%f distIdle=%f reactionTime=%f",distSafety,distIdle,reactionTime);

    CGFloat leftMarginPos = 10;
    CGFloat rightMarginPos = [UIScreen mainScreen].bounds.size.height  - MYCAR_POS;
    CGFloat distanceWidth = rightMarginPos - leftMarginPos;
    
   // NSLog(@"rightMarginPos=%lf leftMarginPos=%lf",rightMarginPos,leftMarginPos);

    
    
    
    rectDistanceBar.origin.x = rightMarginPos - distanceWidth*( distIdle / (float)MAX_DISTANCE) - IMAGE_LEFT_MARGIN;
    rectSafetyDistaneBar.origin.x = rightMarginPos - distanceWidth*(distSafety / (float)MAX_DISTANCE) - IMAGE_LEFT_MARGIN;
    rectBaseDistanceBar.origin.x = rightMarginPos;
    
    
    
    [UIView animateWithDuration:0.1 animations:^{
        _idleRunningDistanceBar.frame = rectDistanceBar;
        _safetyDistanceBar.frame = rectSafetyDistaneBar;
        _baseDistanceBar.frame = rectBaseDistanceBar;
        
        
        if(distIdle < 10){
            _labelIdleDistance.alpha = 0.0f;
        }else{
            _labelIdleDistance.alpha = 1.0f;
        }
        if(distSafety < 20){
            _labelSafetyDistance.alpha = 0.0f;
        }else{
            _labelSafetyDistance.alpha = 1.0f;
        }
    }];
    
    [self checkObstacle];
    
}

- (void)setObstaclePosition:(NSInteger)obstacle
{
    
    
    CGFloat leftMarginPos = 10;
    CGFloat rightMarginPos = [UIScreen mainScreen].bounds.size.height  - MYCAR_POS;
    CGFloat distanceWidth = rightMarginPos - leftMarginPos;
    
    CGRect rect = _imageObstacle.frame;
    rect.origin.x = rightMarginPos - distanceWidth*( (float)(obstacle) / (float)MAX_DISTANCE) - rect.size.width;
    [UIView animateWithDuration:0.3 animations:^{
        _imageObstacle.frame = rect;
    }];
    
    _obstacleDistance = obstacle;
    [self checkObstacle];
    
    
    
    
}

- (void)checkObstacle
{
    if(_safetyDistance > _obstacleDistance)
    {
        if(_imageWarn == nil)
        {
            UIImage* image1 = [UIImage imageNamed:@"warn"];
            UIImage* image2 = [UIImage imageNamed:@"warn2"];
            _imageWarn = [[[UIImageView alloc] init] autorelease];
            _imageWarn.frame = CGRectMake(0,0,image1.size.width,image1.size.height);
            
            _imageWarn.animationImages = [NSArray arrayWithObjects:image1,image2, nil];
            _imageWarn.animationDuration = 0.5;
            _imageWarn.animationRepeatCount = 0;
            CGRect screenRect = [UIScreen mainScreen].bounds;
            _imageWarn.center = CGPointMake((screenRect.size.height/2.0),100);
            [_imageWarn startAnimating];
            [self.view addSubview:_imageWarn];
        }
    }else{
        if(_imageWarn)
        {
            [_imageWarn removeFromSuperview];
            _imageWarn = nil;
        }
        
        
    }
}

- (void)tapWait:(id)obj
{
    
    if(_mode == DistanceCheckModeWaitForGreen)
    {
        [_checkModeImage setImage:[UIImage imageNamed:@"c3"]];
        _mode = DistanceCheckModeWaitForPush;
        _startDate = [[NSDate date] retain];
    }
}


- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [UIApplication sharedApplication].idleTimerDisabled = YES;
    
    
    _mu = DEFAULT_MU;
    _obstacleDistance = 1000;

    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
    CGRect screenRect = [UIScreen mainScreen].bounds;
    
    UIImage *image = [UIImage imageNamed:@"c1"];
    _checkModeImage = [[[UIImageView alloc] initWithImage:image] autorelease];
    _checkModeImage.userInteractionEnabled = NO;
    _checkModeImage.center = CGPointMake(screenRect.size.height/2,screenRect.size.width/2);
    
    CGFloat leftPadding=0;
    if(screenRect.size.height <= 480){
        leftPadding = 44.0;
    
    }
    
    
    for(int i=0;i<CHECK_NUM;i++){
        _textField[i] = [[[UITextField alloc] initWithFrame:CGRectMake(10+leftPadding, 120+i*30, 300, 50)] autorelease];
        _textField[i].font = [UIFont systemFontOfSize:15];
        _textField[i].text = [NSString stringWithFormat:@"%d: 未測定",i];
        [_checkModeImage addSubview:_textField[i]];
    }
    _textFieldAverage = [[[UITextField alloc] initWithFrame:CGRectMake(10+leftPadding, 120+100, 300, 50)] autorelease];
    _textFieldAverage.font = [UIFont systemFontOfSize:15];
    [_checkModeImage addSubview:_textFieldAverage];

    [self.view addSubview:_checkModeImage];
    
    [self newConnection];
    

}

- (void)newConnection
{
    CGRect screenRect = [UIScreen mainScreen].bounds;
    
    if(_initView)
    {
        [_initView removeFromSuperview];
        
        
    }
    _initView= [[UIView alloc] initWithFrame:CGRectMake(0,0, screenRect.size.height, screenRect.size.width) ];
    
    _initView.userInteractionEnabled = YES;
    _initView.backgroundColor = [UIColor whiteColor];
    
    
    _btn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [_btn addTarget:self action:@selector(onInitDoneBtn:) forControlEvents:UIControlEventTouchUpInside];
    _btn.frame = CGRectMake( screenRect.size.height/2-100 , 100,200,50);
    [_btn setTitle:@"接続" forState:UIControlStateNormal];
    
    _address = [[UITextField alloc] initWithFrame:CGRectMake(screenRect.size.height/2-150, 40, 200, 35)];
    _port = [[UITextField alloc] initWithFrame:CGRectMake(screenRect.size.height/2+55, 40, 70, 35)];
    
    _address.borderStyle = UITextBorderStyleBezel;
    _port.borderStyle = UITextBorderStyleBezel;
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    NSString* address = [ud objectForKey:@"address"];
    NSNumber* port = [ud objectForKey:@"port"];
    if(!address) address = @"192.168.1.103";
    if(!port) port = [NSNumber numberWithInt:10001];
    
    
    _address.text = address;
    _port.text = [NSString stringWithFormat:@"%d",port.intValue];
    
    _address.keyboardType = UIKeyboardTypeURL;
    _port.keyboardType = UIKeyboardTypeNumberPad;
    
    
    
    [_initView addSubview:_btn];
    
    [_initView addSubview:_address];
    [_initView addSubview:_port];
    
    [self.view addSubview:_initView];
    [_initView release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationLandscapeRight
            || interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
}

- (BOOL) shouldAutorotate {
    return YES;
}

// サポートする回転方向を返す
- (NSInteger) supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}


- (void)onInitDoneBtn:(id)sender
{
    
    
    UIActivityIndicatorView *ai = [[[UIActivityIndicatorView alloc] init] autorelease];
    ai.frame = CGRectMake(0, 0, 50, 50);
    ai.center = _initView.center;
    ai.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    [_initView addSubview:ai];
    
    [ai startAnimating];
    
    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:_address.text forKey:@"address"];
    [ud setObject:[NSNumber numberWithInt:[_port.text intValue]] forKey:@"port"];
    [ud synchronize];
    
    if(_car)
    {
        [_car release];
    }
    NSString* url = [NSString stringWithFormat:@"ws://%@:%@/ws/",_address.text,_port.text];
    _car = [[CommunicateWithCar alloc] init];
    _car.delegate = self;
    [_car startWithURL:url];
    
    
    [_btn removeFromSuperview];
    _btn = nil;
    [_address removeFromSuperview];
    _address = nil;
    [_port removeFromSuperview];
    _port = nil;
     
    
    
    
}


- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    
    
    
    
    
    
    
}

- (void)dealloc
{
    [_car stop];
    [_car release];
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark CommunicateWithCarDelegate


- (void)didReceiveData:(NSString*)key value:(NSNumber*)value
{

    //NSLog(@"%@=%d",key,[value integerValue]);
    
    if([key isEqualToString:@"brake"] )
    {
        if( value.boolValue){
            [self didBrakeDown];
        }else{
            [self didBrakeUp];
        }
    }else if([key isEqualToString:@"speed"])
    {
       
        if(_labelSpeed)
        {
            _labelSpeed.text = [NSString stringWithFormat:@"%d",value.intValue];
        }
        [self setBarPosition:value.intValue];
        
    }else if([key isEqualToString:@"wiper"])
    {
        if([value boolValue]){
            _mu = RAIN_MU;
            [UIView animateWithDuration:1.0 animations:^{
                _bgImageView_rain.alpha = 1.0f;
                
            }];
        }else{
            _mu = DEFAULT_MU;
            [UIView animateWithDuration:1.0 animations:^{
                _bgImageView_rain.alpha = 0.0f;
            }];
        }
        
    }else if([key isEqualToString:@"obstacle"])
    {
        
        [self setObstaclePosition:[value intValue]];
    }
    
}

- (void)didClose
{

    [self newConnection];
}

- (void)didOpen
{
    [UIView animateWithDuration:0.3 animations:^{
        _initView.alpha = 0.0f;
    }completion:^(BOOL finished){
        
        [_initView removeFromSuperview];
        _initView = nil;
        
        _mode = DistanceCheckModeReady;
        
    }];
}

@end
