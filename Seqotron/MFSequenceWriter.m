//
//  MFSequenceWriter.m
//  Seqotron
//
//  Created by Mathieu Fourment on 31/01/14.
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

#import "MFSequenceWriter.h"

#include "MFSequenceSet.h"
#include "MFSequence.h"
#include "MFString.h"
#include "MFNucleotide.h"


NSString *MFSequenceWriterRange = @"MFSequenceRange";
NSString *MFSequenceWriterIgnoreLeadingGaps = @"MFSequenceIgnoreLeadingGaps";

@implementation MFSequenceWriter



+ (NSData *) data:(MFSequenceSet *) inSequences withFormat:(MFSequenceFormat)format attributes:(NSDictionary*)attrs{
    NSData *data = nil;
    NSArray *formats = [[NSArray alloc] initWithObjects:MFSequenceFormatArray];
    switch (format) {
        case MFSequenceFormatFASTA:
            data = [MFSequenceWriter dataFasta:inSequences attributes:attrs];
            break;
        case MFSequenceFormatNEXUS:
            data = [MFSequenceWriter dataNexus:inSequences attributes:attrs];
            break;
        case MFSequenceFormatPHYLIP:
            data = [MFSequenceWriter dataPhylip:inSequences attributes:attrs];
            break;
        case MFSequenceFormatMEGA:
            data = [MFSequenceWriter dataMega:inSequences attributes:attrs];
            break;
        case MFSequenceFormatCLUSTAL:
            data = [MFSequenceWriter dataClustal:inSequences attributes:attrs];
            break;
        case MFSequenceFormatGDE:
            data = [MFSequenceWriter dataGDE:inSequences attributes:attrs];
            break;
        case MFSequenceFormatNBRF:
            data = [MFSequenceWriter dataNBRF:inSequences attributes:attrs];
            break;
        case MFSequenceFormatSTOCKHOLM:
            data = [MFSequenceWriter dataStockholm:inSequences attributes:attrs];
            break;
        default:
            NSLog(@"Format not recognized");
            break;
    }
    
    [formats release];
    return data;
}

+ (NSString *) string:(MFSequenceSet *) inSequences withFormat:(MFSequenceFormat)format attributes:(NSDictionary*)attrs{
    NSString *data = nil;
    
    NSArray *formats = [[NSArray alloc] initWithObjects:MFSequenceFormatArray];
    switch (format) {
        case MFSequenceFormatFASTA:
            data = [MFSequenceWriter stringFasta:inSequences attributes:attrs];
            break;
        case MFSequenceFormatNEXUS:
            data = [MFSequenceWriter stringNexus:inSequences attributes:attrs];
            break;
        case MFSequenceFormatPHYLIP:
            data = [MFSequenceWriter stringPhylip:inSequences attributes:attrs];
            break;
        case MFSequenceFormatCLUSTAL:
            data = [MFSequenceWriter stringClustal:inSequences attributes:attrs];
            break;
        case MFSequenceFormatMEGA:
            data = [MFSequenceWriter stringMega:inSequences attributes:attrs];
            break;
        case MFSequenceFormatGDE:
            data = [MFSequenceWriter stringGDE:inSequences attributes:attrs];
            break;
        case MFSequenceFormatNBRF:
            data = [MFSequenceWriter stringNBRF:inSequences attributes:attrs];
            break;
        case MFSequenceFormatSTOCKHOLM:
            data = [MFSequenceWriter stringStockholm:inSequences attributes:attrs];
            break;
        default:
            NSLog(@"Format not recognized");
            break;
    }
    
    [formats release];
    return data;
}

#pragma mark FASTA

