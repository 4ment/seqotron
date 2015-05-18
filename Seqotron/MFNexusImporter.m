//
//  MFNexusSequenceImporter.m
//  Seqotron
//
//  Created by Mathieu Fourment on 4/11/2014.
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

#import "MFNexusImporter.h"
#import "MFString.h"
#import "MFSequence.h"
#import "MFNucleotide.h"
#import "MFProtein.h"
#import "MFReaderCluster.h"
#import "MFTree.h"

@implementation MFNexusImporter

- (id)init{
	if ( (self = [super init]) ) {
        _nolabels = NO;
        _dataType = nil;
        _contentsEnd = 0;
	}
	return self;
}

-(void)dealloc{
    [_dataType release];
    [super dealloc];
}

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

-(MFSequenceSet*)readSequences:(MFReaderCluster*)reader{
    NSRegularExpression *blockRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*begin\\s+((?:data|characters|taxa));" options:NSRegularExpressionCaseInsensitive error:nil];
    
    
    MFSequenceSet *sequences = nil;
    
    NSString *line;
    
    while ( (line = [reader readLine]) ) {
        
        if ([line isEmpty]) continue;
        
        NSArray* block = [blockRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
        
        if( [block count] == 1 ){
            NSTextCheckingResult* match = [block objectAtIndex:0];
            NSString *name = [line substringWithRange:[match rangeAtIndex:1]];
            
            if( [ [name uppercaseString] isEqualToString:@"DATA"] ){
                sequences = [self readDataBlock:reader];
                break;
            }
            else if( [ [name uppercaseString] isEqualToString:@"CHARACTERS"] ){
                sequences = [self readDataBlock:reader];
                break;
            }
            else if( [ [name uppercaseString] isEqualToString:@"TAXA"] ){
                [self readTaxaBlock:reader];
            }
        }
    }
    if( [sequences size] != _numberOfSequences ){
        NSLog(@"Number of sequences of found: %tu Number of sequences expected from ntax %tu", [sequences size], _numberOfSequences );
    }
    
    if( _dataType != nil ){
        for (MFSequence *sequence in [sequences sequences]) {
            [sequence setDataType:_dataType];
        }
    }
    
	return sequences;
}


-(NSString*)nextLineUncommented:(MFReaderCluster*) reader{
    
    NSString *line = [reader readLine];
    
    NSInteger indexStart = [line rangeOfString:@"["].location;
    NSInteger indexStop  = [line rangeOfString:@"]"].location;
    
    //no comment
    if( indexStart == NSNotFound && indexStop == NSNotFound ){
        return line;
    }
    
    // if we enter this loop it means we it is a multiline comment
    while ( indexStop == NSNotFound && (line = [reader readLine]) ) {
        indexStop  = [line rangeOfString:@"]"].location;
        indexStart = 0;
    }
    
    NSMutableString *mutableLine = [NSMutableString stringWithString:@""];
    if (indexStart > 0 ) {
        [mutableLine appendString:[line substringToIndex:indexStart]];
    }
    else if( indexStop < [line length]-1 ){
        [mutableLine appendString:[line substringFromIndex:indexStop+1]];
    }
    
    return mutableLine;
}

-(MFSequenceSet *)readDataBlock:(MFReaderCluster*) reader{
    NSRegularExpression *ntaxRegex       = [NSRegularExpression regularExpressionWithPattern:@"ntax\\s*=\\s*(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *ncharRegex      = [NSRegularExpression regularExpressionWithPattern:@"nchar\\s*=\\s*(\\d+)" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *gapRegex        = [NSRegularExpression regularExpressionWithPattern:@"gap\\s*=\\s*(\\w)" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *missingRegex    = [NSRegularExpression regularExpressionWithPattern:@"missing\\s*=\\s*(\\w)" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *datatypeRegex   = [NSRegularExpression regularExpressionWithPattern:@"datatype\\s*=\\s*(\\w+)" options:NSRegularExpressionCaseInsensitive error:nil];
    NSRegularExpression *matchcharRegex  = [NSRegularExpression regularExpressionWithPattern:@"matchchar\\s*=\\s*(\\w)" options:NSRegularExpressionCaseInsensitive error:nil];

    NSString *line;
    
    // read ntax and nchar and datatype
    while ( (line = [self nextLineUncommented:reader]) ) {
        
        line = [line stringByTrimmingPaddingWhitespace];
        
        if ([line isEmpty]) continue;
        
        if( [[line uppercaseString] hasPrefix:@"MATRIX"] ) {
            return [self readMatrix:reader];
        }
        
        NSArray* matches  = [ntaxRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
        
        if( [line rangeOfString:@"nolabels" options:NSCaseInsensitiveSearch].location != NSNotFound ){
            _nolabels = YES;
        }
        if( [matches count] == 1 ){
            NSString *ntaxString = [line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
            _numberOfSequences = [ntaxString integerValue];
        }
        
        matches = [ncharRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
        if( [matches count] == 1 ){
            NSString *ncharString = [line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
            _numberOfSites = [ncharString integerValue];
        }
        
        if( [line rangeOfString:@"interleave" options:NSCaseInsensitiveSearch].location != NSNotFound ){
            NSRange r = [line rangeOfString:@"interleave" options:NSCaseInsensitiveSearch];
            NSString *temp = [line substringFromIndex:r.length+r.location];
            temp = [temp stringByTrimmingLeadingWhitespace];
            _interleaved = YES;
            // some nexus files have the interleave keyword without specifying yes or no so we consider it interleaved
            if( ![temp isEmpty] ){
                if( [temp characterAtIndex:0] == '=' ){
                    NSUInteger i = 1;
                    while ( i < [temp length] ) {
                        if ( [temp characterAtIndex:i] == 'y' || [temp characterAtIndex:i] == 'Y' ) {
                            _interleaved = YES;
                            break;
                        }
                        else if ( [temp characterAtIndex:i] == 'n' || [temp characterAtIndex:i] == 'N' ) {
                            _interleaved = NO;
                            break;
                        }
                    }
                }
            }
        }
        
        matches = [datatypeRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
        if( [matches count] == 1 ){
            NSString *datatypeString = [[line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]] uppercaseString];
            if ( [@"NUCLEOTIDE" isEqualToString: datatypeString] || [@"DNA" isEqualToString: datatypeString] || [@"RNA" isEqualToString: datatypeString]) {
                _dataType = [[MFNucleotide alloc]init];
            }
            else if( [@"PROTEIN" isEqualToString: datatypeString] ){
                _dataType = [[MFProtein alloc]init];
            }
        }
        
        matches = [gapRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
        if( [matches count] == 1 ){
            _gap = [line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
        }
        
        matches = [missingRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
        if( [matches count] == 1 ){
            _missing = [line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
        }
        
        matches = [matchcharRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
        if( [matches count] == 1 ){
            _matchchar = [line substringWithRange:[[matches objectAtIndex:0] rangeAtIndex:1]];
        }
    }
    
    return nil;
}

-(void)readTaxaBlock:(MFReaderCluster *)reader{
    NSString *line;
    
    while ( (line = [self nextLineUncommented:reader]) ) {
        
        
        line = [line stringByTrimmingPaddingWhitespace];
        
        if( [line  isEmpty] ) continue;

        if( [[line uppercaseString] hasPrefix:@"END;"] ){
            break;
        }
        
        if([[line uppercaseString] hasPrefix:@"TAXLABELS"] ){
            NSMutableString *mutableString = [[NSMutableString alloc]init];
            NSRange r = [line rangeOfString:@"taxlabels" options:NSCaseInsensitiveSearch];
            [mutableString appendString:[line substringFromIndex:r.location+r.length]];
            
            while( (line = [self nextLineUncommented:reader]) && ![line hasSuffix:@";"] ) {
                [mutableString appendFormat:@" %@",line ];
            }
            // in case the last taxon ends with the final ;
            if ( ![line isEqualToString:@";"] ) {
                [mutableString appendString:[line substringToIndex:[line length]-1]];
            }
            
            _taxa = [NSMutableArray array];
            
            NSMutableCharacterSet *delimiters = [[NSCharacterSet whitespaceCharacterSet] mutableCopy];
            [delimiters invert];
            
            r = NSMakeRange(0, [mutableString length]);
            while ( r.location <  [mutableString length]-1 ) {
                r = [mutableString rangeOfCharacterFromSet:delimiters options:0 range:NSMakeRange(r.location, [mutableString length] - r.location)];
                
                NSRange r2 = NSMakeRange(r.location+1, 1);
                
                if( [mutableString characterAtIndex:r.location] == ';' ){
                    break;
                }
                else if( [mutableString characterAtIndex:r.location] == '\''){
                    r = [mutableString rangeOfString:@"'" options:0 range:NSMakeRange(r2.location, [mutableString length] - r2.location)];
                }
                else if( [mutableString characterAtIndex:r.location] == '"'){
                    r = [mutableString rangeOfString:@"\"" options:0 range:NSMakeRange(r2.location, [mutableString length] - r2.location)];
                }
                else {
                    r = [mutableString rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet] options:0 range:NSMakeRange(r2.location, [mutableString length] - r2.location-1)];
                }
                
                r2.length = r.location - r2.location;
                [_taxa addObject:[mutableString substringWithRange:r2]];
                r.location = r2.location+r2.length+1;
            }
            [delimiters release];
            [mutableString release];
        }
        else if( [[line uppercaseString] hasPrefix:@"DIMENSIONS"] && [line rangeOfString:@"ntax" options:NSCaseInsensitiveSearch].location != NSNotFound ){
            NSRange r = [line rangeOfString:@"ntax" options:NSCaseInsensitiveSearch];
            r.location += r.length;
            r.length = [line length] - r.location;
            line = [ line substringWithRange:r];
            r = [line rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet] options:0 range:NSMakeRange(0, [line length]) ];
            NSScanner *scanner = [NSScanner scannerWithString:[line substringFromIndex:r.location] ];
            [scanner scanInteger:&_numberOfSequences];
        }
    }
}

-(MFSequenceSet *)readMatrix:(MFReaderCluster*) reader{
    
    MFSequenceSet *sequences = [[MFSequenceSet alloc]init];
    
    NSUInteger index = 0;
    NSString *line;
    
    while ( (line = [self nextLineUncommented:reader])) {
        
        line = [line stringByTrimmingPaddingWhitespace];
        
        if( [line  isEmpty] ){
            continue;
        }
        if( [line hasPrefix:@";"] ){
            break;
        }
        
        NSString *taxon;
        NSString *seqString;
        
        if( _nolabels ){
            taxon = [_taxa objectAtIndex:index];
            seqString = line;
        }
        else{
            if( [line hasPrefix:@"'"] ){
                
                NSUInteger i = 1;
                while ( [line characterAtIndex:i] != '\'') {
                    i++;
                }
                taxon = [line substringWithRange:NSMakeRange(1, i-1)];
                seqString = [line substringFromIndex:i+1];
            }
            else if( [line hasPrefix:@"\""] ){
                NSUInteger i = 1;
                while ( [line characterAtIndex:i] != '"') {
                    i++;
                }
                taxon = [line substringWithRange:NSMakeRange(1, i-1)];
                seqString = [line substringFromIndex:i+1];
            }
            else{
                NSUInteger i = 0;
                while ( ![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[line characterAtIndex:i]] ) {
                    i++;
                }
                taxon     = [line substringToIndex:i];
                seqString = [line substringFromIndex:i+1];
            }
        }
        
        NSArray* temp = [[seqString uppercaseString] componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        seqString = [temp componentsJoinedByString:@""];
        
        BOOL endOfMatrix = [seqString hasSuffix:@";"];
        
        if( endOfMatrix ){
            seqString = [seqString substringToIndex:[seqString length]-1];
        }
        if([sequences size] < _numberOfSequences ){
            MFSequence *sequence = [[ MFSequence alloc] initWithString:seqString name:taxon];
            [sequences addSequence:sequence];
            [sequence release];
            
        }
        else{
            if( index == _numberOfSequences ){
                index = 0;
            }
            MFSequence *sequence = [sequences sequenceAt:index];
            [sequence concatenateString:seqString];
        }
        
        index++;
        
        if(endOfMatrix){
            break;
        }
    }
    return  [sequences autorelease];
}

-(NSArray *)readTreesBlock:(MFReaderCluster*) reader{
    
    NSMutableArray *trees = [[NSMutableArray alloc]init];
    NSMutableDictionary *translate = [[NSMutableDictionary alloc]init];;
    
    NSString *line;
    
    while ( (line = [reader readLine])) {
        
        line = [line stringByTrimmingPaddingWhitespace];
        
        if( [line  isEmpty] ){
            continue;
        }
        if( [[line uppercaseString] hasPrefix:@"TREE"] ){
            NSUInteger i = 4;
            while ( [line characterAtIndex:i] != '(') {
                if( [line characterAtIndex:i] == '['){
                    while ( [line characterAtIndex:i] != ']') {
                        i++;
                    }
                }
                i++;
            }
            NSString *newick = [line substringFromIndex:i];
            MFTree *tree = [[MFTree alloc]initWithNewick:newick];
            [trees addObject:tree];
            [tree release];
        }
        else if( [[line uppercaseString] hasPrefix:@"TRANSLATE"] ){
            BOOL done = NO;
            while( (line = [self nextLineUncommented:reader]) && !done ) {
                line = [line stringByTrimmingPaddingWhitespace];
                
                if( [line isEqualToString:@";"] ) break;
                if( [line rangeOfString:@";"].location != NSNotFound ){
                    line = [line substringToIndex:[line rangeOfString:@";"].location];
                    done = YES;
                }
                
                NSArray *t = [line componentsSeparatedByString:@","];
                for ( NSUInteger i = 0; i < [t count]; i++ ) {
                    NSString *temp = [[t objectAtIndex:i] stringByTrimmingPaddingWhitespace];
                    
                    if( [temp isEqualToString:@""] ) continue;
                    
                    NSInteger idx = [temp rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]].location;
                    NSString *shorthand = [temp substringToIndex:idx];
                    NSString *taxonName = [temp substringFromIndex:idx+1];
                    taxonName = [[taxonName stringByTrimmingPaddingWhitespace] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
                    [translate setValue:taxonName forKey:shorthand];
                }
            }
        }
    }
    
    if( [translate count] > 0 ){
        for ( NSUInteger i = 0; i < [trees count]; i++ ) {
            MFTree *tree = [trees objectAtIndex:i];
            [tree enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPostorder usingBlock:^(MFNode *node){
                if( [node isLeaf] ){
                    if( [translate objectForKey:[node name]] ){
                        node.name = [translate objectForKey:[node name]];
                    }
                }
            }];
        }
    }
    [translate release];
    return  [trees autorelease];
}

-(NSArray*)readTreesFromFile:(NSString*)path{
    
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithFile:path];
    
    NSArray *trees = [self readTrees:reader];
    
    [reader release];
    
    return trees;
}

-(NSArray*)readTreesFromURL:(NSURL*)url{
    NSString *content = [ NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSArray *trees = [self readTreesFromString:content];
    return trees;
}

-(NSArray*)readTreesFromData:(NSData*)data{
    
    NSString *content = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    NSArray *trees = [self readTreesFromString:content];
    [content release];
    return trees;
}

-(NSArray*)readTreesFromString:(NSString*)content{
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithString:content];
    
    NSArray *trees = [self readTrees:reader];
    
    [reader release];
    
    return trees;
}

-(NSArray*)readTrees:(MFReaderCluster*)reader{
    NSRegularExpression *blockRegex = [NSRegularExpression regularExpressionWithPattern:@"^\\s*begin\\s+((?:trees|taxa));" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *trees = nil;
    
    NSString *line;
    
    while ( (line = [reader readLine]) ) {
        
        if ([line isEmpty]) continue;
        
        NSArray* block = [blockRegex matchesInString:line options:0 range: NSMakeRange(0, [line length])];
        
        if( [block count] == 1 ){
            NSTextCheckingResult* match = [block objectAtIndex:0];
            NSString *name = [line substringWithRange:[match rangeAtIndex:1]];
            
            if( [ [name uppercaseString] isEqualToString:@"TREES"] ){
                trees = [self readTreesBlock:reader];
                break;
            }
        }
    }
    
    return trees;
}


@end
