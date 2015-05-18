//
//  MFSequenceWriter.h
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

#import <Foundation/Foundation.h>

#import "MFDefines.h"
#import "MFSequenceSet.h"

extern NSString *MFSequenceWriterRange;
extern NSString *MFSequenceWriterIgnoreLeadingGaps;

@interface MFSequenceWriter : NSObject

+ (NSData *) data:(MFSequenceSet *) inSequences withFormat:(MFSequenceFormat)format attributes:(NSDictionary*)attrs;

+ (NSString *) string:(MFSequenceSet *) inSequences withFormat:(MFSequenceFormat)format attributes:(NSDictionary*)attrs;


#pragma mark FASTA

+ (void)writeFasta:(MFSequenceSet *) sequences toFile:(NSString *)file attributes:(NSDictionary*)attrs;

+ (NSString*) stringFasta:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

+ (NSData*) dataFasta:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

#pragma mark Nexus

+ (NSString*) stringNexus:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

+ (NSData*) dataNexus:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

#pragma mark Phylip

+ (NSString*) stringPhylip:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

+ (NSData*) dataPhylip:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

#pragma mark MEGA

+ (NSData *) dataMega:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

+ (NSString *) stringMega:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

#pragma mark GDE

+ (NSData *) dataGDE:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

+ (NSString *) stringGDE:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

#pragma mark NBRF

+ (NSData *) dataNBRF:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

+ (NSString *) stringNBRF:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

#pragma mark Stockholm

+ (NSData *) dataStockholm:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

+ (NSString *) stringStockholm:(MFSequenceSet *) inSequences attributes:(NSDictionary*)attrs;

@end
