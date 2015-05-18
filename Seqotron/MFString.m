//
//  MFString.m
//  Seqotron
//
//  Created by Mathieu Fourment on 5/02/14.
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

#import "MFString.h"

@implementation NSString (MoreString)


-(NSArray*)splitLines{
    NSUInteger length = [self length];
    NSUInteger paraStart = 0, paraEnd = 0, contentsEnd = 0;
    NSMutableArray *array = [NSMutableArray array];
    NSRange currentRange;
    while (paraEnd < length) {
        [self getParagraphStart:&paraStart end:&paraEnd contentsEnd:&contentsEnd forRange:NSMakeRange(paraEnd, 0)];
        currentRange = NSMakeRange(paraStart, contentsEnd - paraStart);
        [array addObject:[self substringWithRange:currentRange]];
    }
    return array;
}

-(NSString*)stringByTrimmingLeadingWhitespace {
    NSInteger i = 0;
    
    while ((i < [self length])
           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    return [self substringFromIndex:i];
}

-(NSString*)stringByTrimmingTrailingWhitespace {
    NSInteger i = [self length]-1;
    
    while ( i >= 0 && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]] ) {
        i--;
    }
    return [self substringToIndex:i];
}

// NSPanel seems to implement stringByTrimmingWhitespace too
-(NSString*)stringByTrimmingPaddingWhitespace {
    NSInteger i = [self length]-1;
    NSRange range = NSMakeRange(0, [self length]);
    
    while ( i >= 0 && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]] ) {
        range.length--;
        i--;
    }
    if( i == -1 ) return @"";
    
    i = 0;
    
    while ( i < [self length] && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]]) {
        range.location++;
        range.length--;
        i++;
    }
    return [self substringWithRange:range];
}

-(NSString*)reverse:(NSString*)aString{
    NSMutableString *reversedString = [NSMutableString stringWithCapacity:[aString length]];

    [aString enumerateSubstringsInRange:NSMakeRange(0,[aString length])
                             options:(NSStringEnumerationReverse | NSStringEnumerationByComposedCharacterSequences)
                          usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                              [reversedString appendString:substring];
                       }];
    return [reversedString autorelease];
}

- (BOOL) containCharacter:(char)character {
    if ([self rangeOfString:[NSString stringWithFormat:@"%c",character]].location != NSNotFound){
        return YES;
    }
    return NO;
}

-(BOOL) isEmpty{
    NSUInteger i = 0;
    while ( i < [self length]){
        if( ![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]] ){
            break;
        }
        i++;
    }
    return i == [self length];
}

+ (NSString*)stringRandomWithLength:(NSUInteger)length {
    NSString *alphabet  = @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXZY0123456789";
    NSMutableString* string = [NSMutableString stringWithCapacity:length];
    for (NSUInteger i = 0; i < length; i++) {
        u_int32_t r = arc4random() % [alphabet length];
        unichar c = [alphabet characterAtIndex:r];
        [string appendFormat:@"%C", c];
    }
    return string;
}

-(NSString*)stringByAddingQuotesIfSpaces{
    NSRange range = [self rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (range.location != NSNotFound) {
        return [NSString stringWithFormat:@"""%@""", self];
    }
    return self;
}

-(NSString*)stringByExcapingSpaces{
    NSRange range = [self rangeOfCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]];
    if (range.location != NSNotFound) {
        return [NSString stringWithFormat:@"\"%@\"", self];
    }
    return self;
}

-(NSString*)stringByChopping{
    if( [self length] == 0 ){
        return self;
    }
    return [self substringToIndex:[self length]-1];
}
@end
