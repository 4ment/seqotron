//
//  MFSequenceReader.m
//  Seqotron
//
//  Created by Mathieu Fourment on 25/01/14.
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

#import "MFSequenceReader.h"


#import "MFSequence.h"
#import "MFSequenceSet.h"
#import "MFString.h"
#import "MFNucleotide.h"
#import "MFProtein.h"
#import "MFDefines.h"
#import "MFReaderCluster.h"

#import "MFNexusImporter.h"
#import "MFFASTAImporter.h"
#import "MFPhylipImporter.h"
#import "MFClustalImporter.h"
#import "MFGDEImporter.h"
#import "MFMEGAImporter.h"
#import "MFNBRFImporter.h"
#import "MFStockholmImporter.h"

@implementation MFSequenceReader

NSString * const MFSequenceFileFormat = @"tk.phylogenetics.sequence.file.format";

+ (MFSequenceSet *)readSequencesFromData:(NSData *)data{
    NSString *content = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    
    MFSequenceSet *sequences = [MFSequenceReader readSequencesFromString:content];
    
    [content release];
    return sequences;
}

+ (MFSequenceSet *)readSequencesFromURL:(NSURL*)url{
    NSString *content = [ NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    MFSequenceSet *sequences = [MFSequenceReader readSequencesFromString:content];
    
    return sequences;
}

+ (MFSequenceSet *)readSequencesFromString:(NSString *)content{
    
    // For Phylip
    NSString *pattern = @"^\\s*\\d+\\s+\\d+\\s*[iIsS]?";
    NSError *error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:&error];
    
    NSRange range = NSMakeRange(0, 0);
    NSUInteger start, end;
    NSUInteger contentsEnd = 0;
    
    NSArray *formats = [[NSArray alloc] initWithObjects:MFSequenceFormatArray];
    
    MFSequenceSet *sequenceSet = nil;
    
    while ( contentsEnd < [content length]) {
		[content getLineStart:&start end:&end contentsEnd:&contentsEnd forRange:range];
		NSString *line = [content substringWithRange:NSMakeRange(start,contentsEnd-start)];
        NSString *temp = line;
        
        
        // Allow the first line to be empty
        if( [[temp stringByTrimmingPaddingWhitespace] length] == 0 ){
            range.location = end;
            range.length = 0;
            continue;
        }
        
        // NBRF
        if( [line hasPrefix:@">P1;"] || [line hasPrefix:@">F1;"]
           ||  [line hasPrefix:@">D1;"] || [line hasPrefix:@">DC;"] || [line hasPrefix:@">DC;"]
           ||  [line hasPrefix:@">RL;"] || [line hasPrefix:@">F1;"]
           ||  [line hasPrefix:@">N1;"] || [line hasPrefix:@">N3;"]
           ||  [line hasPrefix:@">XX;"] ){
            NSLog(@"Reading NBRF Flat file!");
            MFNBRFImporter *importer = [[MFNBRFImporter alloc]init];
            sequenceSet = [importer readSequencesFromString:content ];
            [importer release];
            [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatNBRF ] forKey:MFSequenceFileFormat];
        }
        // FASTA
        else if( [line hasPrefix:@">"] ){
            NSLog(@"Reading FASTA file!");
            MFFASTAImporter *importer = [[MFFASTAImporter alloc]init];
            sequenceSet = [importer readSequencesFromString:content ];
            [importer release];
            [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatFASTA ] forKey:MFSequenceFileFormat];
        }
        // Nexus
        else if( [[line uppercaseString] hasPrefix:@"#NEXUS"]){
            NSLog(@"Reading NEXUS file!");
            MFNexusImporter *importer = [[MFNexusImporter alloc]init];
            sequenceSet = [importer readSequencesFromString:content ];
            [importer release];
            [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatNEXUS ] forKey:MFSequenceFileFormat];
            
        }
        // CLUSTAL
        else if( [[line uppercaseString] hasPrefix:@"CLUSTAL"]){
            NSLog(@"Reading CLUSTAL file!");
            MFClustalImporter *importer = [[MFClustalImporter alloc]init];
            sequenceSet = [importer readSequencesFromString:content ];
            [importer release];
            [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatCLUSTAL ] forKey:MFSequenceFileFormat];
            
        }
        // MEGA
        else if( [[line uppercaseString] hasPrefix:@"#MEGA"] ){
            NSLog(@"Reading MEGA file!");
            MFMEGAImporter *importer = [[MFMEGAImporter alloc]init];
            sequenceSet = [importer readSequencesFromString:content ];
            [importer release];
            [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatMEGA ] forKey:MFSequenceFileFormat];
        }
        // Stockholm
        else if( [[line uppercaseString] hasPrefix:@"# STOCKHOLM"] || [[line uppercaseString] hasPrefix:@"#STOCKHOLM"] ){
            NSLog(@"Reading Stockholm!");
            MFStockholmImporter *importer = [[MFStockholmImporter alloc]init];
            sequenceSet = [importer readSequencesFromString:content ];
            [importer release];
            [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatSTOCKHOLM ] forKey:MFSequenceFileFormat];
        }
        // GDE
        else if( [[line uppercaseString] hasPrefix:@"#"] ){
            NSLog(@"Reading GDE Flat file!");
            MFGDEImporter *importer = [[MFGDEImporter alloc]init];
            sequenceSet = [importer readSequencesFromString:content ];
            [importer release];
            [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatGDE ] forKey:MFSequenceFileFormat];
        }
        else {
            NSRange searchedRange = NSMakeRange(0, [line length]);
            NSArray* matches = [regex matchesInString:line options:0 range: searchedRange];
            // Phylip
            if( [matches count] == 1 ){
                NSLog(@"Reading Phylip file!");
                MFPhylipImporter *importer = [[MFPhylipImporter alloc]init];
                sequenceSet = [importer readSequencesFromString:content ];
                [importer release];
                [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatPHYLIP ] forKey:MFSequenceFileFormat];
                
            }
        }
        break;
    }
    [formats release];
    
    return sequenceSet;
}


