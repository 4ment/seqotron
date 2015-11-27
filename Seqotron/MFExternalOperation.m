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
NSString *MFExternalOperationStdoutFileKey    = @"tk.phylogenetics.external.operation.stdout.file";
NSString *MFExternalOperationStdoutKey         = @"tk.phylogenetics.external.operation.read.stdout";
NSString *MFExternalOperationStderrKey         = @"tk.phylogenetics.external.operation.read.stderr";

@implementation MFExternalOperation


-(id)initWithOptions:(NSDictionary*)options{
    if( self = [super initWithOptions:options]){
        _task = [[NSTask alloc]init];
        _stdOutHandle = nil;
        _parseStdout = YES;
        _stdoutRedirectedToFile = NO;
        _stdInHandle = nil;
        _currentLineStdOut = [@"" copy];
        
        if( [options objectForKey:MFExternalOperationStdoutFileKey] ){
            _stdoutRedirectedToFile = [[options objectForKey:MFExternalOperationStdoutFileKey] boolValue];
        }
        
        [_task setLaunchPath:[options objectForKey:MFExternalOperationLaunchPathKey]];
        [_task setArguments:[options objectForKey:MFExternalOperationArgumentsKey]];
        
        if ( [[options objectForKey:MFExternalOperationStdoutKey] boolValue] ) {
            NSPipe *stdOutPipe = [NSPipe pipe];
            _stdOutHandle = [stdOutPipe fileHandleForReading];
            [_task setStandardOutput: stdOutPipe];
        }
        else if ( [[options objectForKey:MFExternalOperationStderrKey] boolValue] ) {
            NSPipe *stdOutPipe = [NSPipe pipe];
            _stdOutHandle = [stdOutPipe fileHandleForReading];
            [_task setStandardError: stdOutPipe];
        
            _timer = [NSTimer scheduledTimerWithTimeInterval:2.0 target:self selector:@selector(logMethod:) userInfo:nil repeats:YES];
            
            [[NSRunLoop currentRunLoop] addTimer:_timer forMode:NSRunLoopCommonModes];
        }
        else if( _stdoutRedirectedToFile ){
            _stdOutHandle = [NSFileHandle fileHandleForWritingAtPath:[_outputURL path]];
            if(_stdOutHandle == nil) {
                [[NSFileManager defaultManager] createFileAtPath:[_outputURL path] contents:nil attributes:nil];
                _stdOutHandle = [NSFileHandle fileHandleForWritingAtPath:[_outputURL path]];
            }
            [_task setStandardOutput : _stdOutHandle];
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
    if( !_stdoutRedirectedToFile && _stdOutHandle != nil ){
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
