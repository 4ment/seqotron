//
//  MFDocumentController.m
//  Seqotron
//
//  Created by Mathieu Fourment on 16/12/2014.
//  Copyright (c) 2014 Mathieu Fourment. All rights reserved.
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

#import "MFDocumentController.h"

#import "MFReaderCluster.h"
#import "MFString.h"

@implementation MFDocumentController



// By default a file is an alignment what ever the extension is.
-(NSString *)typeForContentsOfURL:(NSURL *)url error:(NSError **)error {
    if ( ![url isFileURL] ) {
        return nil;
    }
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithFile:url.path];
    NSString *line = nil;
    
    BOOL isTree = NO;
    BOOL isSequence = NO;
    BOOL isNexus = NO;
    
    while ( (line = [reader readLine]) ) {
        // Allow the first line to be empty
        if( [[line stringByTrimmingPaddingWhitespace] length] == 0 ){
            continue;
        }
        if ( [[line uppercaseString] hasPrefix:@"#NEXUS"]) {
            isNexus = YES;
        }
        else if( [line hasPrefix:@"("]){
            isTree = YES;
        }
        break;
    }
    
    if ( isNexus ) {
        while ( (line = [reader readLine]) ) {
            if( [[line stringByTrimmingPaddingWhitespace] length] == 0 ){
                continue;
            }
            if( [[line uppercaseString] hasPrefix:@"BEGIN TREES"] ){
                NSLog(@"nexus tree");
                isTree = YES;
            }
            else if( [[line uppercaseString] hasPrefix:@"BEGIN DATA"] || [[line uppercaseString] hasPrefix:@"BEGIN CHARACTERS"] ){
                isSequence = YES;
                NSLog(@"nexus sequence");
            }
            if( isTree && isSequence)break;
        }
    }
    [reader release];
    
    if(isTree) return @"Tree";
    
    return @"Alignment";
}

@end
