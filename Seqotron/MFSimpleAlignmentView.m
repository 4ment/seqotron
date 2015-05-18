//
//  MFSimpleAlignmentView.m
//  Seqotron
//
//  Created by Mathieu Fourment on 3/03/2015.
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

#import "MFSimpleAlignmentView.h"

#import "MFSequence.h"
#import "MFSequence+MFSequenceDrawing.h"

@implementation MFSimpleAlignmentView

@synthesize sequences = _sequences;
@synthesize residueHeight = _residueHeight;
@synthesize foregroundColor = _foregroundColor;
@synthesize backgroundColor = _backgroundColor;

-(void)awakeFromNib {
    [super awakeFromNib];
    NSLog(@"MFSimpleAlignmentView view awakeFromNib");
    
    _foregroundColor = nil;
    _backgroundColor = nil;
    
    _drawBackground = NO;
    _canvasColor = [NSColor whiteColor];
    
    _sequences = nil;
    _fontSize = 15;
    _fontName = [[NSString alloc] initWithString: @"Courier"];
    _rowSpacing = 4;
    _attsDict = [[NSMutableDictionary alloc] init];
    [_attsDict setObject:[NSFont fontWithName:_fontName size:_fontSize] forKey:NSFontAttributeName];
    [self initSize];
}

-(void)dealloc{
    [_sequences release];
    [_fontName release];
    [_attsDict release];
    [super dealloc];
}

- (BOOL)isFlipped{
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
    
    NSUInteger numberOfSequences = [[self sequences] count];
    if ( numberOfSequences == 0 ) {
        return;
    }
    
    // These NSRanges represent the  number of rows (sequences) and (columns) sites that can be displayed in the NSScrollView (without copying)
    NSRange siteRange;
    NSRange seqRange;
    NSUInteger numberOfSites = [[[self sequences]objectAtIndex:0]length];
    
    siteRange.length = MIN(numberOfSites, ceil(dirtyRect.size.width/_residueWidth));
    seqRange.length  = MIN(numberOfSequences, ceil(dirtyRect.size.height/(_residueHeight + _rowSpacing)));
    
    siteRange.location  = dirtyRect.origin.x/_residueWidth;
    seqRange.location   = dirtyRect.origin.y/(_residueHeight + _rowSpacing);
    
    NSPoint point;
    
    for ( NSUInteger i = seqRange.location; i < seqRange.location+seqRange.length; i++ ) {
        
        MFSequence *sequence = [_sequences objectAtIndex: i];
        
        point.x = siteRange.location * _residueWidth;
        point.y = (i+1)*_rowSpacing+ i*_residueHeight - _rowSpacing/2;
        
        if( _drawBackground ){
            [self drawBackgroundForSequence:sequence InRange:NSMakeRange(siteRange.location, siteRange.length) atPoint:point];
        }
        
        point.y = (i * (_residueHeight + _rowSpacing)) - _lineGap + _rowSpacing;
        [sequence drawAtPoint:point withRange:NSMakeRange(siteRange.location, siteRange.length) withAttributes:_attsDict];
    }
}

-(void)drawBackgroundForSequence:(MFSequence*)sequence InRange:(NSRange)siteRange atPoint:(NSPoint)point{
    
    NSRect rect = NSMakeRect(point.x, point.y, _residueWidth, _residueHeight+_rowSpacing);
    
    for ( NSUInteger j = siteRange.location; j < siteRange.location+siteRange.length; j++ ) {
        NSString *residue = [sequence subSequenceWithRange:NSMakeRange(j, 1)];
        NSColor *background;
        
        if( [_backgroundColor objectForKey:[residue uppercaseString]] != nil ){
            background = [_backgroundColor objectForKey: [residue uppercaseString] ];
        }
        else if( [_backgroundColor objectForKey:@"?"] != nil ){
            background = [_backgroundColor objectForKey: @"?" ];
        }
        else{
            background = [NSColor grayColor];
        }
        [background set];
        NSRectFill(rect);
        rect.origin.x += _residueWidth;
    }
}

-(void)setForegroundColor:(NSMutableDictionary*)colors{
    if ( _foregroundColor != colors ) {
        [_foregroundColor release];
        _foregroundColor = [colors retain];
        [_attsDict setObject:_foregroundColor forKey:NSForegroundColorAttributeName];
    }
    [self setNeedsDisplay:YES];
}

-(void)setBackgroundColor:(NSMutableDictionary*)colors{
    if ( _backgroundColor != nil ) {
        [_backgroundColor release];
    }
    _backgroundColor = [colors retain];
    [_attsDict setObject:_backgroundColor forKey:NSBackgroundColorAttributeName];
    
    
    
    if( _backgroundColor == nil || [_backgroundColor count] == 0 ){
        _drawBackground = NO;
        _canvasColor = [NSColor whiteColor];
    }
    else {
        NSColor *backgroundCol = [self commonColorBackground];
        if( !backgroundCol ){
            _drawBackground = YES;
            _canvasColor = [NSColor whiteColor];
        }
        else {
            _drawBackground = NO;
            _canvasColor = backgroundCol;
        }
    }
    
    
    [self setNeedsDisplay:YES];
}

-(NSColor *)commonColorBackground{
    
    NSArray *values = [_backgroundColor allValues];
    NSColor *color = [values objectAtIndex:0];
    for ( NSUInteger i = 1; i < [values count]; i++ ) {
        if( ![color  isEqualTo:[values objectAtIndex:i]] ){
            color = nil;
            break;
        }
    }
    
    return color;
}

-(void)initSize{
    NSMutableDictionary *attsDict = [[NSMutableDictionary alloc] init];
    NSFont *font = [NSFont fontWithName:_fontName size:_fontSize];
    [attsDict setObject:font forKey:NSFontAttributeName];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"A" attributes:attsDict];
    //_rowHeight     = [font capHeight]+_rowSpacing;//[string size].height - 4;
    
    _lineGap = [string size].height+[font descender] - [font capHeight];
    _rowHeight     = [string size].height - _lineGap;
    _residueHeight = [font capHeight];
    _residueWidth  = [string size].width;
    [string release];
    [attsDict release];
    
}

@end
