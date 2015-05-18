//
//  MFNamesView.m
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

#import "MFNamesView.h"

#import "NSObject+TDBindings.h"

@implementation MFNamesView

@synthesize fontName,fontSize,rowSpacing;

-(void)awakeFromNib {
    [super awakeFromNib];
    NSLog(@"MFNamesView view awakeFromNib");
    _attsDict = [[NSMutableDictionary alloc] init];
    
    fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontSize"]floatValue];
    fontName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontName"]copy];
    //_rowSpacing = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceRowSpacing"]floatValue];

    _sequences = nil;
    _selectionIndexes = nil;
    [self initSize];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(superviewResized:)
                                                 name:NSViewFrameDidChangeNotification object:[self superview]];
}

-(void)dealloc{
    NSLog(@"MFNanesView dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [fontName release];
    [_attsDict release];
    [_sequences release];
    [_selectionIndexes release];
    [super dealloc];
}

- (BOOL)isFlipped{
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}

- (void)drawRect:(NSRect)dirtyRect{
     // Draw background
     [[NSColor whiteColor] set];
     NSRectFill(dirtyRect);
    
    NSUInteger numberOfSequences = [_sequences count];
    if( numberOfSequences == 0 ){
        return;
    }
    
    NSUInteger nRow = MIN(ceil(dirtyRect.size.height/(_residueHeight + self.rowSpacing)), numberOfSequences);
    NSUInteger seqPos  = dirtyRect.origin.y/(_residueHeight + self.rowSpacing);
    
    // Draw selection background
    if( [self.selectionIndexes count] > 0 ){
        //[[[NSColor redColor]colorWithAlphaComponent:0.3]set];
        [[NSColor knobColor]set];
        
        for ( NSUInteger i = seqPos; i < MIN(numberOfSequences,seqPos+nRow); i++ ) {
            
            if( [self.selectionIndexes containsIndex:i] ){
                NSRect selected = NSMakeRect(0, (_residueHeight+self.rowSpacing)*i+self.rowSpacing/2, [self frame].size.width, (_residueHeight+self.rowSpacing));
                NSRectFillUsingOperation(selected, NSCompositeSourceAtop);
            }
        }
    }
    
    NSPoint point = NSMakePoint(0, 0);
    
    [[NSColor blackColor] set];
    // Unlike drawSequences in MFSequencesView I draw the whole the sequence name instead of the sequences visible in clipview
    for ( NSUInteger i = seqPos; i < MIN(numberOfSequences,seqPos+nRow); i++ ) {
        NSString *name = [_sequences objectAtIndex:i];
        point.y = (i * (_residueHeight + self.rowSpacing)) - _lineGap + self.rowSpacing;
        [name drawAtPoint:point withAttributes:_attsDict];
    }
}


- (void)mouseDown:(NSEvent *)anEvent {
    if( [_sequences count] == 0 ) return;
    
    if ( !([anEvent modifierFlags] & NSShiftKeyMask) ) {
        dragStartPoint = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    }
}

- (void)mouseUp:(NSEvent *)anEvent{
    dragPoint = [self convertPoint: [anEvent locationInWindow] fromView:nil];

    NSUInteger numberOfSequences = [_sequences count];
    
    NSUInteger seqStart  = dragStartPoint.y/(_residueHeight+self.rowSpacing);
    // more space in the scrollview than sequences and we clicked it: remove all selections if any
    if(seqStart >= numberOfSequences){
        if( [[self selectionIndexes] count] > 0 ){
            [self setSelectionIndexes:[NSIndexSet indexSet]];
            [self propagateValue:[NSIndexSet indexSet] forBinding:@"selectionIndexes"];
        }
        return;
    }
    
    NSUInteger seqEnd    = dragPoint.y/(_residueHeight+self.rowSpacing);
    
    if( seqEnd == seqStart && [[self selectionIndexes]containsIndex:seqStart] ){
        if( [[self selectionIndexes] count] == 1 ){
            [self setSelectionIndexes:[NSIndexSet indexSet] ];
            [self propagateValue:[NSIndexSet indexSet] forBinding:@"selectionIndexes"];
            return;
        }
        else if( [[self selectionIndexes] count] > 1 && [anEvent modifierFlags] & NSCommandKeyMask ){
            NSMutableIndexSet *indexes = [[self selectionIndexes]mutableCopy];
            [indexes removeIndex:seqEnd];
            [self setSelectionIndexes:indexes ];
            [self propagateValue:indexes forBinding:@"selectionIndexes"];
            [indexes release];
            return;
        }
    }
    
    seqEnd    = MAX(seqEnd,0); // check if released above the window
    seqEnd    = MIN(seqEnd, numberOfSequences-1);  // check if released above the window
    
    if(seqStart > seqEnd ){
        NSUInteger temp = seqEnd;
        seqEnd = seqStart;
        seqStart = temp;
    }

    NSMutableIndexSet *indexes;
        
    // replace selection
    // shift: extend selection
    if ( [anEvent modifierFlags] & NSShiftKeyMask ) {
        indexes = [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(seqStart, seqEnd-seqStart+1)];
        [indexes addIndexes:[self selectionIndexes]];
    }
    // command: add selection
    else if ( [anEvent modifierFlags] & NSCommandKeyMask ) {
        indexes = [[NSMutableIndexSet alloc] initWithIndex:seqEnd];
        [indexes addIndexes:[self selectionIndexes]];
        
    }
    else {
        indexes = [[NSMutableIndexSet alloc] initWithIndexesInRange:NSMakeRange(seqStart, seqEnd-seqStart+1)];
    }
    
    [self setSelectionIndexes:indexes];
    [self propagateValue:indexes forBinding:@"selectionIndexes"];
    [indexes release];
    
    [self autoscroll:anEvent];
    [self setNeedsDisplay: YES];
}

- (void)setSelectionIndexes:(NSIndexSet *)indexes{
    //if ( indexes != selectionIndexes ) {
        [_selectionIndexes release];
        _selectionIndexes = [indexes copy];
        [self setNeedsDisplay:YES];
    //}
}

- (NSIndexSet*)selectionIndexes{
    return _selectionIndexes;
}

- (void)setSequences:(NSArray *)seqs{
    if ( _sequences != seqs ) {
        [_sequences release];
        _sequences = [seqs copy];
        [self updateFrameSize];
        [self setNeedsDisplay:YES];
    }
}

- (NSArray*)sequences{
    return _sequences;
}

- (void)setFontSize:(CGFloat)size{
    if( fontSize != size ){
        fontSize = size;
        [self initSize];
        [self setNeedsDisplay:YES];
    }
}

- (CGFloat)fontSize{
    return fontSize;
}

- (void)setRowSpacing:(CGFloat)spacing{
    if( rowSpacing != spacing ){
        rowSpacing = spacing;
        [self setNeedsDisplay:YES];
    }
}

- (CGFloat)rowSpacing{
    return rowSpacing;
}

- (void)setFontName:(NSString*)name{
    if( [fontName isEqualToString:name] ){
        [fontName release];
        fontName = [name retain];
        [self initSize];
        [self setNeedsDisplay:YES];
    }
}

- (NSString*)fontName{
    return fontName;
}

- (void)superviewResized:(NSNotification *)notification{
    if( [_sequences count] > 0 ){
        [self updateFrameSize];
        [self setNeedsDisplay:YES];
    }
}

-(void)updateFrameSize{
    NSUInteger numberOfSequences = [_sequences count];
    
    NSUInteger maxLength = 0;
    for ( int i = 0; i < numberOfSequences; i++ ) {
        NSString *name = [_sequences objectAtIndex:i];
        if( [name length] > maxLength ){
            maxLength = [name length];
        }
    }
    
    NSSize superViewSize = [[self superview]bounds].size;
    
    NSSize size;
    size.height = (_residueHeight+self.rowSpacing) * numberOfSequences+self.rowSpacing;
    size.width  = _residueWidth  * maxLength;

    // not enough sequences to fill the scrollview vertically
    if(size.height < superViewSize.height){
        size.height = superViewSize.height;
    }
    // Sequence names are not long enough to fill the scrollview horizontally
    if(size.width < superViewSize.width){
        size.width = superViewSize.width;
    }
    
    if( !NSEqualSizes([self frame].size, size) ){
        [self setFrameSize:size];
    }
}

-(void)initSize{
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
    [_attsDict setObject:font forKey:NSFontAttributeName];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"A" attributes:_attsDict];
    
    _lineGap = [string size].height+[font descender] - [font capHeight];
    _residueHeight = [font capHeight];
    _residueWidth  = [string size].width;
    [string release];
    
}

@end