+ (void)writeFasta:(MFSequenceSet *) inSequences toFile:(NSString *)file attributes:(NSDictionary*)attrs{
    NSString *fastaString = [MFSequenceWriter stringFasta:inSequences attributes:attrs];
    [fastaString writeToFile:file atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

+ (NSData *) dataFasta:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSString *string = [MFSequenceWriter stringFasta:inSequences attributes:attrs];
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    return nsdata;
}

+ (NSString *) stringFasta:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSMutableArray *sequences = [inSequences sequences];
    NSMutableString	*fastaString = [NSMutableString string];
    
    NSRange range = NSMakeRange(0, [[inSequences sequenceAt:0] length]);
    if( [attrs objectForKey:MFSequenceWriterRange] ){
        range = [[attrs objectForKey:MFSequenceWriterRange]rangeValue];
    }
    else if( [[attrs objectForKey:MFSequenceWriterIgnoreLeadingGaps]boolValue] ){
        NSUInteger index = [inSequences indexFirstNonGap];
        range.location = index;
        range.length -= index;
    }
    
    for (MFSequence *sequence in sequences) {
        [fastaString appendFormat:@">%@\r",[sequence name]];
        [fastaString appendFormat:@"%@\r",[sequence subSequenceWithRange:range]];
        
    }
    return fastaString;
}

#pragma mark NEXUS

+ (NSData *) dataNexus:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSString *string = [MFSequenceWriter stringNexus:inSequences attributes:attrs];
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    return nsdata;
}

+ (NSString *) stringNexus:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSMutableArray *sequences = [inSequences sequences];
    NSMutableString	*string = [NSMutableString string];
    
    [string appendString:@"#NEXUS\r\r"];
    
    
    [string appendString:@"BEGIN DATA;\r"];
    
    NSRange range = NSMakeRange(0, [[inSequences sequenceAt:0] length]);
    if( [attrs objectForKey:MFSequenceWriterRange] ){
        range = [[attrs objectForKey:MFSequenceWriterRange]rangeValue];
    }
    else if( [[attrs objectForKey:MFSequenceWriterIgnoreLeadingGaps]boolValue] ){
        NSUInteger index = [inSequences indexFirstNonGap];
        range.location = index;
        range.length -= index;
    }
    
	[string appendFormat:@"\tDimensions ntax=%ld nchar=%ld;\r", [inSequences size], range.length];
    if( [[inSequences sequenceAt:0] dataType] != nil ){
        if( [[inSequences sequenceAt:0] translated]){
            [string appendFormat:@"\tFormat datatype=protein gap=%@;\r", [[[inSequences sequenceAt:0] dataType]gap] ];
        }
        else if( [[[inSequences sequenceAt:0] dataType] isKindOfClass:[MFNucleotide class]]  ){
            [string appendFormat:@"\tFormat datatype=nucleotide gap=%@;\r", [[[inSequences sequenceAt:0] dataType]gap] ];
        }
        else{
            [string appendFormat:@"\tFormat datatype=protein gap=%@;\r", [[[inSequences sequenceAt:0] dataType]gap] ];
        }
    }

	[string appendString:@"\tMatrix\r"];
    
    NSInteger maxlen = 0;
    for (MFSequence *sequence in sequences) {
        NSString *name = [sequence name];
        NSInteger len = [name length];
        NSRange whiteSpaceRange = [name rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
        if (whiteSpaceRange.location != NSNotFound) {
            len+=2;
        }
        if(len > maxlen){
            maxlen = len;
        }
    }
    
    
    for (MFSequence *sequence in sequences) {
        NSString *name = [sequence name];
        NSInteger len = [name length];
        NSRange whiteSpaceRange = [name rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
        if (whiteSpaceRange.location != NSNotFound) {
            [string appendFormat:@"\t\'%@\'",[sequence name]];
            len+=2;
        }
        else{
            [string appendFormat:@"\t%@",[sequence name]];
        }
        for ( int i = 0; i < maxlen-len+2; i++) {
            [string appendFormat:@" "];
        }
        
        [string appendFormat:@"%@\r",[sequence subSequenceWithRange:range]];
        
    }
    
    [string appendString:@";\rEND;\r"];
    return string;
}

#pragma mark Phylip

+ (NSData *) dataPhylip:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSString *string = [MFSequenceWriter stringPhylip:inSequences attributes:attrs];
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    return nsdata;
}

