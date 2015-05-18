//
//  MFDistanceMatrix.m
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

#import "MFDistanceMatrix.h"

#import "MFSequence.h"

@implementation MFDistanceMatrix
@synthesize dimension = _dimension;


-(id)initWithSequencesFromArray:(NSArray*)sequences{
    if( self = [super init] ){
        _dimension = [sequences count];
        _matrix = malloc(_dimension*sizeof(float*));
        for ( NSUInteger i = 0; i < _dimension; i++ ) {
            _matrix[i] = calloc(_dimension, sizeof(float));
        }
        _sequences = [sequences retain];
    }
    return self;
}

-(void)dealloc{
    NSLog(@"MFDistanceMatrix dealloc");
    for ( NSUInteger i = 0; i < _dimension; i++ ) {
        free(_matrix[i]);
    }
    free(_matrix);
    [_sequences release];
    [super dealloc];
}

- (float)calculatePairwiseDistanceBetween:(MFSequence*)sequence1 and:(MFSequence*)sequence2{
    NSUInteger d = 0;
    NSUInteger n = 0;
    const char *c1 = [[sequence1 sequence]UTF8String];
    const char *c2 = [[sequence2 sequence]UTF8String];
    MFDataType *dataType = sequence1.dataType;
    NSUInteger dimension = [sequence1 length];
    
    for ( NSUInteger k = 0; k < dimension; k++ ) {
        if( [dataType isKnownChar:c1[k]] && [dataType isKnownChar:c2[k]] ){
            if(c1[k] != c2[k] ){
                d++;
            }
            n++;
        }
    }
    return (float)d/n;
}


-(void)calculateDistances{
    for ( NSUInteger i = 0; i < _dimension; i++ ) {
        MFSequence *seq1 = [_sequences objectAtIndex:i];
        
        for ( NSUInteger j = i+1; j < _dimension; j++ ) {
            MFSequence *seq2 = [_sequences objectAtIndex:j];

            _matrix[i][j] = _matrix[j][i] = [self calculatePairwiseDistanceBetween:seq1 and:seq2];
        }
    }
}

- (float**)floatMatrix{
    return _matrix;
}

- (NSString*)nameAtIndex:(NSUInteger)index{
    return [[_sequences objectAtIndex:index]name];
}

- (void)print{
    for ( NSUInteger i = 0; i < _dimension; i++ ) {
        for ( NSUInteger j = 0; j < _dimension; j++ ) {
            printf("%f ", _matrix[i][j]);
        }
        printf("\n");
    }
}

-(float)valueForRow:(NSUInteger)aRow column:(NSUInteger)aColumn{
    return _matrix[aRow][aColumn];
}

#pragma mark *** C functions ***

float calculatePairwiseDistance(const char *c1, const char *c2, NSUInteger dimension){
    NSUInteger d = 0;
    NSUInteger n = 0;
    
    for ( NSUInteger k = 0; k < dimension; k++ ) {
        
        if(   (*c1 == 'A' || *c1 == 'C' || *c1 == 'G' || *c1 == 'T' || *c1 == 'U')
           && (*c2 == 'A' || *c2 == 'C' || *c2 == 'G' || *c2 == 'T' || *c2 == 'U') ){
            if( *c1 != *c2 ){
                d++;
            }
            n++;
        }
        
        c1++;
        c2++;
    }
    return (float)d/n;
}



@end
