//
//  MFSequence.h
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

@interface MFSequence : NSObject<NSCopying> {
	NSMutableString *_sequence;
	NSString *_name;
    MFDataType *_dataType;
    
    NSDictionary *_genetictable;
    BOOL _translated;
}

@property (readonly) NSMutableString *sequence;
@property (copy) NSString *name;
@property (retain) MFDataType *dataType;
@property BOOL translated;

- (id)initWithString:(NSString *)aSequence name:(NSString *)aName dataType:(MFDataType*)aDataType;

- (id)initWithString:(NSString *)aSequence name:(NSString *)aName;

- (id)initWithName:(NSString *)aName;

- (NSString*)sequenceString;

- (NSUInteger)length;

- (NSString *)subCodonSequenceWithRange:(NSRange)range;

- (NSString *)subSequenceWithRange:(NSRange)range;

- (void)insertResidues:(NSString*)residues AtIndex:(NSUInteger)index;

- (void)insertGaps:(NSUInteger)ngaps AtIndex:(NSUInteger)index;

- (void)appendGaps:(NSUInteger)ngaps;

- (void)trimEndGaps;

-(void)removeAllGaps;

- (unichar)residueAt:(NSUInteger)index;

- (NSString*)residueStringAt:(NSUInteger)index;

- (void)deleteResiduesInRange:(NSRange)range;

- (void)deleteResiduesAtIndexes:(NSIndexSet*)indexes;

- (void)replaceCharactersInRange:(NSRange)range withString:(NSString*)residues;

-(void)replaceOccurencesOfString:(NSString*)target withString:(NSString*)replacement options:(NSStringCompareOptions)options range:(NSRange)range;

- (void)setGeneticTable: (NSDictionary*)geneticTable;


- (void)reverse;

- (void)complement;

-(void)translateFinal;

- (NSRange)rangeOfSequence:(NSString*)string options:(NSStringCompareOptions)mask range:(NSRange)range;


- (void)concatenateString:(NSString*)aString;

- (void)concatenate:(MFSequence*)aSequence;

- (void)insert:(NSString*)string atIndex:(NSUInteger)index;


- (void)remove:(NSRange)range;


//- (void)removeAt:(NSUInteger)index;

@end