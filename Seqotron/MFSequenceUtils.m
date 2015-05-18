//
//  MFSequenceUtils.m
//  Seqotron
//
//  Created by Mathieu Fourment on 29/10/2014.
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

#import "MFSequenceUtils.h"

#import "MFSequence.h"

@implementation MFSequenceUtils

+ (NSUInteger)maxLength:(NSArray*)sequences{
    NSUInteger maxLength = 0;
    if( [sequences count] != 0 ){
        //
        for (MFSequence *sequence in sequences) {
            for ( NSInteger i = [sequence length]-1; i >= 0; i--) {
                if( [sequence residueAt:i] != '-' ){
                    if( i > maxLength ){
                        maxLength = i;
                    }
                    break;
                }
            }
        }
    }
    return maxLength+1;
}

+ (NSUInteger)numberOfEmptyColumnsAtFront:(NSArray*)sequences{
    MFDataType *datatype = [[sequences objectAtIndex:0]dataType];
    for ( NSUInteger i = 0; i < [[sequences objectAtIndex:0]length]; i++ ) {
        for (MFSequence *sequence in sequences) {
            if( ![datatype isGap:[sequence residueStringAt:i]] ){
                return i;
            }
        }
    }
    return NSNotFound;
}
    

+ (BOOL)isStartingWithOneGap:(NSArray*)sequences{
    for (MFSequence *sequence in sequences) {
        if ( [sequence residueAt:0] != '-' ) {
            return NO;
        }
    }
    return YES;
}

// test if the selection is made of gaps only and is located at the end of the aligment
+ (BOOL)isEmptyBlockAtTheEnd:(NSArray*)sequences inRange:(NSRange)range{
    if( [sequences count] > 0 ){
        
        // test if there is residues behind the selection that are not gaps
        if( range.location+range.length < [[sequences objectAtIndex:0] length]){
            for ( NSUInteger i = 0; i < [sequences count]; i++ ) {
                MFSequence *sequence = [sequences objectAtIndex: i];
    
                for ( NSUInteger j = range.location+range.length; j < [sequence length]; j++ ) {
                    if([sequence residueAt:j] != '-') return NO;
                }
            }
        }
        
        // At this point selection can be gaps only or contain residues but not followed by gaps (it could be at the end)
        for ( NSUInteger i = 0; i < [sequences count]; i++ ) {
            MFSequence *sequence = [sequences objectAtIndex: i];
            NSUInteger j = range.location;
            for ( ; j < range.location+range.length; j++ ) {
                if([sequence residueAt:j] != '-') return NO;
            }
        }
        return YES;
    }
    return NO;
}

+ (void)pad:(NSArray*)sequences{
    if( [sequences count] != 0 ){
        NSUInteger maxLength = [MFSequenceUtils maxLength:sequences];
        
        if( maxLength != 0 ){
            for (MFSequence *sequence in sequences) {
                if( [sequence length] >  maxLength ){
                    NSRange range;
                    range.location = maxLength;
                    range.length   = [sequence length] - maxLength;
                    [sequence deleteResiduesInRange:range];
                }
                else if( [sequence length] <  maxLength ){
                    NSUInteger nGaps = maxLength - [sequence length];
                    [sequence appendGaps:nGaps];
                }
            }
        }
    }
}

+ (void)deleteFrontEmptyColumns:(NSArray*)sequences{
    NSUInteger empties = [MFSequenceUtils numberOfEmptyColumnsAtFront:sequences];
    if( empties > 0 ){
        NSRange range = NSMakeRange(0, empties);
        for (MFSequence *sequence in sequences) {
            [sequence deleteResiduesInRange:range];
        }
    }
}

+ (MFSequence*)consensus:(NSArray*)sequences withDescription:(NSString*)desc{
    NSInteger len = [[sequences objectAtIndex:0]length];
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    NSMutableString *seqString = [[NSMutableString alloc]initWithCapacity:len];
    for ( NSInteger i = 0; i < len; i++ ) {
        for (MFSequence *sequence in sequences) {
            NSString *res = [sequence residueStringAt:i];
            if( [dict objectForKey:res]){
                [dict setObject:[NSNumber numberWithInt:[[dict objectForKey:res] intValue] + 1] forKey:res];
            }
            else {
                [dict setObject:[NSNumber numberWithInt:0] forKey:res];
            }
        }
        __block NSInteger max = -1;
        __block NSMutableArray *residues;
        [dict enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop){
            if( [obj intValue] >= max){
                max = [obj intValue];
                [residues addObject:key];
            }
        }];
        
        if( [residues count] == 1 ){
            [seqString appendString:[residues objectAtIndex:0]];
        }
        else {
            [residues removeObjectsInArray:[NSArray arrayWithObjects:@"-",@"?",nil]];
            // it was only -s and ?s
            if ([residues count] == 0){
                [seqString appendString:@"?"];
            }
            // it was a unique residue AND - and/or ?
            else if ([residues count] == 1){
                [seqString appendString:[residues objectAtIndex:0]];
            }
            else {
                //TODO: should use ambiguity symbols
                [seqString appendString:[residues objectAtIndex:0]];
            }
        }
        
    }
    
    MFSequence *sequence = [[MFSequence alloc] initWithString:seqString name:desc];
    [seqString release];
    return [sequence autorelease];
}

@end
