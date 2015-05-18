//
//  MFClustalImporter.m
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

#import "MFClustalImporter.h"

#import "MFSequence.h"
#import "MFReaderCluster.h"
#import "MFString.h"

@implementation MFClustalImporter


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
    
    
    NSRegularExpression *conservationRegex  = [NSRegularExpression regularExpressionWithPattern:@"^\\s*[\\*\\.: ]+$" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *positionRegex = [NSRegularExpression regularExpressionWithPattern:@"\\d+$" options:NSRegularExpressionCaseInsensitive error:nil];
    
    
    NSString *line;
    // discard first line (CLUSTAL...)
    [reader readLine];
    
    MFSequenceSet *sequences = nil;
    NSMutableArray *array = [[NSMutableArray alloc] init];
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    while ( (line = [ reader readLine]) ) {
		
        if ( ![line isEmpty] ){
            NSArray* block = [conservationRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
            
            // Not the conservation sequence
            if( [block count] == 0 ){
                line = [line stringByTrimmingPaddingWhitespace];
                NSUInteger i = 0;
                while ( i != [line length] ) {
                    if ( [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[line characterAtIndex:i]]) break;
                    i++;
                }
                NSString *name = [line substringToIndex:i];
                
                NSArray* temp = [[[line substringFromIndex:i+1] uppercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *seq  = [temp componentsJoinedByString:@""];
                
                // remove position at the end of each sequence if available
                seq = [positionRegex stringByReplacingMatchesInString:seq options:0 range:NSMakeRange(0, [seq length]) withTemplate:@""];
                seq = [seq uppercaseString];
                
                if( [dict objectForKey:name] ){
                    MFSequence *sequence = [dict objectForKey:name];
                    [sequence concatenateString:seq];
                }
                else {
                    MFSequence *sequence = [[MFSequence alloc] initWithString:seq name:name];
                    [dict setObject:sequence forKey:name];
                    [sequence release];
                    [array addObject:name];
                }
            }
        }
    }
    if( [array count] > 0 ){
        sequences = [[MFSequenceSet alloc] initWithCapacity:[array count]];
        for (NSString *name in array) {
            [sequences addSequence: [dict objectForKey:name]];
        }
    }
    [dict release];
    [array release];

    return [sequences autorelease];
}

@end
