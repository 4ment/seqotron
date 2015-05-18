//
//  MFSequences.h
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

#import <Foundation/Foundation.h>

#import "MFDataType.h"

#import "MFSequence.h"

@interface MFSequenceSet : NSObject{
    NSMutableArray *_sequences;
    NSMutableDictionary *_annotations;
}

-(MFDataType*)guessDataType;

- (id)initWithCapacity:(NSUInteger)capacity;

- (id)initWithSequences:(NSArray*)sequence;

-(NSUInteger)count;

- (void) addAnnotation:(NSString *)annotation forKey: (NSString *) key;

- (id) annotationForKey: (NSString *) key;

-(NSMutableArray*)sequences;

-(MFSequence*)sequenceAt:(NSUInteger)index;

-(NSArray*)sequencesAtIndexes:(NSIndexSet*)indexes;

-(void)addSequence:(MFSequence*)aSequence;

-(void)insertSequence:(MFSequence*)aSequence atIndex:(NSUInteger)index;

-(void)insertSequences:(NSArray*)someSequences atIndexes:(NSIndexSet*)indexes;

-(void)removeSequence:(MFSequence*)aSequence;

-(void)removeSequenceAtIndex:(NSUInteger)index;

-(void)removeSequencesInRange:(NSRange)range;

-(void)removeSequencesAtIndexes:(NSIndexSet*)indexes;

- (NSUInteger)indexFirstNonGap;

-(void)empty;

-(NSUInteger)size;

@end
