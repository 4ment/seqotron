//
//  MFSequence+MFSequenceDrawing.m
//  Seqotron
//
//  Created by Mathieu Fourment on 6/08/2014.
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

#import "MFSequence+MFSequenceDrawing.h"


NSString *MFDrawableSequenceIsTranslated = @"MFDrawableSequenceIsTranslated";
NSString *MFSpacingAttributeName = @"MFSpacingAttributeName";

@implementation MFSequence (MFSequenceDrawing)


- (void) drawAtPoint: (NSPoint)point withRange:(NSRange)range withAttributes: (NSDictionary*)attrs{
    NSString *sequence = [self subSequenceWithRange:range];
    
    NSFont *font = [attrs objectForKey: NSFontAttributeName];
    NSDictionary *foregroundDict = [attrs objectForKey: NSForegroundColorAttributeName];
    
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:sequence];
    [mutableAttributedString addAttribute:NSFontAttributeName
                                    value:font
                                    range:NSMakeRange(0, [sequence length])];

//    [mutableAttributedString addAttribute:NSKernAttributeName
//                                    value:[NSNumber numberWithFloat:1]
//                                    range:NSMakeRange(0, [sequence length])];
    
    if(foregroundDict != nil && [foregroundDict count] != 0 ){
        
        for ( int j = 0; j < [sequence length]; j++ ) {
            
            NSString *residue = [sequence substringWithRange:NSMakeRange(j, 1)];
            NSColor *foreground;
            
            if( [foregroundDict objectForKey:[residue uppercaseString]] != nil ){
                foreground = [foregroundDict objectForKey: [residue uppercaseString] ];
            }
            else if( [foregroundDict objectForKey:@"?"] != nil ){
                foreground = [foregroundDict objectForKey: @"?" ];
            }
            else{
                foreground = [NSColor blackColor];
            }
            
            [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:foreground range:NSMakeRange(j, 1)];
        }
    }
    
    [mutableAttributedString drawAtPoint:point];
    
    [mutableAttributedString release];
    
}

// draw one residue at a time
- (void) drawAtPoint2: (NSPoint)point withRange:(NSRange)range withAttributes: (NSDictionary*)attrs{
    NSString *sequence = [self subSequenceWithRange:range];
    
    NSFont *font = [attrs objectForKey: NSFontAttributeName];
    NSDictionary *foregroundDict = [attrs objectForKey: NSForegroundColorAttributeName];
    
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc] initWithString:@"A"];
    [mutableAttributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, 1)];
    CGFloat resWidth = [mutableAttributedString size].width;
    
    CGFloat spacing = 4;
    if( [attrs objectForKey: MFSpacingAttributeName] ){
        spacing = [[attrs objectForKey: MFSpacingAttributeName]floatValue];
    }
    
    
    NSPoint p = point;
        
    for ( int j = 0; j < [sequence length]; j++ ) {
        
        NSString *residue = [sequence substringWithRange:NSMakeRange(j, 1)];
        [[mutableAttributedString mutableString]setString:residue];
        NSColor *foreground;
        
        if( [foregroundDict objectForKey:[residue uppercaseString]] != nil ){
            foreground = [foregroundDict objectForKey: [residue uppercaseString] ];
        }
        else if( [foregroundDict objectForKey:@"?"] != nil ){
            foreground = [foregroundDict objectForKey: @"?" ];
        }
        else{
            foreground = [NSColor blackColor];
        }
        
        [mutableAttributedString addAttribute:NSFontAttributeName value:font range:NSMakeRange(0, 1)];
        [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:foreground range:NSMakeRange(0, 1)];
        [mutableAttributedString drawAtPoint:p];
        p.x += resWidth + spacing;
    }
    
    [mutableAttributedString release];
    
}

@end
