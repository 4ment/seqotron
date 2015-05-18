//
//  MFDistanceMatrix.h
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

#import <Foundation/Foundation.h>

#import "MFSequence.h"

typedef enum MFDistanceMatrixModel: NSUInteger {
    MFDistanceMatrixModelRAW  = 0,
    MFDistanceMatrixModelJC69 = 1,
    MFDistanceMatrixModelK2P  = 2,
    
} MFDistanceMatrixModel;

@interface MFDistanceMatrix : NSObject{
    float **_matrix;
    NSUInteger _dimension;
    NSArray *_sequences;
}

@property (readonly)NSUInteger dimension;

-(id)initWithSequencesFromArray:(NSArray*)sequences;

-(float)valueForRow:(NSUInteger)aRow column:(NSUInteger)aColumn;

- (void)calculateDistances;

- (float)calculatePairwiseDistanceBetween:(MFSequence*)sequence1 and:(MFSequence*)sequence2;

- (NSString*)nameAtIndex:(NSUInteger)index;

- (float**)floatMatrix;

- (void)print;


@end
