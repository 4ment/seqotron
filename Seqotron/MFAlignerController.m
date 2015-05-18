//
//  MFAlignerController.m
//  Seqotron
//
//  Created by Mathieu Fourment on 7/03/2015.
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

#import "MFAlignerController.h"

#import "MFSequenceWriter.h"
#import "MFSequenceSet.h"
#import "MFString.h"
#import "MFExternalOperation.h"
#import "MFOperationTransalign.h"

@implementation MFAlignerController

@synthesize indexTabView,refine,additionalCommands,transalign,transalignEnabled;

- (id)initWithSequences:(NSArray *)sequences withName:(NSString*)name{
    if(self = [super initWithWindowNibName:@"MFAligner"]){
        
        _sequences = [sequences retain];
        _musclePath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"bin/muscle"] copy];
        _mafftPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"bin/mafft.bat"] copy];;
        NSError *error = nil;
        NSURL *cacheDir = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
        
        NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
        _tempPath = [[NSString alloc]initWithString:[[[cacheDir path] stringByAppendingPathComponent:executableName]stringByAppendingPathComponent:@"temp"]];
        transalignEnabled = YES;
        transalign = NO;
    }
    return self;
}

-(void)dealloc{
    NSLog(@"MFAlignerController delloc");
    [_sequences release];
    
    [_musclePath release];
    [_tempPath release];
    [_mafftPath release];
    
    [super dealloc];
}

