//
//  MFNeighborJoining.h
//  Seqotron
//
//  Created by Mathieu on 3/12/2014.
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

#import "MFDistanceMatrix.h"
#import "MFTree.h"

@interface MFNeighborJoining : NSObject{
    MFDistanceMatrix *_distanceMatrix;
    NSUInteger _dimension;
    NSMutableArray *_nodes;
    
    NSUInteger _ncluster;
    NSUInteger _imin;
    NSUInteger _jmin;
    
    float **_matrix;
    float *_r;
    int *_alias;
}


-(id)initWithDistanceMatrix:(MFDistanceMatrix*) matrix;

- (MFTree*)inferTree;

@end
