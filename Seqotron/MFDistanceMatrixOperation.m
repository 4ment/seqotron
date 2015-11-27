//
//  MFDistanceMatrixOperation.m
//  Seqotron
//
//  Created by Mathieu Fourment on 10/12/2014.
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

#import "MFDistanceMatrixOperation.h"

#import "MFK2PDistanceMatrix.h"
#import "MFJukeCantorDistanceMatrix.h"
#import "MFProtein.h"

@implementation MFDistanceMatrixOperation

@synthesize matrix = _matrix;

-(id)initWithSequenceArray:(NSArray*)sequences model:(MFDistanceMatrixModel)model{
    if ( self = [super initWithOptions:[NSDictionary dictionary]] ) {
        _sequences = [sequences retain];
        _model = model;
        _matrix = nil;
        
        if ( [[[_sequences objectAtIndex:0]dataType] isKindOfClass:[MFProtein class]] ) {
            _matrix = [[MFDistanceMatrix alloc]initWithSequencesFromArray: _sequences];
            self.description = @"Caculating distance Matrix";
        }
        else {
            
            switch (_model) {
                case MFDistanceMatrixModelRAW:{
                    _matrix = [[MFDistanceMatrix alloc]initWithSequencesFromArray: _sequences];
                    self.description = @"Caculating distance matrix";
                    break;
                }
                case MFDistanceMatrixModelJC69:{
                    _matrix = [[MFJukeCantorDistanceMatrix alloc]initWithSequencesFromArray: _sequences];
                    self.description = @"Caculating JC69 distance matrix";
                    break;
                }
                case MFDistanceMatrixModelK2P:{
                    _matrix = [[MFK2PDistanceMatrix alloc]initWithSequencesFromArray: _sequences];
                    self.description = @"Caculating K2P distance matrix";
                    break;
                }
                default:{
                    NSLog(@"MFDistanceMatrixOperation error");
                    break;
                }
            }
        }
    }
    return self;
}

-(void)dealloc{
    [_matrix release];
    [_sequences release];
    [super dealloc];
}

-(void)main{
    NSLog(@"MFDistanceMatrixOperation running %lu", _model);

//    if( [self.delegate respondsToSelector:@selector(operation:setDescription:)] ){
//        dispatch_sync(dispatch_get_main_queue(), ^{
//            [self.delegate operation:self setDescription:self.description];
//        });
//    }
    float **matrix = [_matrix floatMatrix];
    NSUInteger dimension = [_sequences count];
    for ( NSUInteger i = 0; i < dimension; i++ ) {
        MFSequence *seq1 = [_sequences objectAtIndex:i];
        
        for ( NSUInteger j = i+1; j < dimension; j++ ) {
            MFSequence *seq2 = [_sequences objectAtIndex:j];
            matrix[i][j] = matrix[j][i] = [_matrix calculatePairwiseDistanceBetween:seq1 and:seq2];
        }
        if( [self isCancelled] )break;
    }
    //[_matrix calculateDistances];
    
//    [(NSObject *)self.delegate performSelectorOnMainThread: @selector(distanceMatrixDidFinish:)
//                                       withObject: self
//                                    waitUntilDone: YES];
}

@end
