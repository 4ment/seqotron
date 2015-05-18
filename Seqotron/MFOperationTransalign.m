//
//  MFOperationTransalign.m
//  Seqotron
//
//  Created by Mathieu Fourment on 9/03/2015.
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

#import "MFOperationTransalign.h"

#import "MFSequence.h"
#import "MFSequenceSet.h"
#import "MFSequenceReader.h"
#import "MFSequenceWriter.h"

@implementation MFOperationTransalign

@synthesize position;

-(id)initWithNucleotideFile:(NSString*)inputNucleotide AminoacidFile:(NSString*)inputAminoAcid outputULR:(NSURL*)output{
    //if( self = [super initWithOutputURL:output classDocument:@"MFDocument"] ){
    if( self = [super initWithOptions:[NSDictionary dictionaryWithObjectsAndKeys:output, MFOperationOutputKey,@"MFDocument", MFOperationDocumentClassKey, nil]] ){
        _inputNucleotide = [inputNucleotide retain];
        _inputAminoAcid  = [inputAminoAcid retain];
        position = 0;
    }
    return self;
}

-(void)dealloc{
    [_inputNucleotide release];
    [_inputAminoAcid release];
    [super dealloc];
}

-(void)main{
    NSLog(@"Operation transalign running");
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        [self.delegate operation:self setDescription:self.description];
//    });
    
    MFSequenceSet *sequenceSetNuc = [MFSequenceReader readSequencesFromFile:_inputNucleotide];
    MFSequenceSet *sequenceSetAA = [MFSequenceReader readSequencesFromFile:_inputAminoAcid];
    
    NSUInteger offset = (self.position == 0 ? 0 : 3);
    
    for ( NSUInteger i = 0; i < [sequenceSetNuc count]; i++) {
        if (self.isCancelled) break;
        
        MFSequence *nuc = [sequenceSetNuc sequenceAt:i];
        NSUInteger nGap = 0;
        if ( self.position ) {
            nGap++;
            if( [[nuc subSequenceWithRange:NSMakeRange(0, 2)] isEqualToString:@"--"]){
                nGap++;
                if( [[nuc subSequenceWithRange:NSMakeRange(0, 3)] isEqualToString:@"---"]){
                    nGap++;
                }
            }
        }
        [nuc removeAllGaps];
        if(self.position) [nuc insertGaps:nGap AtIndex:0];
        NSEnumerator *enumerator = [[sequenceSetAA sequences] objectEnumerator];
        MFSequence *aa;
        while ( aa = [enumerator nextObject]) {
            if( [[aa name] isEqualToString:[nuc name] ]) break;
        }
        for ( NSUInteger j = 0; j < [aa length]; j++ ) {
            if( [aa residueAt:j] == '-' ){
                [nuc insertGaps:3 AtIndex:j*3+offset];
            }
        }
    }
    
    [MFSequenceWriter writeFasta:sequenceSetNuc toFile:_outputURL.path attributes:nil];
    
    NSLog(@"Operation transalign finished");
}



@end
