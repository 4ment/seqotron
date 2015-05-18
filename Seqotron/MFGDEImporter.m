//
//  MFFASTAImporter.m
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

#import "MFGDEImporter.h"

#import "MFSequence.h"
#import "MFReaderCluster.h"
#import "MFNucleotide.h"
#import "MFProtein.h"

// http://cs.mcgill.ca/~birch/tutorials/GDE/overview/GDE.file_formats.html
// Flatfile format only

@implementation MFGDEImporter

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
    
	NSMutableString *sequenceBuffer = [ [NSMutableString alloc] initWithCapacity:100 ];
    NSMutableString *nameBuffer = [ [NSMutableString alloc] initWithCapacity:100 ];
	[sequenceBuffer setString: @""];
    
    MFDataType *dataType = nil;
    
    NSString *line;
    while ( (line = [reader readLine]) ) {

        if( [line hasPrefix:@"#"] || [line hasPrefix:@"%"] ){
            if( dataType == nil ){
                if( [line hasPrefix:@"%"] ){
                    dataType = [[MFProtein alloc]init];
                }
                else if( [line hasPrefix:@"#"] ){
                    dataType = [[MFNucleotide alloc]init];
                }
            }
            if( ![ sequenceBuffer isEqualToString: @"" ]){
                
                NSArray* temp = [sequenceBuffer componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                NSString *seq = [temp componentsJoinedByString:@""];
                MFSequence *sequence = [[MFSequence alloc]initWithString:seq name:nameBuffer dataType:dataType];
                
                [sequences addSequence:sequence];
                [sequence release];
				[sequenceBuffer setString: @""];
            }
            [nameBuffer setString:[line substringFromIndex:1]];
        }
        else {
            [sequenceBuffer appendString: [line uppercaseString]];
        }
	}
	
    if( ![ sequenceBuffer isEqualToString: @"" ]){
        MFSequence *sequence = [[ MFSequence alloc] initWithString:sequenceBuffer name:nameBuffer];
        [sequences addSequence:sequence];
        [sequence release];
    }
    
	[sequenceBuffer release];
    [nameBuffer release];
    [dataType release];
    return [sequences autorelease];
}

@end