// sequential
+ (NSString *) stringPhylip:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSMutableArray *sequences = [inSequences sequences];
    NSMutableString	*string = [NSMutableString string];
    
    NSRange range = NSMakeRange(0, [[inSequences sequenceAt:0] length]);
    if( [attrs objectForKey:MFSequenceWriterRange] ){
        range = [[attrs objectForKey:MFSequenceWriterRange]rangeValue];
    }
    else if( [[attrs objectForKey:MFSequenceWriterIgnoreLeadingGaps]boolValue] ){
        NSUInteger index = [inSequences indexFirstNonGap];
        range.location = index;
        range.length -= index;
    }
    
    [string appendFormat:@" %ld %ld\r", [inSequences size],range.length];
    
    NSInteger maxlen = 0;
    for (MFSequence *sequence in sequences) {
        NSString *name = [sequence name];
        NSInteger len = [name length];
        NSRange whiteSpaceRange = [name rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
        if (whiteSpaceRange.location != NSNotFound) {
            len+=2;
        }
        if(len > maxlen){
            maxlen = len;
        }
    }
    
    for (MFSequence *sequence in sequences) {
        NSString *name = [sequence name];
        NSInteger len = [name length];
        NSRange whiteSpaceRange = [name rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
        if (whiteSpaceRange.location != NSNotFound) {
            [string appendFormat:@"\"%@\"",[sequence name]];
            len+=2;
        }
        else{
            [string appendFormat:@"%@",[sequence name]];
        }
        for ( int i = 0; i < maxlen-len+5; i++) {
            [string appendFormat:@" "];
        }
        
        [string appendFormat:@"%@\r",[sequence subSequenceWithRange:range]];
    }
    return string;
}

#pragma mark MEGA

+ (NSData *) dataMega:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSString *string = [MFSequenceWriter stringMega:inSequences attributes:attrs];
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    return nsdata;
}

+ (NSString *) stringMega:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSMutableArray *sequences = [inSequences sequences];
    NSMutableString	*megaString = [NSMutableString string];
    
    NSRange range = NSMakeRange(0, [[inSequences sequenceAt:0] length]);
    if( [attrs objectForKey:MFSequenceWriterRange] ){
        range = [[attrs objectForKey:MFSequenceWriterRange]rangeValue];
    }
    else if( [[attrs objectForKey:MFSequenceWriterIgnoreLeadingGaps]boolValue] ){
        NSUInteger index = [inSequences indexFirstNonGap];
        range.location = index;
        range.length -= index;
    }
    
    [megaString appendString:@"#mega\r"];
    
    for (MFSequence *sequence in sequences) {
        [megaString appendFormat:@"#%@\r",[sequence name]];
        [megaString appendFormat:@"%@\r",[sequence subSequenceWithRange:range]];
    }
    return megaString;
}

#pragma mark Clustal

+ (NSData *) dataClustal:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSString *string = [MFSequenceWriter stringClustal:inSequences attributes:attrs];
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    return nsdata;
}

// sequential
+ (NSString *) stringClustal:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSMutableArray *sequences = [inSequences sequences];
    NSMutableString	*string = [NSMutableString string];
    
    NSRange alignmentRange = NSMakeRange(0, [[inSequences sequenceAt:0] length]);
    if( [attrs objectForKey:MFSequenceWriterRange] ){
        alignmentRange = [[attrs objectForKey:MFSequenceWriterRange]rangeValue];
    }
    else if( [[attrs objectForKey:MFSequenceWriterIgnoreLeadingGaps]boolValue] ){
        NSUInteger index = [inSequences indexFirstNonGap];
        alignmentRange.location = index;
        alignmentRange.length -= index;
    }
    
    NSUInteger len = alignmentRange.length;
    
    [string appendFormat:@"CLUSTAL W Generated by Seqotron ntax %tu nchar %tu\r\r", [inSequences size], len];
    
    NSInteger maxlenName = 0;
    for (MFSequence *sequence in sequences) {
        NSString *name = [[sequence name]stringByReplacingOccurrencesOfString:@" " withString:@""];
        NSInteger len = [name length];
        if(len > maxlenName){
            maxlenName = len;
        }
    }
    

    for ( NSUInteger i = 0; i < len; i+=60) {
        for (MFSequence *sequence in sequences) {
            NSString *name = [[sequence name]stringByReplacingOccurrencesOfString:@" " withString:@""];
            [string appendString:name];
        
            for ( int i = 0; i < maxlenName-[name length]+5; i++) {
                [string appendFormat:@" "];
            }
            NSString *seq = [sequence subSequenceWithRange:alignmentRange];
            NSRange range = NSMakeRange(i, 60);
            if( i + 60 > [seq length]){
                range.length = [seq length] - i;
            }
            
            [string appendString:[seq substringWithRange:range ] ];
            
            [string appendFormat:@" %tu\r", i+range.length];
        }
    }
    return string;
}