+ (MFSequenceSet *)readSequencesFromFile:(NSString *)path{
    
    // For Phylip
    NSString *pattern = @"^\\s*\\d+\\s+\\d+\\s*[iIsS]?";
    NSError *error = nil;
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern: pattern options:0 error:&error];
    
    NSArray *formats = [[NSArray alloc] initWithObjects:MFSequenceFormatArray];
    
    MFSequenceSet *sequenceSet = nil;
    
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithFile:path];
    NSString *line = nil;
    
    while ( (line = [reader readLine]) ) {
        // Allow the first line to be empty
        if( [[line stringByTrimmingPaddingWhitespace] length] == 0 ){
            continue;
        }
        line = [line copy]; // seems bad
        break;
    }
    [reader release];
    
    // NBRF
    if( [[line uppercaseString] hasPrefix:@">P1;"] ){
        NSLog(@"Reading NBRF Flat file!");
        MFNBRFImporter *importer = [[MFNBRFImporter alloc]init];
        sequenceSet = [importer readSequencesFromFile:path ];
        [importer release];
        [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatNBRF ] forKey:MFSequenceFileFormat];
    }
    // FASTA
    else if( [line hasPrefix:@">"] ){
        NSLog(@"Reading FASTA file!");
        MFFASTAImporter *importer = [[MFFASTAImporter alloc]init];
        sequenceSet = [importer readSequencesFromFile:path ];
        [importer release];
        [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatFASTA ] forKey:MFSequenceFileFormat];
    }
    // Nexus
    else if( [[line uppercaseString] hasPrefix:@"#NEXUS"]){
        NSLog(@"Reading NEXUS file!");
        MFNexusImporter *importer = [[MFNexusImporter alloc]init];
        sequenceSet = [importer readSequencesFromFile:path ];
        [importer release];
        [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatNEXUS ] forKey:MFSequenceFileFormat];
        
    }
    // CLUSTAL
    else if( [[line uppercaseString] hasPrefix:@"CLUSTAL"]){
        NSLog(@"Reading CLUSTAL file!");
        MFClustalImporter *importer = [[MFClustalImporter alloc]init];
        sequenceSet = [importer readSequencesFromFile:path ];
        [importer release];
        [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatCLUSTAL ] forKey:MFSequenceFileFormat];
        
    }
    // MEGA
    else if( [[line uppercaseString] hasPrefix:@"#MEGA"] ){
        NSLog(@"Reading MEGA file!");
        MFMEGAImporter *importer = [[MFMEGAImporter alloc]init];
        sequenceSet = [importer readSequencesFromFile:path ];
        [importer release];
        [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatMEGA ] forKey:MFSequenceFileFormat];
    }
    // Stockholm
    else if( [[line uppercaseString] hasPrefix:@"# STOCKHOLM"] || [[line uppercaseString] hasPrefix:@"#STOCKHOLM"] ){
        NSLog(@"Reading Stockholm!");
        MFStockholmImporter *importer = [[MFStockholmImporter alloc]init];
        sequenceSet = [importer readSequencesFromFile:path ];
        [importer release];
        [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatSTOCKHOLM ] forKey:MFSequenceFileFormat];
    }
    // GDE
    else if( [[line uppercaseString] hasPrefix:@"#"] ){
        NSLog(@"Reading GDE Flat file!");
        MFGDEImporter *importer = [[MFGDEImporter alloc]init];
        sequenceSet = [importer readSequencesFromFile:path ];
        [importer release];
        [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatGDE ] forKey:MFSequenceFileFormat];
    }
    else {
        NSRange searchedRange = NSMakeRange(0, [line length]);
        NSArray* matches = [regex matchesInString:line options:0 range: searchedRange];
        // Phylip
        if( [matches count] == 1 ){
            NSLog(@"Reading Phylip file!");
            MFPhylipImporter *importer = [[MFPhylipImporter alloc]init];
            sequenceSet = [importer readSequencesFromFile:path ];
            [importer release];
            [sequenceSet addAnnotation:[formats objectAtIndex:MFSequenceFormatPHYLIP ] forKey:MFSequenceFileFormat];
            
        }
    }
    
    [line release];
    [formats release];
    
    return sequenceSet;
}

@end
