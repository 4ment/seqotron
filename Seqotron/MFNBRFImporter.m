//
//  MFNBRFImporter.m
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

#import "MFNBRFImporter.h"

#import "MFSequence.h"
#import "MFReaderCluster.h"

@implementation MFNBRFImporter

/*
 P1 - Protein (complete)
 F1 - Protein (fragment)
 D1 - DNA (e.g. EMBOSS seqret output)
 DL - DNA (linear)
 DC - DNA (circular)
 RL - RNA (linear)
 RC - RNA (circular)
 N3 - tRNA
 N1 - Other functional RNA
 XX - Unknown
 */

/*
 >P1;CRAB_ANAPL
 ALPHA CRYSTALLIN B CHAIN (ALPHA(B)-CRYSTALLIN).
 MDITIHNPLI RRPLFSWLAP SRIFDQIFGE HLQESELLPA SPSLSPFLMR
 SPIFRMPSWL ETGLSEMRLE KDKFSVNLDV KHFSPEELKV KVLGDMVEIH
 GKHEERQDEH GFIAREFNRK YRIPADVDPL TITSSLSLDG VLTVSAPRKQ
 SDVPERSIPI TREEKPAIAG AQRK*
 
 >P1;CRAB_BOVIN
 ALPHA CRYSTALLIN B CHAIN (ALPHA(B)-CRYSTALLIN).
 MDIAIHHPWI RRPFFPFHSP SRLFDQFFGE HLLESDLFPA STSLSPFYLR
 PPSFLRAPSW IDTGLSEMRL EKDRFSVNLD VKHFSPEELK VKVLGDVIEV
 HGKHEERQDE HGFISREFHR KYRIPADVDP LAITSSLSSD GVLTVNGPRK
 QASGPERTIP ITREEKPAVT AAPKK*
 */

- (MFSequenceSet *)readSequencesFromFile:(NSString *)path{
	MFReaderCluster *reader = [[MFReaderCluster alloc]initWithFile:path];
    
    MFSequenceSet *sequences = [self readSequences:reader];
    
    [reader release];
    
	return sequences;
}

-(MFSequenceSet*)readSequencesFromURL:(NSURL*)url{
    NSString *content = [ NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    MFSequenceSet *sequences = [self readSequencesFromString:content];
    
    return sequences;
}

-(MFSequenceSet*)readSequencesFromData:(NSData*)data{
    NSString *content = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithString:content];
    
    MFSequenceSet *sequences = [self readSequences:reader];
    
    [reader release];
    [content release];
    
    return sequences;
}

-(MFSequenceSet*)readSequencesFromString:(NSString*)content{
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithString:content];
    
    MFSequenceSet *sequences = [self readSequences:reader];
    
    [reader release];
    
	return sequences;
}

- (MFSequenceSet *)readSequences:(MFReaderCluster *)reader{
    
    MFSequenceSet *sequences = [[MFSequenceSet alloc] init];
    
	NSMutableString *sequenceBuffer = [ [NSMutableString alloc] initWithCapacity:100 ];
    NSMutableString *nameBuffer = [ [NSMutableString alloc] initWithCapacity:100 ];
	[sequenceBuffer setString: @""];
    NSCharacterSet *charSet = [NSCharacterSet characterSetWithCharactersInString:@" \t*"];
    
    NSString *line;
    while ( (line = [reader readLine]) ) {

        // P1, F1, DL, DC, RL, RC, XX
        if( [line hasPrefix:@">"] ){
            if( ![ sequenceBuffer isEqualToString: @"" ]){
                NSString *seq = [sequenceBuffer stringByTrimmingCharactersInSet:charSet];
                MFSequence *sequence = [[ MFSequence alloc] initWithString:seq name:nameBuffer];
                
                [sequences addSequence:sequence];
                [sequence release];
				[sequenceBuffer setString: @""];
            }
            [nameBuffer setString:[line substringFromIndex:4]];
            [reader readLine]; // that's a comment line
        }
        else {
            [sequenceBuffer appendString: [line uppercaseString]];
        }
	}
	
    if( ![sequenceBuffer isEqualToString: @"" ]){
        NSString *seq = [sequenceBuffer stringByTrimmingCharactersInSet:charSet];
        MFSequence *sequence = [[ MFSequence alloc] initWithString:seq name:nameBuffer];
        [sequences addSequence:sequence];
        [sequence release];
    }
    
	[sequenceBuffer release];
    [nameBuffer release];
    
    return [sequences autorelease];
}

@end
