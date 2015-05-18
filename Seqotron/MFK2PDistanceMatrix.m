//
//  MFK2PDistanceMatrix.m
//  Seqotron
//
//  Created by Mathieu on 5/12/2014.
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

#import "MFK2PDistanceMatrix.h"

@implementation MFK2PDistanceMatrix

- (float)calculateDistanceBetween:(MFSequence*)sequence1 and:(MFSequence*)sequence2{
    float transversion = 0;
    float transition   = 0;
    float n = 0;
    const char *c1 = [[sequence1 sequence]UTF8String];
    const char *c2 = [[sequence2 sequence]UTF8String];
    MFDataType *dataType = sequence1.dataType;
    NSUInteger dimension = [sequence1 length];
    
    for ( NSUInteger k = 0; k < dimension; k++ ) {
        if( [dataType isKnownChar:c1[k]] && [dataType isKnownChar:c2[k]] ){
            if( c1[k] != c2[k]  ){
                if (   (c1[k] == 'A' && c2[k] == 'G')    // A G
                    || (c1[k] == 'G' && c2[k] == 'A')    // G A
                    || (c1[k] == 'C' && c2[k] == 'T')    // C T
                    || (c1[k] == 'T' && c2[k] == 'C')    // T C
                    || (c1[k] == 'C' && c2[k] == 'U')    // C U
                    || (c1[k] == 'U' && c2[k] == 'C') ){ // U C
                    transition++;
                }
                else {
                    transversion++;
                }
            }
            n++;
            
        }
    }
    return 0.5 * log(1.0/(1-(2*transition-transversion)/n)) + 0.25*log(1/(1-2*transversion/n));
}

@end
