//
//  MFSequence.m
//  Seqotron
//
//  Created by Mathieu Fourment on 25/01/14.
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

#import "MFSequence.h"
#import "MFNucleotide.h"

@class MFDataType;

@implementation MFSequence

@synthesize sequence = _sequence;
@synthesize name = _name;
@synthesize dataType = _dataType;
@synthesize translated = _translated;

- (id)initWithString:(NSString *)aSequence name:(NSString *)aName dataType:(MFDataType*)aDataType{
	if ( (self = [super init]) ) {
		_name = [aName copy];
		_sequence = [aSequence mutableCopy];
        _dataType = [aDataType retain];
        _genetictable = nil;
        _translated = NO;
	}
	return self;
}

- (id)initWithString:(NSString *)aSequence name:(NSString *)aName{
	if ( (self = [super init]) ) {
		_name = [aName copy];
		_sequence = [aSequence mutableCopy];
        _dataType = [[MFNucleotide alloc]init];
        _genetictable = nil;
        _translated = NO;
	}
	return self;
}

- (id)initWithName:(NSString *)aName{
	if ( (self = [super init]) ) {
		_name = [aName copy];
        _sequence = [[NSMutableString alloc] initWithCapacity:10];
        _dataType = [[MFNucleotide alloc]init];
        _genetictable = nil;
        _translated = NO;
	}
	return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MFSequence *copy = [[MFSequence alloc]initWithString:_sequence name:_name dataType:_dataType];
    [copy setTranslated:_translated];
    NSDictionary *dict = [_genetictable copy];
    [copy setGeneticTable:dict];
    [dict release];
    return copy;
}

- (void)dealloc{
	[_name release];
	[_sequence release];
    [_genetictable release];
    [_dataType release];
	[super dealloc];
}

-(NSString*)sequenceString{
    return [self subSequenceWithRange:NSMakeRange(0, [self length])];
}

- (NSUInteger)length{
    if( _translated){
        return ([_sequence length]+2)/3;
    }
    return [_sequence length];
}

- (NSString *)subSequenceWithRange:(NSRange)range{
    if(range.location >= [_sequence length] ){
        return nil;
    }
    if( _translated){
        NSMutableString *aa = [[NSMutableString alloc] initWithCapacity:range.length];
        range.length   *= 3;
        range.location *= 3;
        
        // 0  1
        // K  X
        // AAAGG
        // 01234
        
        NSUInteger len = range.location+range.length;
        if( len > [_sequence length] ){
            len = [_sequence length] - [_sequence length]%3;
        }
        
        for( NSUInteger i = range.location; i < len; i += 3){
            NSString *codon = [[_sequence substringWithRange:NSMakeRange(i, 3)] uppercaseString];
            
            if(  [codon isEqualTo:@"---"] ){
                [aa appendString:@"-"];
            }
            else if(  [[_genetictable objectForKey:codon]objectForKey: @"OLC"] == nil ){
                [aa appendString:@"X"];
            }
            else {
                [aa appendString: [[_genetictable objectForKey:codon]objectForKey: @"OLC"]];
            }
        }
        
        //if( [_sequence length]%3 != 0 ){
        if( range.location+range.length > [_sequence length] ){
            [aa appendString:@"X"];
        }
        return [aa autorelease];
    }
    
	return [_sequence substringWithRange:range];
}

- (NSString *)subCodonSequenceWithRange:(NSRange)range{
    if(range.location >= [_sequence length] ){
        return nil;
    }
    if( _translated){
        range.length   *= 3;
        range.location *= 3;
        
        if( range.length+range.location > [_sequence length] ){
            range.length = [_sequence length] - range.location;
        }
        
        return [_sequence substringWithRange:range];
    }
    
	return [_sequence substringWithRange:range];
}


- (void)insertResidues:(NSString*)residues AtIndex:(NSUInteger)index{
    
    if ( _translated ) {
        [_sequence insertString:residues atIndex:index*3];
    }
    else{
        [_sequence insertString:residues atIndex:index];
    }
    
}

- (void)insertGaps:(NSUInteger)ngaps AtIndex:(NSUInteger)index{
    
    if ( _translated ) {
        NSMutableString *gaps = [NSMutableString stringWithCapacity:ngaps*3];
        for ( NSUInteger i = 0; i < ngaps; i++ ) {
            [gaps appendString:@"---"];
        }
        
        [_sequence insertString:gaps atIndex:index*3];
        
    }
    else{
        NSMutableString *gaps = [NSMutableString stringWithCapacity:ngaps];
        for ( NSUInteger i = 0; i < ngaps; i++ ) {
            [gaps appendString:@"-"];
        }
        [_sequence insertString:gaps atIndex:index];
    }
    
}

