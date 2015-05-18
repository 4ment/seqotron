//
//  MFSequences.m
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

#import "MFSequenceSet.h"

#include "MFSequence.h"
#include "MFProtein.h"
#include "MFNucleotide.h"

@implementation MFSequenceSet



- (id)init{
	if ( (self = [super init]) ) {
		_sequences = [[NSMutableArray alloc] init];
        _annotations = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithCapacity:(NSUInteger)capacity{
	if ( (self = [super init]) ) {
        _sequences = [[NSMutableArray alloc] initWithCapacity:capacity];
        _annotations = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (id)initWithSequences:(NSArray*)sequences{
    if ( (self = [super init]) ) {
        _sequences = [[NSMutableArray alloc] initWithArray:sequences];
        _annotations = [[NSMutableDictionary alloc] init];
	}
	return self;
}

- (void)dealloc{
	[_sequences release];
    [_annotations release];
	[super dealloc];
}

-(MFDataType*)guessDataType{
    __block NSUInteger count = 0;
    __block NSUInteger countAA = 0;

    NSCharacterSet *nucSet  = [NSCharacterSet characterSetWithCharactersInString: @"ACTGU"];
    NSCharacterSet *aaSet   = [NSCharacterSet characterSetWithCharactersInString: @"ACDEFGHIKLMNPQERSTVWY"];
    
    for (int i = 0; i < [_sequences count]; i++ ) {
        NSString *sequence = [[_sequences objectAtIndex:i] sequenceString];
        
        [sequence enumerateSubstringsInRange:NSMakeRange(0,[sequence length])
                                      options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                                   usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                       if ( [substring rangeOfCharacterFromSet: nucSet].location != NSNotFound ){
                                           count++;
                                       }
                                       if ( [substring rangeOfCharacterFromSet: aaSet].location != NSNotFound ){
                                           countAA++;
                                       }
                                   }];
    }
    
    MFDataType *dataType;
    if( (CGFloat)count/countAA > 0.8 ){
        dataType = [[MFNucleotide alloc]init];
    }
    else {
        dataType = [[MFProtein alloc]init];
    }
    for (MFSequence *sequence in _sequences) {
        [sequence setDataType:dataType];
    }
    return [dataType autorelease];
}

- (void) addAnnotation:(NSString*)annotation forKey: (NSString*) key{
    [_annotations setObject:annotation forKey:key];
}

- (NSString*) annotationForKey:(NSString*) key{
    return [_annotations objectForKey:key];
}

-(NSUInteger)count{
    return [_sequences count];
}

-(NSMutableArray*)sequences{
    return _sequences;
}

-(NSArray*)sequencesAtIndexes:(NSIndexSet*)indexes{
    return [_sequences objectsAtIndexes:indexes];
}

-(MFSequence*)sequenceAt:(NSUInteger)index{
    return [_sequences objectAtIndex:index];
}

-(void)addSequence:(MFSequence*)aSequence{
    [_sequences addObject:aSequence];
}

-(void)insertSequence:(MFSequence*)aSequence atIndex:(NSUInteger)index{
    [_sequences insertObject:aSequence atIndex:index];
}

-(void)insertSequences:(NSArray*)someSequences atIndexes:(NSIndexSet*)indexes{
    [_sequences insertObjects:someSequences atIndexes:indexes];
}

-(void)removeSequence:(MFSequence*)aSequence{
    [_sequences removeObject:aSequence];
}

-(void)removeSequenceAtIndex:(NSUInteger)index{
    [_sequences removeObjectAtIndex:index];
}

-(void)removeSequencesInRange:(NSRange)range{
    [_sequences removeObjectsInRange:range];
}

-(void)removeSequencesAtIndexes:(NSIndexSet*)indexes{
    [_sequences removeObjectsAtIndexes:indexes];
}

- (void)concatenate:(MFSequenceSet*)someSequences{
    if( [self size] != [someSequences size] ){
        return;
    }
    for ( int i = 0; i < [_sequences count]; i++ ) {
        MFSequence *seq = [_sequences objectAtIndex:i];
        [seq concatenate: [someSequences sequenceAt:i]];
    }
}


-(void)insertGaps:(NSUInteger)nGaps atSite:(NSUInteger)site inRange:(NSRange)aRange{
    NSMutableString *gaps = [NSMutableString stringWithCapacity:nGaps];
    for ( NSUInteger i = 0; i < nGaps; i++ ) {
        [gaps appendString:@"-"];
    }
    
    for ( NSUInteger i = 0; i < aRange.length; i++ ) {
        MFSequence *sequence = [self sequenceAt: aRange.location+i];
        [sequence insert:gaps atIndex:site];
    }
    [self pad];
}



- (void)pad{
    if( [_sequences count] > 0 ){
        NSRange range;
        NSUInteger maxLength = [self maxLength: _sequences];
        
        
        for (MFSequence *sequence in _sequences) {
            if([sequence length] > maxLength ){
                range.location = maxLength;
                range.length   = [sequence length] - maxLength;
                [sequence deleteResiduesInRange:range];
            }
            else if( [sequence length] < maxLength ){
                NSUInteger nGaps = maxLength - [sequence length];
                [sequence appendGaps:nGaps];
            }
        }
    }
}

// return the maximum length excuding the last gaps
-(NSUInteger)maxLength:(NSArray*)sequences{
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


- (NSUInteger)indexFirstNonGap{
    MFDataType *datatype = [[_sequences objectAtIndex:0]dataType];
    for ( NSUInteger i = 0; i < [[_sequences objectAtIndex:0]length]; i++ ) {
        for (MFSequence *sequence in _sequences) {
            if( ![datatype isGap:[sequence residueStringAt:i]] ){
                return i;
            }
        }
    }
    return NSNotFound;
}

-(void)empty{
    [_sequences removeAllObjects];
}

-(NSUInteger)size{
    return [_sequences count];
}



@end
