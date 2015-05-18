//
//  MFNeighborJoining.m
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

#import "MFNeighborJoining.h"
#import "MFNode.h"

@implementation MFNeighborJoining

- (id)initWithDistanceMatrix:(MFDistanceMatrix*) matrix{
    if( self = [super init]){
        _distanceMatrix = [matrix retain];
        _dimension = matrix.dimension;
        _ncluster = matrix.dimension;
        _nodes = [[NSMutableArray alloc]initWithCapacity:_dimension];
        
        _alias = malloc(_dimension*sizeof(int));
        _r = malloc(_dimension*sizeof(float));
       
        for (NSUInteger i = 0; i < _dimension; i++) {
            MFNode *node = [[MFNode alloc]initWithName:[matrix nameAtIndex:i]];
            [_nodes addObject:node];
            [node release];
            _alias[i] = (int)i;
        }
        _matrix = [matrix floatMatrix];
    }
    return self;
}

- (void)dealloc{
    free(_alias);
    free(_r);
    [_nodes release];
    [_distanceMatrix release];
    [super dealloc];
}

- (MFTree*)inferTree{
    if( _ncluster != _dimension ){
        @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                       reason:[NSString stringWithFormat:@"Can not reuse %@ in MFNeighborJoining", NSStringFromSelector(_cmd)]
                                     userInfo:nil];
    }
    
    while( _ncluster > 2 ){
        // calculate net divergence
        for ( NSUInteger i = 0; i < _ncluster; i++ ) {
            _r[i] = 0;
            for ( NSUInteger j = 0; j < _ncluster; j++ ) {
                _r[i] += _matrix[ _alias[i] ][ _alias[j] ];
            }
        }

        [self findMinIndexes];
        
        MFNode *node  = [[MFNode alloc]initWithName:[NSString stringWithFormat:@"node%lu",_ncluster]];
        MFNode *inode = [_nodes objectAtIndex:_alias[_imin]];
        MFNode *jnode = [_nodes objectAtIndex:_alias[_jmin]];
        
        
        CGFloat il = (_matrix[ _alias[_imin] ][ _alias[_jmin] ] + (_r[_imin] - _r[_jmin])/(_ncluster-2))*0.5;
        CGFloat jl = _matrix[ _alias[_imin] ][ _alias[_jmin] ]-il;
        
        [inode setBranchLength:MAX(il,0)];
        [jnode setBranchLength:MAX(jl,0)];
        
        [node addChild:inode];
        [node addChild:jnode];
        
        [_nodes replaceObjectAtIndex:_alias[_imin] withObject:node];
        [_nodes replaceObjectAtIndex:_alias[_jmin] withObject:[NSNull null]];
        
        [node release];
        
        // Recalculate distance matrix
        
        NSUInteger k = 0;
        for ( ; k < _imin; k++) {
            int ak = _alias[k];
            _matrix[ak][_alias[_imin]] = _matrix[_alias[_imin]][ak] = (_matrix[ _alias[k] ][ _alias[_imin] ] + _matrix[ _alias[k] ][ _alias[_jmin] ] - _matrix[ _alias[_imin] ][ _alias[_jmin] ]) * 0.5;
        }
        for ( k++; k < _jmin; k++) {
            int ak = _alias[k];
            _matrix[ak][_alias[_imin]] = _matrix[_alias[_imin]][ak] = (_matrix[ _alias[k] ][ _alias[_imin] ] + _matrix[ _alias[k] ][ _alias[_jmin] ] - _matrix[ _alias[_imin] ][ _alias[_jmin] ]) * 0.5;
        }

        for ( k++; k < _ncluster; k++) {
            int ak = _alias[k];
            _matrix[ak][_alias[_imin]] = _matrix[_alias[_imin]][ak] = (_matrix[ _alias[k] ][ _alias[_imin] ] + _matrix[ _alias[k] ][ _alias[_jmin] ] - _matrix[ _alias[_imin] ][ _alias[_jmin] ]) * 0.5;
        }
        memmove(&_alias[_jmin], &_alias[_jmin+1], sizeof(int)*(_ncluster-_jmin-1));
    
        _ncluster--;
    }
    
    [self findMinIndexes];
    
    MFNode *node  = [[MFNode alloc]initWithName:@"node0"];
    MFNode *inode = [_nodes objectAtIndex:_alias[_imin]];
    MFNode *jnode = [_nodes objectAtIndex:_alias[_jmin]];
    
    CGFloat il = _matrix[ _alias[_imin] ][ _alias[_jmin] ]*0.5;
    CGFloat jl = _matrix[ _alias[_imin] ][ _alias[_jmin] ]-il;
    [inode setBranchLength:MAX(il,0)];
    [jnode setBranchLength:MAX(jl,0)];
    
    [node addChild:inode];
    [node addChild:jnode];
    
    MFTree *tree = [[MFTree alloc] initWithRoot:node];
    [node release];
    
    return [tree autorelease];
}

- (void)findMinIndexes{
    float min = INFINITY;
    _imin = 0;
    _jmin = 0;
    float denom = 1.0/(_ncluster-2);
    for( NSUInteger i = 0; i < _ncluster; i++ ){
        for( NSUInteger j = i+1; j < _ncluster; j++ ){
            float sij = _matrix[ _alias[i] ][ _alias[j] ] - (_r[i] + _r[j] ) * denom;
            
            if( sij < min ){
                _imin = i;
                _jmin = j;
                min  = sij;
            }
        }
    }
}

@end
