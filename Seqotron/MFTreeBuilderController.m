//
//  MFTreeBuilder.m
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

#import "MFTreeBuilderController.h"

#import "MFExternalOperation.h"
#import "MFNucleotide.h"
#import "MFSequence.h"
#import "MFSequenceSet.h"
#import "MFSequenceWriter.h"
#import "MFString.h"

#define MFNUCLEOTIDEMODELS @"GTR", @"HKY", @"JC69", @"K80",@"GY94", nil
#define MFAMINOACIDMODELS @"LG",@"WAG", @"Dayhoff", nil
#define MFCODONMODELS @"GY94", nil

#define MFNUCLEOTIDEDISTANCE @"Uncorrected",@"JC69",@"K2P", nil
#define MFAMINOACIDDISTANCE @"K83", nil


@implementation MFTreeBuilderController

@synthesize resampling, bootstrap, indexTabView, resamplingSelection, resamplingThreads;

@synthesize distanceTreeMethods = _distanceTreeMethods;
@synthesize distanceMatrices = _distanceMatrices;
@synthesize distanceTreeMethodsSelection,distanceMatricesSelection;

@synthesize topologySearches, topologySearchesSelection;
@synthesize mlModels;
@synthesize gamma,categories,pInvariant;

- (id)initWithSequences:(NSArray *)sequences withName:(NSString*)name{
    if(self = [super initWithWindowNibName:@"MFTreeBuilderController"]){
        
        _sequences = [sequences retain];
        _alignmentName = [name copy];
        
        _distanceTreeMethods = [[NSArray alloc]initWithObjects:@"Neighbor joining", @"UPGMA", nil];
        distanceMatricesSelection = 0;
        distanceTreeMethodsSelection = 0;

        mlModels = [[NSMutableArray alloc]init];
        _distanceMatrices = [[NSMutableArray alloc]init];
        [self initType];
        
        // Maximum Likelihood
        topologySearches = [[NSArray alloc]initWithObjects:@"Fixed", @"NNI", nil];
        topologySearchesSelection = 0;
        _mlModelsSelection = 0;
        gamma = NO;
        categories = 1;
        pInvariant = NO;
        
        resampling = [[NSArray alloc]initWithObjects:@"None", @"Bootstrap", @"Jackknife", nil];
        bootstrap = 100;
        resamplingThreads = 1;
        
        indexTabView = 0;
        
        _physherPath = [[[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"bin/physher"]stringByAddingQuotesIfSpaces] copy];
        
        NSError *error = nil;
        NSURL *cacheDir = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        
        NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
        _tempPath = [[NSString alloc]initWithString:[[[cacheDir path] stringByAppendingPathComponent:executableName]stringByAppendingPathComponent:@"temp"]];
    }
    return self;
}

-(void)initType{
    [mlModels removeAllObjects];
    [_distanceMatrices removeAllObjects];
    
    MFSequence *sequence = [_sequences objectAtIndex:0];
    
    [self willChangeValueForKey:@"mlModels"];
    [self willChangeValueForKey:@"distanceMatrices"];
    if( [[sequence dataType] isKindOfClass:[MFNucleotide class]] && ![sequence translated] ){
        [mlModels addObjectsFromArray:[NSArray arrayWithObjects:MFNUCLEOTIDEMODELS]];
        [_distanceMatrices addObjectsFromArray:[NSArray arrayWithObjects:MFNUCLEOTIDEDISTANCE]];
    }
    else {
        [mlModels addObjectsFromArray:[NSArray arrayWithObjects:MFAMINOACIDMODELS]];
        [_distanceMatrices addObjectsFromArray:[NSArray arrayWithObjects:MFAMINOACIDDISTANCE]];
    }
    [self didChangeValueForKey:@"mlModels"];
    [self didChangeValueForKey:@"distanceMatrices"];
}

-(void)dealloc{
    NSLog(@"MFTreeBuilderController delloc");
    [_alignmentName release];
    [_sequences release];
    
    [_distanceTreeMethods release];
    [_distanceMatrices release];
    [topologySearches release];

    
    [mlModels release];
    [resampling release];
    
    [_physherPath release];
    [_tempPath release];

    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSInteger t = time(NULL);
    [_seedTextField setStringValue:[@(t) stringValue]];
}