#pragma mark GDE Flat

+ (void)writeGDE:(MFSequenceSet *) inSequences toFile:(NSString *)file attributes:(NSDictionary*)attrs{
    NSString	*str = [MFSequenceWriter stringGDE:inSequences attributes:attrs];
    [str writeToFile:file atomically:NO encoding:NSUTF8StringEncoding error:nil];
}

+ (NSData *) dataGDE:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSString *string = [MFSequenceWriter stringGDE:inSequences attributes:attrs];
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    return nsdata;
}

+ (NSString *) stringGDE:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSMutableArray *sequences = [inSequences sequences];
    NSMutableString	*str = [NSMutableString string];
    
    NSRange range = NSMakeRange(0, [[inSequences sequenceAt:0] length]);
    if( [attrs objectForKey:MFSequenceWriterRange] ){
        range = [[attrs objectForKey:MFSequenceWriterRange]rangeValue];
    }
    else if( [[attrs objectForKey:MFSequenceWriterIgnoreLeadingGaps]boolValue] ){
        NSUInteger index = [inSequences indexFirstNonGap];
        range.location = index;
        range.length -= index;
    }
    
    for (MFSequence *sequence in sequences) {
        [str appendFormat:@"#%@\r",[sequence name]];
        [str appendFormat:@"%@\r",[sequence subSequenceWithRange:range]];
    }
    return str;
}

#pragma mark NBRF

+ (NSData *) dataNBRF:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSString *string = [MFSequenceWriter stringNBRF:inSequences attributes:attrs];
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    return nsdata;
}

+ (NSString *) stringNBRF:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSMutableArray *sequences = [inSequences sequences];
    NSMutableString	*nbrfString = [NSMutableString string];
    
    NSRange range = NSMakeRange(0, [[inSequences sequenceAt:0] length]);
    if( [attrs objectForKey:MFSequenceWriterRange] ){
        range = [[attrs objectForKey:MFSequenceWriterRange]rangeValue];
    }
    else if( [[attrs objectForKey:MFSequenceWriterIgnoreLeadingGaps]boolValue] ){
        NSUInteger index = [inSequences indexFirstNonGap];
        range.location = index;
        range.length -= index;
    }
    
    NSString *type = @"P1";
    if( [[[sequences objectAtIndex:0] dataType] isKindOfClass:[MFNucleotide class]]){
        type = @"D1";
    }
    
    for (MFSequence *sequence in sequences) {
        [nbrfString appendFormat:@">%@;%@\r",type, [sequence name]];
        [nbrfString appendFormat:@"%@\r",[sequence name]];
        [nbrfString appendFormat:@"%@*\r",[sequence subSequenceWithRange:range]];
    }
    return nbrfString;
}


#pragma mark Stockholm

+ (NSData *) dataStockholm:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSString *string = [MFSequenceWriter stringStockholm:inSequences attributes:attrs];
    NSData *nsdata = [string dataUsingEncoding:NSUTF8StringEncoding];
    return nsdata;
}

+ (NSString *) stringStockholm:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs{
    NSMutableArray *sequences = [inSequences sequences];
    NSMutableString	*stockholmString = [NSMutableString string];
    
    NSUInteger spacing = 5;
    NSUInteger maxLength = 0;
    for (MFSequence *sequence in sequences) {
        if( [[sequence name]length] > maxLength ){
            maxLength = [[sequence name] length];
        }
    }
    [stockholmString appendString:@"# STOCKHOLM 1.0"];
    for (MFSequence *sequence in sequences) {
        NSString *name = [[[sequence name]componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]componentsJoinedByString:@"_"];
        [stockholmString appendFormat:@"%@", name];
        for ( NSUInteger i = 0; i < maxLength - [name length] + spacing ; i++ ) {
            [stockholmString appendString:@" "];
        }
        [stockholmString appendFormat:@"%@\r", [sequence sequenceString]];
    }
    [stockholmString appendString:@"//"];
    return stockholmString;
}
@end
