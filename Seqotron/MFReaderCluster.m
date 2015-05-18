//
//  MFReaderCluster.m
//  Seqotron
//
//  Created by Mathieu Fourment on 7/11/2014.
//  Copyright (c) 2014 Mathieu Fourment. All rights reserved.
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

#import "MFReaderCluster.h"

#import "MFFileReader.h"
#import "MFStringReader.h"

@implementation MFReaderCluster

-(id)initWithData:(NSData*)data{
    [self release];
    
    return self;
}

-(id)initWithURL:(NSURL*)url{
    [self release];
    
    return self;
}

-(id)initWithFile:(NSString*)filepath{
    [self release];
    
    return [[MFFileReader alloc] initWithFile:filepath];
}

-(id)initWithString:(NSString*)content{
    [self release];
    
    return [[MFStringReader alloc]initWithString:content];
}

-(void)dealloc{
    [super dealloc];
}

-(NSString*)readLine{
    return @"";
}

-(void)rewind{
    
}

@end
