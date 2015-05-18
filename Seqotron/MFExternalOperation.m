//
//  MFExternalOperation.m
//  Seqotron
//
//  Created by Mathieu on 13/01/2015.
//  Copyright (c) 2015 Mathieu Fourment. All rights reserved.
//
//  This file is part of Seqotron.
//
//  Seqotron is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Seqotron is distributed in the hope that it will be useful,
//  but Seqotron ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Seqotron.  If not, see <http://www.gnu.org/licenses/>.
//

#import "MFExternalOperation.h"

NSString *MFExternalOperationLaunchPathKey    = @"tk.phylogenetics.external.operation.launchPath";
NSString *MFExternalOperationArgumentsKey     = @"tk.phylogenetics.external.operation.arguments";
NSString *MFExternalOperationInputKey         = @"tk.phylogenetics.external.operation.input";
NSString *MFExternalOperationStdoutKey         = @"tk.phylogenetics.external.read.stdout";
NSString *MFExternalOperationStderrKey         = @"tk.phylogenetics.external.read.stderr";

@implementation MFExternalOperation


-(id)initWithOptions:(NSDictionary*)options{
    if( self = [super initWithOptions:options]){
        _task = [[NSTask alloc]init];
        _stdOutHandle = nil;
        _parseStdout = YES;
        _stdInHandle = nil;
        _currentLineStdOut = [@"" copy];
        
        [_task setLaunchPath:[options objectForKey:MFExternalOperationLaunchPathKey]];
        [_task setArguments:[options objectForKey:MFExternalOperationArgumentsKey]];
        
        if ( [[options objectForKey:MFExternalOperationStdoutKey] boolValue] ) {
            NSPipe *stdOutPipe = [NSPipe pipe];
            _stdOutHandle = [stdOutPipe fileHandleForReading];
            [_task setStandardError: stdOutPipe];
        }
        else if ( [[options objectForKey:MFExternalOperationStderrKey] boolValue] ) {
            NSPipe *stdOutPipe = [NSPipe pipe];
            _stdOutHandle = [stdOutPipe fileHandleForReading];
            [_task setStandardError: stdOutPipe];
        
            _timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(logMethod:) userInfo:nil repeats:YES];
            
            [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        }
    }
    return self;
}

-(void)dealloc{
    [_currentLineStdOut release];
    [_task release];
    [super dealloc];
}


-(void)main{
    NSLog(@"Operation running %@",self.description);
    
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        [self.delegate operation:self setDescription:self.description];
//    });
    
    [_task launch];
    
    
    NSData *data;
    if( _stdOutHandle != nil ){
        
        if( !_parseStdout ){
            data = [_stdOutHandle readDataToEndOfFile];
        }
        else {
            while ( (data = [_stdOutHandle availableData]) ){
                NSString *str = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
                [_currentLineStdOut release];
                _currentLineStdOut = [str copy];
                
                [str release];
            }
        }
    }
    else {
        [_task waitUntilExit];
    }
    NSLog(@"Operation finished");
}

-(void) cancel {
    [_timer invalidate];
    [_task terminate];
    [super cancel];
}

// run on the main thread
- (void)logMethod:(NSTimer*)theTimer {
    //NSLog(@"targetMethod: %d",[NSThread isMainThread]);
    [self.delegate operation:self setDescription:_currentLineStdOut];
}

@end