- (void)appendGaps:(NSUInteger)ngaps {
    
    if ( _translated ) {
        NSMutableString *gaps = [NSMutableString stringWithCapacity:ngaps*3];
        // We need to add gaps
        if( [_sequence length]%3 != 0 ){
            if( [_sequence length]%3 == 1 ){
                [gaps appendString:@"-"];
            }
            [gaps appendString:@"-"];
        }
        for ( NSUInteger i = 0; i < ngaps; i++ ) {
            [gaps appendString:@"---"];
        }
        [_sequence appendString:gaps];
    }
    else{
        NSMutableString *gaps = [NSMutableString stringWithCapacity:ngaps];
        for ( NSUInteger i = 0; i < ngaps; i++ ) {
            [gaps appendString:@"-"];
        }
        
        [_sequence appendString:gaps];
    }
}

- (void)deleteResiduesInRange:(NSRange)range{
    if ( _translated ) {
        range.location *= 3;
        range.length   *= 3;
        
        if( range.length+range.location > [_sequence length] ){
            range.length = [_sequence length] - range.location;
        }
    }
    [_sequence deleteCharactersInRange:range ];
    
}


// indexes are very likely to be consecutive if we block edit
- (void)deleteResiduesAtIndexes:(NSIndexSet*)indexes{
    if ( _translated ) {
        [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
            NSRange range = NSMakeRange(idx*3, 3);
            [_sequence deleteCharactersInRange: range];
        }];
    }
    else{
        [indexes enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger idx, BOOL *stop) {
            NSRange range = NSMakeRange(idx, 1);
            [_sequence deleteCharactersInRange: range ];
        }];
    }
}


- (unichar)residueAt:(NSUInteger)index{
    if ( _translated ) {
        index *= 3;
        // K..X
        // AAAA
        //    *
        if( [_sequence length] - index < 3 ){
            return 'X';
        }
        else {
            NSString *codon = [[_sequence substringWithRange:NSMakeRange(index, 3)] uppercaseString];
            if( [codon isEqualToString:@"---"]){
                return '-';
            }
            else if(  [[_genetictable objectForKey:codon]objectForKey: @"OLC"] == nil ){
                return 'X';
            }
            NSString *res = [[_genetictable objectForKey:codon]objectForKey: @"OLC"];
            return [res UTF8String][0];
        }
        
    }
    return [_sequence characterAtIndex: index];
}

- (NSString*)residueStringAt:(NSUInteger)index{
    if ( _translated ) {
        index *= 3;
        // K..X
        // AAAA
        //    *
        if( [_sequence length] - index < 3 ){
            return @"X";
        }
        else {
            NSString *codon = [[_sequence substringWithRange:NSMakeRange(index, 3)] uppercaseString];
            if( [codon isEqualToString:@"---"]){
                return @"-";
            }
            else if(  [[_genetictable objectForKey:codon]objectForKey: @"OLC"] == nil ){
                return @"X";
            }
            return [[_genetictable objectForKey:codon]objectForKey: @"OLC"];
        }
        
    }
    return [_sequence substringWithRange:NSMakeRange(index, 1)];
}

// If it is translated we could replace a codon
-(void)replaceCharactersInRange:(NSRange)range withString:(NSString*)residues{
    if(_translated){
        NSLog(@"Replacing is not allowed when sequence is translated");
    }
    else{
        [_sequence replaceCharactersInRange:range withString:residues];
    }
    
}

-(void)replaceOccurencesOfString:(NSString*)target withString:(NSString*)replacement options:(NSStringCompareOptions)options range:(NSRange)range{
    if(_translated){
        NSLog(@"Replacing is not allowed when sequence is translated");
    }
    else{
        [_sequence replaceOccurrencesOfString:target withString:replacement options:options range:range];
    }
    
}

-(void)removeAllGaps{
    if(_translated){
        NSLog(@"removeAllGaps is not allowed when sequence is translated");
    }
    else{
        [_sequence setString: [_sequence stringByReplacingOccurrencesOfString:@"-" withString:@""]];
    }
}

-(NSRange)rangeOfSequence:(NSString*)string options:(NSStringCompareOptions)mask range:(NSRange)range{
    if(_translated){
        NSString *str = [self subSequenceWithRange:range];
        NSRange r = [str rangeOfString:string options:mask range:range];
        r.length   /= 3;
        r.location /= 3;
        return r;
    }
    else{
        return [_sequence rangeOfString:string options:mask range:range];
    }
}

