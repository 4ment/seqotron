//
//  MFOperation.m
//  Seqotron
//
//  Created by Mathieu Fourment on 10/03/2015.
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

#import "MFOperation.h"

@implementation MFOperation


NSString *MFOperationDescriptionKey   = @"tk.phylogenetics.operation.description";
NSString *MFOperationOutputKey        = @"tk.phylogenetics.operation.output";
NSString *MFOperationDocumentClassKey = @"tk.phylogenetics.operation.document.class";

@synthesize outputURL = _outputURL;
@synthesize classType = _classType;
@synthesize description,options;
@synthesize delegate;

- (id)init{
    if( self = [super init]){
        options = nil;
        description = nil;
        _outputURL = nil;
        _classType = nil;
    }
    return self;
}

-(id)initWithOutputURL:(NSURL*)url classDocument:(NSString*)type{
    if( self = [super init]){
        _outputURL = [url retain];
        _classType = [type copy];
        description = [@""copy];
        delegate = nil;
    }
    return self;
}

- (id)initWithOptions:(NSDictionary *)someOptions{
    if( self = [super init]){
        options = [someOptions retain];
        description = nil;
        _outputURL = nil;
        _classType = nil;
        
        if( [options objectForKey:MFOperationDescriptionKey]){
            description = [[options objectForKey:MFOperationDescriptionKey]copy];
        }
        if( [options objectForKey:MFOperationOutputKey]){
            _outputURL = [[options objectForKey:MFOperationOutputKey]copy];
        }
        if( [options objectForKey:MFOperationDocumentClassKey]){
            _classType = [[options objectForKey:MFOperationDocumentClassKey]copy];
        }
    }
    return self;
}


-(void)dealloc{
    [options release];
    [_classType release];
    [_outputURL release];
    [description release];
    delegate = nil;
    [super dealloc];
}
@end
