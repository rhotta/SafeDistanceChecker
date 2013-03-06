//
//  CommunicateWithCar.h
//  SafeDistanceChecker
//
//  Created by RyusukeHotta on 13/03/04.
//  Copyright (c) 2013年 RyusukeHotta. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SRWebSocket.h"

@protocol CommunicateWithCarDelegate <NSObject>

- (void)didReceiveData:(NSString*)key value:(NSNumber*)value;
- (void)didOpen;

- (void)didClose;

@end

@interface CommunicateWithCar : NSObject


- (void)startWithURL:(NSString*)url;
- (void)stop;


@property (nonatomic,assign) id delegate;
@end
