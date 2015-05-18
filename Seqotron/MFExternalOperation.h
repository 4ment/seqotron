//
//  MFExternalOperation.h
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

#import <Foundation/Foundation.h>

#import "MFOperation.h"

extern NSString *MFExternalOperationLaunchPathKey;
extern NSString *MFExternalOperationArgumentsKey;
extern NSString *MFExternalOperationInputKey;
extern NSString *MFExternalOperationStdoutKey;
extern NSString *MFExternalOperationStderrKey;

@interface MFExternalOperation : MFOperation{
    NSTask *_task;
    NSFileHandle *_stdOutHandle;
    NSFileHandle *_stdInHandle;
    BOOL _parseStdout;// if YES the output is parsed. It can be an alignment or a tree
    NSString *_currentLineStdOut;
    NSTimer *_timer;
    
}

-(id)initWithOptions:(NSDictionary*)options;

@end
