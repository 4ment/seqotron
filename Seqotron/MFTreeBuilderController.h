//
//  MFTreeBuilder.h
//  Seqotron
//
//  Created by Mathieu Fourment on 18/12/2014.
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

#import <Cocoa/Cocoa.h>

#import "MFDataType.h"
#import "MFExternalOperation.h"
#import "MFSequenceSet.h"
#import "MFOperationBuilder.h"

@interface MFTreeBuilderController : NSWindowController <NSTextFieldDelegate,MFOperationBuilder>{

    NSString *_alignmentName;
    NSArray *_sequences;
    
    NSString *_physherPath;
    NSString *_tempPath;
    
    // Resampling
    IBOutlet NSTextField *_bootstrapTextField;
    IBOutlet NSTextField *_seedTextField;
    
    // Distance
    NSMutableArray *_distanceMatrices;
    NSArray *_distanceTreeMethods;
    
    // Maximum likelihood
    IBOutlet NSTextField *_categoriesTextField;
}

@property NSUInteger indexTabView;

@property (retain) NSArray *resampling;
@property NSUInteger resamplingSelection;
@property NSUInteger bootstrap;
@property NSUInteger resamplingThreads;

// Distance
@property (retain) NSMutableArray *distanceMatrices;
@property (retain) NSArray *distanceTreeMethods;
@property NSUInteger distanceMatricesSelection;
@property NSUInteger distanceTreeMethodsSelection;

// Maximum likelihood
@property (retain) NSMutableArray *mlModels;
@property NSUInteger mlModelsSelection;
@property (retain,readonly) NSArray *topologySearches;
@property NSUInteger topologySearchesSelection;
@property BOOL gamma;
@property NSUInteger categories;
@property BOOL pInvariant;

- (id)initWithSequences:(NSArray *)sequences withName:(NSString*)name;

-(void)initType;

@end
