//
//  MFStockholmImporter.m
//  Seqotron
//
//  Created by Mathieu on 3/12/2014.
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

#import "MFStockholmImporter.h"

#import "MFSequence.h"
#import "MFReaderCluster.h"
#import "MFString.h"

// http://sonnhammer.sbc.su.se/Stockholm.html
// Gaps are not allowed in sequence names

@implementation MFStockholmImporter

- (MFSequenceSet *)readSequencesFromFile:(NSString *)path{
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithFile:path];
    
    MFSequenceSet *sequences = [self readSequences:reader];
    
    [reader release];
    
    return sequences;
}

-(MFSequenceSet*)readSequencesFromURL:(NSURL*)url{
    NSString *content = [ NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    MFSequenceSet *sequences = [self readSequencesFromString:content];
    
    return sequences;
}

-(MFSequenceSet*)readSequencesFromData:(NSData*)data{
    NSString *content = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithString:content];
    
    MFSequenceSet *sequences = [self readSequences:reader];
    
    [reader release];
    [content release];
    
    return sequences;
}

-(MFSequenceSet*)readSequencesFromString:(NSString*)content{
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithString:content];
    
    MFSequenceSet *sequences = [self readSequences:reader];
    
    [reader release];
    
    return sequences;
}

- (MFSequenceSet *)readSequences:(MFReaderCluster *)reader{
    
    MFSequenceSet *sequences = [[MFSequenceSet alloc] init];
    
    NSString *line;
    
    while ( (line = [reader readLine]) ) {
        line = [[line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]componentsJoinedByString:@""];
        if( [[line lowercaseString] hasPrefix:@"#stockholm"]) break;
    }
    
    while ( (line = [reader readLine]) ) {
        if( [line isEmpty]) continue;
        
        line = [line stringByTrimmingLeadingWhitespace];
        
        if( ![line hasPrefix:@"#"] && ![line hasPrefix:@"//"] ){
            NSRange range = [line rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
            NSString *name = [line substringToIndex:range.location];
            NSString *seq = [[line substringFromIndex:range.location+1] uppercaseString];
            seq = [seq stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            seq = [seq stringByReplacingOccurrencesOfString:@"." withString:@"-"];
            MFSequence *sequence = [[ MFSequence alloc] initWithString:seq name:name];
            [sequences addSequence:sequence];
            [sequence release];
        }
    }
    
    return [sequences autorelease];
}

@end