-(NSArray*)operations{
    NSMutableDictionary *options = [[NSMutableDictionary alloc]init];
    NSMutableArray *arguments = [[NSMutableArray alloc]init];
    
    [options setObject:arguments forKey:MFExternalOperationArgumentsKey];
    [options setObject:@"MFDocument" forKey:MFOperationDocumentClassKey];
    
    NSString *outputDirPath = [_tempPath stringByAppendingPathComponent:[NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0]];
    BOOL isDir = YES;
    while ( [[NSFileManager defaultManager]fileExistsAtPath:outputDirPath isDirectory:&isDir]) {
        outputDirPath = [_tempPath stringByAppendingPathComponent:[NSString stringWithFormat: @"%.0f", [NSDate timeIntervalSinceReferenceDate] * 1000.0]];
    }
    
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:outputDirPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    if( !error ){
        
        NSString *inputFile     = [[outputDirPath stringByAppendingPathComponent:@"input.muscle.fa"] stringByAddingQuotesIfSpaces];
        NSString *outputFile    = [[outputDirPath stringByAppendingPathComponent:@"output.muscle.fa"] stringByAddingQuotesIfSpaces];
        NSString *transalignNuc = [[outputDirPath stringByAppendingPathComponent:@"input.nuc.fa"] stringByAddingQuotesIfSpaces];
        
        NSURL *url = [NSURL URLWithString:[outputFile stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        [options setObject:url forKey:MFOperationOutputKey];
        
        // Input
        NSURL *inputURL = [[NSURL URLWithString:[inputFile stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]copy];
        MFSequenceSet *sequenceSet;
        if ( !MFIsEmpty2DRange(_rangeSelection) ) {
            NSArray *sub = [_sequences objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:_rangeSelection.y]];
            sequenceSet = [[MFSequenceSet alloc]initWithSequences:sub];
            [MFSequenceWriter writeFasta:sequenceSet toFile:inputFile attributes:nil];
        }
        else if( transalign ){
            
            // write DNA for transalign
            sequenceSet = [[MFSequenceSet alloc]initWithSequences:_sequences];
            NSUInteger index = [sequenceSet indexFirstNonGap];
            [MFSequenceWriter writeFasta:sequenceSet toFile:transalignNuc attributes:nil];
            
            // write AA for muscle
            MFSequenceSet *aaSet = [[MFSequenceSet alloc] init];
            for ( MFSequence *seq in _sequences ) {
                MFSequence *copySeq = [seq copy];
                // there are gaps at the beginning
                if( index != 0 ){
                    [copySeq deleteResiduesInRange:NSMakeRange(0, 3)];
                }
                [copySeq translateFinal];
                [aaSet addSequence:copySeq];

                [copySeq release];
            }
            [MFSequenceWriter writeFasta:aaSet toFile:inputFile attributes:nil];
            [aaSet release];
        }
        else{
            sequenceSet = [[MFSequenceSet alloc]initWithSequences:_sequences];
            NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], MFSequenceWriterIgnoreLeadingGaps, nil];
            [MFSequenceWriter writeFasta:sequenceSet toFile:inputFile attributes:attrs];
        }
        
        [options setObject:inputURL forKey:MFExternalOperationInputKey];
        [inputURL release];
        
        // Muscle
        if( self.indexTabView == 0 ){
            
            [arguments addObject:@"-in"];
            [arguments addObject:inputFile];
            
            [arguments addObject:@"-out"];
            [arguments addObject:outputFile];
            
            if ( self.refine ) {
                [arguments addObject:@"-refine"];
            }
            
            //[arguments addObject:@"-stable"]; // keep the same order but not supported in this version
            
            [options setObject:[@"MUSCLE: " stringByAppendingString:[inputFile lastPathComponent]] forKey:MFOperationDescriptionKey];
            
            [options setObject:_musclePath forKey:MFExternalOperationLaunchPathKey];
        }
        // MAFFT
        else if( self.indexTabView == 1 ){
            
            [arguments addObject:inputFile];
            
            [arguments addObject:@">"];
            [arguments addObject:outputFile];
            
            [options setObject:[@"MAFFT: " stringByAppendingString:[inputFile lastPathComponent]] forKey:MFOperationDescriptionKey];
            
            [options setObject:_mafftPath forKey:MFExternalOperationLaunchPathKey];
        }
        
        if ( [additionalCommands length] > 0 ) {
            NSArray *array = [self.additionalCommands componentsSeparatedByString:@"-"];
            for (NSString  *arg in array) {
                arg = [arg stringByTrimmingPaddingWhitespace];
                
                NSRange range = [arg rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
                if (range.location == NSNotFound ) {
                    if (![arg isEmpty])[arguments addObject:[@"-" stringByAppendingString:arg] ];
                }
                else {
                    NSString *key = [[arg substringToIndex:range.location] stringByTrimmingPaddingWhitespace];
                    NSString *value = [[arg substringFromIndex:range.location]stringByTrimmingPaddingWhitespace];
                    
                    [arguments addObject:[@"-" stringByAppendingString:key]];
                    if([value length])[arguments addObject:value];
                }
            }
        }
        
        [arguments release];
        
        NSLog(@"%@", options);
        
        MFExternalOperation *op = [[MFExternalOperation alloc]initWithOptions:options];
        op.description = [options objectForKey:MFOperationDescriptionKey];
        
        [options release];
        NSArray *ops;
        if( transalign ){
            NSString *transalignNucOutput = [[outputDirPath stringByAppendingPathComponent:@"output.nuc.fa"] stringByAddingQuotesIfSpaces];
            NSURL *outputURL = [NSURL URLWithString:[transalignNucOutput stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
            MFOperationTransalign *transalignOp = [[MFOperationTransalign alloc]initWithNucleotideFile:transalignNuc AminoacidFile:outputFile outputULR:outputURL];
            transalignOp.position = [sequenceSet indexFirstNonGap];
            transalignOp.description = [@"Transalign: " stringByAppendingString:[inputFile lastPathComponent]];
            [transalignOp addDependency:op];
            
            ops = [NSArray arrayWithObjects:op,transalignOp, nil];
            [transalignOp release];
        }
        else {
            ops = [NSArray arrayWithObject:op];
        }
        [sequenceSet release];
        [op release];
        return ops;
    }
    
    [options release];
    [arguments release];
    return nil;
}

- (void)setSelection:(MF2DRange)selection{
    _rangeSelection = selection;
}

-(IBAction)closeAction:(id)sender{
    [NSApp endSheet:[self window] returnCode:NSCancelButton];
    [[self window] orderOut:nil];
}

-(IBAction)alignAction:(id)sender{
    [NSApp endSheet:[self window] returnCode:NSOKButton];
    [[self window] orderOut:nil];
}

@end