-(void)trimEndGaps{
    NSRange range = NSMakeRange([_sequence length], 0);
    for ( NSInteger i = [_sequence length]-1; i >= 0; i-- ) {
        if( [_sequence characterAtIndex: i] != '-' ){
            break;
        }
        range.location--;
        range.length++;
    }
    if( range.length > 0 ){
        [_sequence deleteCharactersInRange:range ];
    }
}

- (void)reverse{
    NSMutableString *reversedString = [[NSMutableString alloc] initWithCapacity:[_sequence length]];
    
    [_sequence enumerateSubstringsInRange:NSMakeRange(0,[_sequence length])
                                  options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                               usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                   [reversedString appendString:substring];
                               }];
    
    [_sequence release];
    _sequence = reversedString;
}

-(void)translateFinal{
    if( !self.translated ){
        NSMutableString *protein = [[NSMutableString alloc] initWithCapacity:[_sequence length]/3];

        for ( NSUInteger index = 0; index < [_sequence length]; index+=3 ) {
            if( [_sequence length] - index < 3 ){
                [protein appendString:@"X"];
            }
            else {
                NSString *codon = [[_sequence substringWithRange:NSMakeRange(index, 3)] uppercaseString];
                if( [codon isEqualToString:@"---"]){
                    [protein appendString:@"-"];
                }
                else if(  [[_genetictable objectForKey:codon]objectForKey: @"OLC"] == nil ){
                    [protein appendString:@"X"];
                }
                else {
                    [protein appendString:[[_genetictable objectForKey:codon]objectForKey: @"OLC"]];
                }
            }
        }
        [_sequence release];
        _sequence = protein;
    }
}

// should only be used on nucleotide sequences
- (void)complement{
    if(!_translated){
        NSMutableString *complementString = [[NSMutableString alloc] initWithCapacity:[_sequence length]];
        [_sequence enumerateSubstringsInRange:NSMakeRange(0,[_sequence length])
                                      options:(NSStringEnumerationByComposedCharacterSequences)
                                   usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {

                                       NSString *upperString = [substring uppercaseString];
                                       
                                       if( [@"A" isEqualToString:upperString] ){
                                           [complementString appendString:@"T"];
                                       }
                                       else if( [@"T" isEqualToString:upperString] || [@"U" isEqualToString:upperString] ){
                                           [complementString appendString:@"A"];
                                       }
                                       else if( [@"C" isEqualToString:upperString] ){
                                           [complementString appendString:@"G"];
                                       }
                                       else if( [@"G" isEqualToString:upperString] ){
                                           [complementString appendString:@"C"];
                                       }
                                       else if( [@"R" isEqualToString:upperString] ){
                                           [complementString appendString:@"Y"];
                                       }
                                       else if( [@"Y" isEqualToString:upperString] ){
                                           [complementString appendString:@"R"];
                                       }
                                       else if( [@"M" isEqualToString:upperString] ){
                                           [complementString appendString:@"K"];
                                       }
                                       else if( [@"K" isEqualToString:upperString] ){
                                           [complementString appendString:@"M"];
                                       }
                                       else if( [@"S" isEqualToString:upperString] || [@"W" isEqualToString:upperString] ){
                                           [complementString appendString:substring];
                                       }
                                       else if( [@"V" isEqualToString:upperString] ){
                                           [complementString appendString:@"B"];
                                       }
                                       else if( [@"B" isEqualToString:upperString] ){
                                           [complementString appendString:@"V"];
                                       }
                                       else if( [@"H" isEqualToString:upperString] ){
                                           [complementString appendString:@"D"];
                                       }
                                       else if( [@"D" isEqualToString:upperString] ){
                                           [complementString appendString:@"H"];
                                       }
                                       // if we don't know what it is then we leave it. We could not get the orginal sequence after a redo
                                       else{
                                           [complementString appendString:upperString];
                                       }
                                   }];
        [_sequence release];
        _sequence = complementString;
    }
}

- (void)concatenate:(MFSequence*)aSequence{
    [self concatenateString:[aSequence sequenceString]];
}

- (void)concatenateString:(NSString*)aString{
    [_sequence appendString:aString];
}


-(void)setGeneticTable: (NSDictionary*)geneticTable{
    if( ![_genetictable isEqualToDictionary: geneticTable] ){
        [_genetictable release];
        _genetictable = [geneticTable retain];
    }
}

- (void)insert:(NSString *)string atIndex:(NSUInteger)index{
    [_sequence insertString: string atIndex: index];
}

#pragma mark *** Check these methods ***



- (void)remove:(NSRange)range{
	[_sequence deleteCharactersInRange: range ];
}


- (void)removeAt:(NSUInteger)index{
	[_sequence deleteCharactersInRange:NSMakeRange(index, 1) ];
}








@end