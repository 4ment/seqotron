//
//  MFK83DistanceMatrix.m
//  Seqotron
//
//  Created by Mathieu on 11/05/2015.
//  Copyright (c) 2015 Mathieu Fourment. All rights reserved.
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

#import "MFK83DistanceMatrix.h"

@implementation MFK83DistanceMatrix

- (float)calculatePairwiseDistanceBetween:(MFSequence*)sequence1 and:(MFSequence*)sequence2{
    float d = 0;
    NSUInteger n = 0;
    MFDataType *dataType = sequence1.dataType;
    NSUInteger dimension = [sequence1 length];
    char c1,c2;
    for ( NSUInteger k = 0; k < dimension; k++ ) {
        c1 = [[sequence1 sequence ]characterAtIndex:k];
        c2 = [[sequence2 sequence ]characterAtIndex:k];
        if( [dataType isKnownChar:c1] && [dataType isKnownChar:c2] ){
            if( c1 != c2 ){
                d++;
            }
            n++;
        }
    }
    float p = d/n;
    return -log(1.0-p-0.2*p*p);
}

@end
