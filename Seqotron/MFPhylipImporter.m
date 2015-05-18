//
//  MFPhylipImporter.m
//  Seqotron
//
//  Created by Mathieu Fourment on 7/11/2014.
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

#import "MFPhylipImporter.h"

#import "MFSequence.h"
#import "MFString.h"

@implementation MFPhylipImporter

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

//TODO: only read interleaved
- (MFSequenceSet *)readSequences:(MFReaderCluster *)reader{
    NSString *line = [reader readLine];
    
    NSInteger numberOfSequences = 0;
    NSInteger numberOfSites = 0;
    NSString *type;
    NSScanner *scanner = [NSScanner scannerWithString:line];
    [scanner scanInteger:&numberOfSequences];
    [scanner scanInteger:&numberOfSites];
    
    [reader rewind];
    
    if( [scanner scanCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"iIsS"] intoString:&type] ){
        if( [[type uppercaseString] isEqualToString:@"I"]){
            return [self readInterleavedSequences:reader];
        }
        else if( [[type uppercaseString] isEqualToString:@"S"]){
            return [self readSequentialSequences:reader];
        }
        else {
            return nil;
        }
    }
    
    return [self readInterleavedSequences:reader];
}

- (MFSequenceSet *)readInterleavedSequences:(MFReaderCluster *)reader{
    NSString *line = [reader readLine];
    
    NSInteger numberOfSequences = 0;
    NSInteger numberOfSites = 0;
    NSScanner *scanner = [NSScanner scannerWithString:line];
    [scanner scanInteger:&numberOfSequences];
    [scanner scanInteger:&numberOfSites];
    
    MFSequenceSet *sequences = nil;
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:numberOfSequences];
    
    // read lines containing name + sequence
    while ( (line = [reader readLine]) ) {
        if (![line isEmpty]){
            NSMutableString *mutableString = [line mutableCopy];
            [array addObject:mutableString];
            [mutableString release];
        }
        
        if( [array count] == numberOfSequences ) break;
    }
    
    // read rest of sequences and concatenate (if any)
    NSUInteger index = 0;
    while ( (line = [reader readLine]) ) {
        if ( ![line isEmpty] ){
            if( index == numberOfSequences){
                index = 0;
            }
            [[array objectAtIndex:index] appendString:line];
            index++;
        }
    }
    
    // find the boundary between name and sequence using the length of the sequence
    if( [array count] == numberOfSequences ){
        sequences = [[MFSequenceSet alloc] initWithCapacity:numberOfSequences];
        for ( NSMutableString *line in array) {
            NSUInteger len = 0;
            NSInteger i = [line length]-1;
            while ( len != numberOfSites && i != 0 ) {
                if ( ![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[line characterAtIndex:i]]) {
                    len++;
                }
                i--;
            }
            
            NSArray* temp = [[[line substringFromIndex:i+1] uppercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            NSString *seq = [temp componentsJoinedByString:@""];
            
            if( [seq length] != numberOfSites ){
                [array release];
                [sequences release];
                return nil;
            }
            
            NSString *name = [[line substringToIndex:i+1] stringByTrimmingPaddingWhitespace];
            MFSequence *sequence = [[ MFSequence alloc] initWithString:seq name:name];
            [sequences addSequence:sequence];
            [sequence release];
        }
    }
    [array release];
    
    if( [sequences count] != numberOfSequences ){
        [sequences release];
        return nil;
    }
    
    return [sequences autorelease];
}

- (MFSequenceSet *)readSequentialSequences:(MFReaderCluster *)reader{
    
    NSString *line = [reader readLine];
    
    NSInteger numberOfSequences = 0;
    NSInteger numberOfSites = 0;
    NSScanner *scanner = [NSScanner scannerWithString:line];
    [scanner scanInteger:&numberOfSequences];
    [scanner scanInteger:&numberOfSites];
    
    MFSequenceSet *sequences = [[MFSequenceSet alloc] initWithCapacity:numberOfSequences];;
    
    NSMutableString *mutableString = [NSMutableString string];

    while ( (line = [reader readLine]) ) {
        if (![line isEmpty]){
            [mutableString appendString:line];
            
            if( [mutableString length] > numberOfSites ){
                NSUInteger len = 0;
                NSInteger i = [mutableString length]-1;
                
                while ( len != numberOfSites && i != 0 ) {
                    if ( ![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[mutableString characterAtIndex:i]]) {
                        len++;
                    }
                    i--;
                }
                
                if( i != 0 ){
                    NSArray* temp = [[[mutableString substringFromIndex:i+1] uppercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    NSString *seq = [temp componentsJoinedByString:@""];
                    NSString *name = [[mutableString substringToIndex:i+1] stringByTrimmingPaddingWhitespace];
                    
                    if( [seq length] != numberOfSites ){
                        [sequences release];
                        return nil;
                    }
                    MFSequence *sequence = [[ MFSequence alloc] initWithString:seq name:name];
                    [sequences addSequence:sequence];
                    [sequence release];
                    [mutableString setString:@""];
                }
            }
            
        }
    }
    
    if( [sequences count] != numberOfSequences ){
        [sequences release];
        return nil;
    }
    return [sequences autorelease];
}

@end