-(NSArray*)operations{
    
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    NSMutableArray *arguments = [[NSMutableArray alloc]init];
    
    [options setObject:arguments forKey:MFExternalOperationArgumentsKey];
    
    [options setObject:@"MFTreeDocument" forKey:MFOperationDocumentClassKey];
    
    NSString *tempDirPath = [_tempPath stringByAppendingPathComponent:[NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0]];
    BOOL isDir = YES;
    while ( [[NSFileManager defaultManager]fileExistsAtPath:tempDirPath isDirectory:&isDir]) {
        tempDirPath = [_tempPath stringByAppendingPathComponent:[NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0]];
    }
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:tempDirPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    if( !error ){
        
        // Input
        [arguments addObject:@"-i"];
        
        NSString *inputFile = [tempDirPath stringByAppendingPathComponent:@"input.fa"];
        NSURL *inputURL = [NSURL URLWithString:[inputFile stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSCharacterSet *forbiddenCharacters = [NSCharacterSet characterSetWithCharactersInString:@",[]():; "];
        
        MFSequenceSet *set = [[MFSequenceSet alloc] initWithSequences:_sequences];
        for (MFSequence *sequence in [set sequences]) {
            sequence.name = [[sequence.name componentsSeparatedByCharactersInSet:forbiddenCharacters]componentsJoinedByString:@"_"];
        }
        [MFSequenceWriter writeFasta:set toFile:inputFile attributes:nil];
        [set release];
        
        [arguments addObject:[[inputURL path]stringByAddingQuotesIfSpaces] ];
        
        // Output
        NSString *prefix = @"output";
        NSString *stemPath = [tempDirPath stringByAppendingPathComponent:prefix];
        NSMutableString *outputFile = [NSMutableString stringWithString:stemPath];
        
        [arguments addObject:@"-o"];
        [arguments addObject:[stemPath stringByAddingQuotesIfSpaces]];
        
        if(self.indexTabView == 0 ){
            [self setUpDistance: options withOutput:outputFile];
        }
        else if( self.indexTabView == 1 ){
            [self setUpML:options withOutput:outputFile];
        }
        
        
        //NSURL *outputURL = [NSURL URLWithString:[outputFile stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        NSURL *outputURL = [NSURL fileURLWithPath:outputFile isDirectory:NO];
        [options setObject:outputURL forKey:MFOperationOutputKey];
    }
    
    if(error){
        [options release];
        [arguments release];
        return nil;
    }
    
    if( self.resamplingSelection == 1 && self.bootstrap > 0 ){
        [arguments addObject:@"-b"];
        [arguments addObject:[@(self.bootstrap) stringValue]];
        
    }
    else if( self.resamplingSelection == 2 ){
        [arguments addObject:@"-j"];
    }
        
    if( resamplingThreads > 0 ){
        [arguments addObject:@"-T"];
        [arguments addObject:[@(resamplingThreads) stringValue]];
    }
    
    [arguments addObject:@"-R"];
    [arguments addObject:[_seedTextField stringValue]];
    
    [options setObject:_physherPath forKey:MFExternalOperationLaunchPathKey];
    
    [arguments release];

    NSLog(@"%@", options);
    
    MFExternalOperation *op = [[MFExternalOperation alloc]initWithOptions:options];
    op.description = [options objectForKey:MFOperationDescriptionKey];
    [options release];

    NSArray *ops =  [NSArray arrayWithObject:op];
    [op release];
    
    return ops;
}

-(void)setUpDistance:(NSMutableDictionary*)options withOutput:(NSMutableString*)output{
    NSMutableArray *arguments = [options objectForKey:MFExternalOperationArgumentsKey];
    
    if( self.distanceTreeMethodsSelection == 0 ){
        [arguments addObject:@"-D"];
        [arguments addObject:@"nj"];
        [output appendString:@".nj.tree"];
        [options setObject:[@"Neighbor joining: " stringByAppendingString:_alignmentName] forKey:MFOperationDescriptionKey];
    }
    else if( self.distanceTreeMethodsSelection == 1 ){
        [arguments addObject:@"-D"];
        [arguments addObject:@"upgma"];
        [output appendString:@".upgma.tree"];
        [options setObject:[@"UPGMA: " stringByAppendingString:_alignmentName] forKey:MFOperationDescriptionKey];
    }
    
    if( ![[_distanceMatrices objectAtIndex:self.distanceMatricesSelection]isEqualToString:@"Uncorrected"]){
        [arguments addObject:@"-m"];
        [arguments addObject:[_distanceMatrices objectAtIndex:self.distanceMatricesSelection] ];
    }
}

-(void)setUpML:(NSMutableDictionary*)options withOutput:(NSMutableString*)output{
    NSMutableArray *arguments = [options objectForKey:MFExternalOperationArgumentsKey];
    
    [options setObject:[@"Maximum likelihood: " stringByAppendingString: _alignmentName] forKey:MFOperationDescriptionKey];
    [output appendString:@".freerate.tree"];
    
    [arguments addObject:@"-m"];
    [arguments addObject:[mlModels objectAtIndex:self.mlModelsSelection]];
    
    if( self.pInvariant ){
        [arguments addObject:@"-I"];
    }
    [arguments addObject:@"-c"];
    if(self.gamma && self.categories > 0 ){
        [arguments addObject:[@(categories) stringValue]];
    }
    else {
        [arguments addObject:@"1"];
    }
    
    if ( self.topologySearchesSelection > 0 ) {
        [arguments addObject:@"-O nni"];
    }
}

- (void)controlTextDidChange:(NSNotification *)notification {
    
    NSCharacterSet *cs = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789"] invertedSet];
    
    NSTextField *obj = [notification object];
    if( [obj tag] == 1){
        NSString *filtered = [[[_bootstrapTextField stringValue] componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        if( [filtered isEqualToString:@""] ){
            self.bootstrap = 0;
            [_bootstrapTextField setStringValue:@"0"];
        }
        else {
            self.bootstrap = [filtered intValue];
            [_bootstrapTextField setStringValue:filtered];
        }
    }
    else if( [obj tag] == 2){
        NSString *filtered = [[[_categoriesTextField stringValue] componentsSeparatedByCharactersInSet:cs] componentsJoinedByString:@""];
        if( [filtered isEqualToString:@""] ){
            self.categories = 0;
            [_categoriesTextField setStringValue:@"0"];
        }
        else {
            self.categories = [filtered intValue];
            [_categoriesTextField setStringValue:filtered];
        }
    }
}

-(IBAction)close:(id)sender{
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
    [[self window] orderOut:nil];
}

-(IBAction)build:(id)sender{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:nil];
}


@end
