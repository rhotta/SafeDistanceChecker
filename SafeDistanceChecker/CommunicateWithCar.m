//
//  CommunicateWithCar.m
//  SafeDistanceChecker
//
//  Created by RyusukeHotta on 13/03/04.
//  Copyright (c) 2013年 RyusukeHotta. All rights reserved.
//

#import "CommunicateWithCar.h"


@interface CommunicateWithCar ()<SRWebSocketDelegate>
{
    NSDictionary *_sockets;
    
    BOOL _isOpen;
}
@end


@implementation CommunicateWithCar

@synthesize delegate = _delegate;

- (void)startWithURL:(NSString*)url
{
    if(_sockets == nil) {
        _isOpen = YES;
        NSMutableDictionary *sock_dict = [NSMutableDictionary dictionaryWithCapacity:2];
        for (NSString *proto in [NSArray arrayWithObjects:@"cmd", @"stream", nil]) {
            SRWebSocket *socket = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:url]
                                                         protocols:[NSArray arrayWithObject:proto]];
            socket.delegate = self;
            [socket open];
            [sock_dict setObject:socket forKey:proto];
        }
        _sockets = [NSDictionary dictionaryWithDictionary:sock_dict];
    }
}

- (void)stop
{
    if(_sockets) {
        for (SRWebSocket *socket in [_sockets allValues]) {
            [socket close];
        }
        _sockets = nil;
    }
}
- (void)dealloc
{
 
    [super dealloc];
}
#pragma mark SRWebSocketDelegate

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    
    if([webSocket.protocol isEqualToString:@"stream"]) {
        
        NSData *jdata = [((NSString *)message) dataUsingEncoding:NSUTF8StringEncoding];
        
        NSError *err;
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jdata options:0 error:&err];
        if(!data) return;
        NSDictionary *values = [data valueForKey:@"value"];
        
        if(!values) return;
        
        NSNumber* speed = [values valueForKey:@"speed"];
        
        if(speed){
            [_delegate didReceiveData:@"speed" value:speed];
        }
        
  
    
        
    }else{
        
        NSData *jdata = [((NSString *)message) dataUsingEncoding:NSUTF8StringEncoding];
        NSError *err;
        NSDictionary *data = [NSJSONSerialization JSONObjectWithData:jdata options:0 error:&err];
        if(!data) return;
        
        
        NSNumber* value = [data valueForKey:@"value"];
        if(!value) return;
       
        
        NSString* idRecv = [data valueForKey:@"id"];
        if([idRecv isEqualToString:@"sw18"])
        {
            [_delegate didReceiveData:@"wiper" value:value];
        }else if([idRecv isEqualToString:@"sw23"])
        {
            [_delegate didReceiveData:@"brake" value:value];
        }else if([idRecv isEqualToString:@"slider1"])
        {
            [_delegate didReceiveData:@"obstacle" value:value];
        }

    }
}


- (void)webSocketDidOpen:(SRWebSocket *)webSocket {
    
    
    if([webSocket.protocol isEqualToString:@"stream"]) {
        NSMutableDictionary *cmd = [NSMutableDictionary dictionaryWithCapacity:1];		// ・・・（2）
        [cmd setObject:@"START_STREAM" forKey:@"cmd"];
        
        
        NSError *err;
        NSData *json = [NSJSONSerialization dataWithJSONObject:cmd options:0 error:&err];	// ・・・（3）
        NSString *json_str = [[NSString alloc] initWithData:json encoding:NSUTF8StringEncoding];
        
        [webSocket send:json_str];
        
        [_delegate didOpen];
    }
    
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    if(!_isOpen) return;
    _isOpen = NO;
   
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"didFailWithError"
                                                    message:[error localizedDescription]
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    
     [_delegate didClose];
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    if(!_isOpen) return;
    _isOpen = NO;

    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"didCloseWithCode"
                                                    message:reason
                                                   delegate:nil
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    [alert release];
    
    
    [_delegate didClose];
}



@end
