//
//  MFSequencesView.m
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

#import "MFSequencesView.h"

#import "MFDefines.h"

#import "MFSequence.h"
#import "MFSequence+MFSequenceDrawing.h"
#import "MFSequenceUtils.h"
#import "MFNucleotide.h"


#import "MFSequenceSet.h"
#import "MFSequenceReader.h"
#import "MFSequenceWriter.h"

NSString *MFSequenceViewForegroundColorBindingName = @"foregroundColor";
NSString *MFSequenceViewBackgroundColorBindingName = @"backgroundColor";

NSString *MFTranslationDidChangeNotification = @"MFTranslationDidChange";

@implementation MFSequencesView

@synthesize delegate;
@synthesize rangeSelection = _rangeSelection;
@synthesize mouseOverSequence = _mouseOverSequence;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
    }
    return self;
}

-(void)awakeFromNib {
    [super awakeFromNib];
    NSLog(@"awakeFromNib SequenceView");
    
    _attsDict = [[NSMutableDictionary alloc] init];
    [_attsDict setObject:[NSFont fontWithName:_fontName size:_fontSize] forKey:NSFontAttributeName];
    
    _foregroundColor = nil;
    _backgroundColor = nil;
    
    _drawBackground = NO;
    _canvasColor = [NSColor whiteColor];
    
    _unknownBackgroundColor = [NSColor grayColor];
    _marqueeAlpha = 0.3;
    _marqueeColor = [NSColor redColor];//[[NSColor redColor]colorWithAlphaComponent:0.3];
    
    _siteSelectionIndexes = [[NSMutableIndexSet alloc] init];
    _rangeSelection = MFMakeEmpty2DRange();
    
    _isTranslated = NO;
    
    _maximumNumberOfSites = 0;
    
    _mutableAttributedString = [[NSMutableAttributedString alloc]init];
    _fakeInsertionRange = NSMakeRange(0, 0);
    _fakeDeletionRange  = NSMakeRange(0, 0);
    
    [self createTrackingArea];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(translationDidChange:) name:MFTranslationDidChangeNotification object:nil];
    
}

-(void)dealloc{
    NSLog(@"MFSequenceView dealloc");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_mutableAttributedString release];
    [_attsDict release];
    [_foregroundColor release];
    [_backgroundColor release];
    [_siteSelectionIndexes release];
    [trackingArea release];
    [_mouseOverSequence release];
    [super dealloc];
}

#pragma mark *** Drawing Methods ***

- (void)drawRect:(NSRect)dirtyRect {
    
    // Draw background
    [[NSColor whiteColor] set];
	NSRectFill(dirtyRect);
    
    NSArray *sequences = [self sequences];
    NSUInteger numberOfSequences = [sequences count];
    
    if(numberOfSequences == 0 ){
        return;
    }
    
    [_attsDict setObject:[NSFont fontWithName:_fontName size:_fontSize] forKey:NSFontAttributeName];
    
    _maximumNumberOfSites =  [self numberOfSites];
    
    [self updateFrameSize];
    
    [self drawSequences: dirtyRect];
    
    if( [_backgroundColor count] == 0 ){
        [self drawSelection: dirtyRect];
    }
    else {
        [self drawSelection2:dirtyRect];
    }
    
}

-(NSRect)selectionRect{
    NSRect rectSelection;
    
    rectSelection.origin.x   = _rangeSelection.x.location * _residueWidth;
    rectSelection.size.width = _rangeSelection.x.length   * _residueWidth;
    
    rectSelection.origin.y    = _rangeSelection.y.location * (_residueHeight+_rowSpacing)+_rowSpacing/2;
    rectSelection.size.height = _rangeSelection.y.length   * (_residueHeight+_rowSpacing);
    return rectSelection;
}

-(void)drawSelection:(NSRect)dirtyRect{
    
    if ( [[self selectedSequences] count] != 0 ) {
        
    }
    else if( [_siteSelectionIndexes count] != 0 ){
        
    }
    else {
        
        if( _rangeSelection.x.length != 0 || _rangeSelection.y.length != 0 ){
            [[_marqueeColor colorWithAlphaComponent:_marqueeAlpha] set];
            NSRect rectSelection = [self selectionRect];
            
            NSRectFillUsingOperation(rectSelection, NSCompositeSourceAtop);
        }
        
    }
}

// This method draws the selection on top of the regular alignment.
// It would be better to draw selection first and then draw the rest of the alignment around it.
-(void)drawSelection2:(NSRect)dirtyRect{
    
    if ( [[self selectedSequences] count] != 0 ) {
        
    }
    else if( [_siteSelectionIndexes count] != 0 ){
        
    }
    else {
        
        if( _rangeSelection.x.length != 0 || _rangeSelection.y.length != 0 ){
            

            NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc]init];
            
            NSRect rectSelection = [self selectionRect];
            [[NSColor redColor] set];
            CGRect intersectRect = CGRectIntersection(rectSelection, dirtyRect);
            NSRectFill(intersectRect);
            
            NSRange siteRange;
            NSRange seqRange;
            
            [self getSelectionSequenceRange: &seqRange siteRange:&siteRange inRect:dirtyRect];
            
            if(  _fakeDeletionRange.length != 0 ){
                siteRange.location += _fakeDeletionRange.length;
            }
            else if( _fakeInsertionRange.length != 0 ){
                
                siteRange.location -= _fakeInsertionRange.length;
            }

            
            for ( NSUInteger i = seqRange.location; i < seqRange.location+seqRange.length; i++ ) {
                NSPoint point = NSMakePoint(siteRange.location*_residueWidth,  (i * (_residueHeight + _rowSpacing)) - _lineGap + _rowSpacing);
                
                if(  _fakeDeletionRange.length != 0 ){
                    point.x -= _fakeDeletionRange.length *_residueWidth;
                }
                else if( _fakeInsertionRange.length != 0 ){
                    point.x += _fakeInsertionRange.length *_residueWidth;
                }
                
                MFSequence *sequence = [[self sequences] objectAtIndex:i];
                
                
                NSString *seqString = [sequence subSequenceWithRange:siteRange];
                [[mutableAttributedString mutableString] setString:seqString];
                [mutableAttributedString addAttribute:NSFontAttributeName value:[NSFont fontWithName:_fontName size:_fontSize] range:NSMakeRange(0, [seqString length])];
                [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, [seqString length])];
                
                [mutableAttributedString drawAtPoint:point];
            }
            [mutableAttributedString release];
        }
        
    }
}

-(void)getSelectionSequenceRange:(NSRange*)seqRange siteRange:(NSRange*)siteRange inRect:(NSRect)dirtyRect{
    
    NSUInteger numberOfSequences = [[self sequences] count];
    
    NSRect rectSelection = [self selectionRect];
    CGRect intersectRect = CGRectIntersection(rectSelection, dirtyRect);
    
    
    siteRange->length = MIN(ceil(intersectRect.size.width/_residueWidth),   _maximumNumberOfSites);
    seqRange->length  = MIN(ceil(intersectRect.size.height/(_residueHeight + _rowSpacing)), numberOfSequences);
    
    siteRange->location  = intersectRect.origin.x/_residueWidth;
    seqRange->location   = intersectRect.origin.y/(_residueHeight + _rowSpacing);
    
    if( siteRange->location + siteRange->length > _maximumNumberOfSites ){
        //siteRange.length  -= siteRange.location + siteRange.length - _maximumNumberOfSites;
    }
    if( seqRange->location + seqRange->length > numberOfSequences ){
        seqRange->length  -= seqRange->location + seqRange->length - numberOfSequences;
    }

}

-(void)drawSequences:(NSRect)dirtyRect{
    
    NSUInteger numberOfSequences = [[self sequences] count];
    
    // These NSRanges represent the  number of rows (sequences) and (columns) sites that can be displayed in the NSScrollView (without copying)
    // Not including the insertion
    NSRange siteRange;
    NSRange seqRange;
    
    siteRange.length = ceil(dirtyRect.size.width/_residueWidth);
    seqRange.length  = ceil(dirtyRect.size.height/(_residueHeight + _rowSpacing));
    
    siteRange.location  = dirtyRect.origin.x/_residueWidth;
    seqRange.location   = dirtyRect.origin.y/(_residueHeight + _rowSpacing);
    
    // Outside of bounds. When we drag a large region
    if( siteRange.location >= _maximumNumberOfSites ){
        siteRange.length = 0;
    }
    else if( siteRange.location + siteRange.length > _maximumNumberOfSites ){
        siteRange.length  =  _maximumNumberOfSites - siteRange.location;
    }
    if( seqRange.location + seqRange.length > numberOfSequences ){
        seqRange.length  -= seqRange.location + seqRange.length - numberOfSequences;
    }

    if( _drawBackground ){
        [self drawBackgroundForSequencesinRange:seqRange inSiteRange:siteRange inRect:dirtyRect];
    }

    [self drawForegroudForSequencesinRange:seqRange inSiteRange:siteRange inRect:dirtyRect];
}


-(void)drawForegroudForSequencesinRange:(NSRange)seqRange inSiteRange:(NSRange)siteRange inRect:(NSRect)dirty{
    
    // These NSRanges represent the width and height of the view in terms of number of sites and sequences, respectively
    NSRange siteViewRange;
    NSRange seqViewRange;
    
    siteViewRange.length = ceil(dirty.size.width/_residueWidth);
    seqViewRange.length  = ceil(dirty.size.height/(_residueHeight + _rowSpacing));
    
    siteViewRange.location  = dirty.origin.x/_residueWidth;
    seqViewRange.location   = dirty.origin.y/(_residueHeight + _rowSpacing);
    
    NSArray *sequences = [self sequences];
    NSUInteger alignmentLength = [[sequences objectAtIndex: 0] length];
    
    NSUInteger sitePos = siteRange.location;
    NSUInteger nCol    = siteRange.length;
    
    NSUInteger nSiteLeftVisible = 0;
    NSUInteger nGapVisible = 0;
    NSUInteger nSiteRightVisible = 0;
    
    // number of residues visible after the insertion
    NSInteger nResidues = 0;
    // We have an insertion from dragging right or left
    if(_fakeInsertionRange.length > 0 ){
        
        // there are some sites
        if( _fakeInsertionRange.location > sitePos ){
            nSiteLeftVisible = _fakeInsertionRange.location-sitePos;
            nGapVisible = _fakeInsertionRange.length;
        }
        // it starts with fake gaps
        else {
            // when we drag left and it starts with gaps there can be no gaps visible
            if( _fakeInsertionRange.location + _fakeInsertionRange.length > sitePos ){
                nGapVisible = _fakeInsertionRange.location + _fakeInsertionRange.length - sitePos;
            }
        }
        
        nSiteRightVisible = MIN(alignmentLength - _fakeInsertionRange.location, siteViewRange.length - nGapVisible - nSiteLeftVisible);
        
        
        
        NSUInteger len = _fakeInsertionRange.length;
        // calculate the number of visible residues after the insertion
        if( nCol+sitePos > _fakeInsertionRange.location + _fakeInsertionRange.length){
            nResidues = nCol+sitePos - _fakeInsertionRange.location - _fakeInsertionRange.length;
            // substract the number of visible residues (nResidues) from the number of visible sites (nCol)
            // since the first visible site is a gap
            if( _fakeInsertionRange.location < sitePos ){
                len = nCol - nResidues;
            }
        }
        // When we drag left and we hit the scrollview the number of visible gaps can be 0
        if( nResidues < nCol){
            [[_mutableAttributedString mutableString] setString:@"-"];
            for ( int i = 1; i < len; i++ ) {
                [[_mutableAttributedString mutableString]appendString:@"-" ];
            }
            [_mutableAttributedString addAttribute:NSFontAttributeName value:[_attsDict objectForKey: NSFontAttributeName] range:NSMakeRange(0, len)];
            [_mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, len)];
        }
        
        
    }

    NSPoint point;
    
    for ( NSUInteger i = seqRange.location; i < seqRange.location+seqRange.length; i++ ) {
        
        MFSequence *sequence = [sequences objectAtIndex: i];
        
        point.x = sitePos * _residueWidth;
        point.y = (i * (_residueHeight + _rowSpacing)) - _lineGap + _rowSpacing;
        
        if(  _fakeInsertionRange.length != 0 && _fakeDeletionRange.length != 0 &&  NSLocationInRange(i, _rangeSelection.y) ){
            // Draw sequence up to deletion
            if( _fakeDeletionRange.location > sitePos){
                [sequence drawAtPoint:point withRange:NSMakeRange(sitePos, _fakeDeletionRange.location-sitePos) withAttributes:_attsDict];
            }
            
            // Draw the selection that we used to drag
            point.x += (_fakeDeletionRange.location-sitePos)*_residueWidth;
            [sequence drawAtPoint:point withRange:NSMakeRange(_fakeDeletionRange.location+_fakeDeletionRange.length, _rangeSelection.x.length) withAttributes:_attsDict];
            
            // Draw the insertion
            point.x += _rangeSelection.x.length*_residueWidth;
            [_mutableAttributedString drawAtPoint:point];
            
            // Draw the rest
            if( _fakeDeletionRange.location+_fakeDeletionRange.length+_rangeSelection.x.length < [sequence length]){
                point.x += _fakeInsertionRange.length*_residueWidth;
                [sequence drawAtPoint:point withRange:NSMakeRange(_fakeDeletionRange.location+_fakeDeletionRange.length+_rangeSelection.x.length, nResidues) withAttributes:_attsDict];
            }
            
        }
        else if( _fakeInsertionRange.length != 0 &&  NSLocationInRange(i, _rangeSelection.y) ){
            
            if( nSiteLeftVisible > 0 ){
                [sequence drawAtPoint:point withRange:NSMakeRange(sitePos, nSiteLeftVisible) withAttributes:_attsDict];
                point.x += nSiteLeftVisible * _residueWidth;
            }
            
            if( nGapVisible > 0 ){
                [_mutableAttributedString drawAtPoint:point];
            }

            if( nSiteRightVisible > 0 ){
                point.x += nGapVisible * _residueWidth;
                [sequence drawAtPoint:point withRange:NSMakeRange(_fakeInsertionRange.location, nSiteRightVisible) withAttributes:_attsDict];
            }

        }
        else if( _fakeDeletionRange.length != 0 &&  NSLocationInRange(i, _rangeSelection.y) ){
            NSUInteger n = 0; // number of sites before the deletion
            if( _fakeDeletionRange.location > sitePos ){
                [sequence drawAtPoint:point withRange:NSMakeRange(sitePos, _fakeDeletionRange.location-sitePos) withAttributes:_attsDict];
                n = _fakeDeletionRange.location-sitePos;
            }
            point.x += (_fakeDeletionRange.location-sitePos)*_residueWidth;
            [sequence drawAtPoint:point withRange:NSMakeRange(_fakeDeletionRange.location+_fakeDeletionRange.length, nCol-(n+_fakeDeletionRange.length)) withAttributes:_attsDict];
        }
        else {
            if( nCol > 0){
                NSUInteger nRes = nCol;
                if( nCol < siteViewRange.length && _fakeDeletionRange.length != 0 && _fakeInsertionRange.length == 0  ){
                    nRes -= _fakeDeletionRange.length;
                }
                [sequence drawAtPoint:point withRange:NSMakeRange(sitePos, nRes) withAttributes:_attsDict];
            }
            // The sequence is too short and there is an insertion
            if( nCol < siteViewRange.length && _fakeInsertionRange.length != 0 ){
                NSUInteger nGaps = MIN(_fakeInsertionRange.length, siteViewRange.length-nCol);
                point.x += nCol*_residueWidth;
                [self drawForegroundGaps:nGaps atPoint:point];
            }
        }
    }
}

-(void)drawBackgroundForSequencesinRange:(NSRange)seqRange inSiteRange:(NSRange)siteRange inRect:(NSRect)dirty{
    
    // These NSRanges represent the width and height of the view in terms of number of sites and sequences, respectively
    NSRange siteViewRange;
    NSRange seqViewRange;
    
    siteViewRange.length = ceil(dirty.size.width/_residueWidth);
    seqViewRange.length  = ceil(dirty.size.height/(_residueHeight + _rowSpacing));
    
    siteViewRange.location  = dirty.origin.x/_residueWidth;
    seqViewRange.location   = dirty.origin.y/(_residueHeight + _rowSpacing);
    
    NSArray *sequences = [self sequences];
    NSUInteger alignmentLength = [[sequences objectAtIndex: 0] length];
    
    NSUInteger sitePos = siteRange.location;
    NSUInteger nCol    = siteRange.length;
    
    NSUInteger nSiteLeftVisible = 0;
    NSUInteger nGapVisible = 0;
    NSUInteger nSiteRightVisible = 0;
    
    // number of residues visible after the insertion
    NSInteger nResidues = 0;
    // We have an insertion from dragging right or left
    if(_fakeInsertionRange.length > 0 ){
        
        // there are some sites
        if( _fakeInsertionRange.location > sitePos ){
            nSiteLeftVisible = _fakeInsertionRange.location-sitePos;
            nGapVisible = _fakeInsertionRange.length;
        }
        // it starts with fake gaps
        else {
            // when we drag left and it starts with gaps there can be no gaps visible
            if( _fakeInsertionRange.location + _fakeInsertionRange.length > sitePos ){
                nGapVisible = _fakeInsertionRange.location + _fakeInsertionRange.length - sitePos;
            }
        }
        
        nSiteRightVisible = MIN(alignmentLength - _fakeInsertionRange.location, siteViewRange.length - nGapVisible - nSiteLeftVisible);
        
        
        
        NSUInteger len = _fakeInsertionRange.length;
        // calculate the number of visible residues after the insertion
        if( nCol+sitePos > _fakeInsertionRange.location + _fakeInsertionRange.length){
            nResidues = nCol+sitePos - _fakeInsertionRange.location - _fakeInsertionRange.length;
            // substract the number of visible residues (nResidues) from the number of visible sites (nCol)
            // since the first visible site is a gap
            if( _fakeInsertionRange.location < sitePos ){
                len = nCol - nResidues;
            }
        }
        // When we drag left and we hit the scrollview the number of visible gaps can be 0
        if( nResidues < nCol){
            [[_mutableAttributedString mutableString] setString:@"-"];
            for ( int i = 1; i < len; i++ ) {
                [[_mutableAttributedString mutableString]appendString:@"-" ];
            }
            [_mutableAttributedString addAttribute:NSFontAttributeName value:[_attsDict objectForKey: NSFontAttributeName] range:NSMakeRange(0, len)];
            [_mutableAttributedString addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(0, len)];
        }
        
        
    }
    
    NSPoint point;
    
    for ( NSUInteger i = seqRange.location; i < seqRange.location+seqRange.length; i++ ) {
        
        MFSequence *sequence = [sequences objectAtIndex: i];
        
        point.x = sitePos * _residueWidth;
        point.y = (i+1)*_rowSpacing+ i*_residueHeight - _rowSpacing/2;
        
        if(  _fakeInsertionRange.length != 0 && _fakeDeletionRange.length != 0 &&  NSLocationInRange(i, _rangeSelection.y) ){
            
            // Draw sequence up to deletion
            if( _fakeDeletionRange.location > sitePos){
                [self drawBackgroundForSequence:sequence InRange:NSMakeRange(sitePos, _fakeDeletionRange.location-sitePos) atPoint:point];
            }
            
            // Draw the selection that we used to drag
            point.x += (_fakeDeletionRange.location-sitePos)*_residueWidth;
            [self drawBackgroundForSequence:sequence InRange:NSMakeRange(_fakeDeletionRange.location+_fakeDeletionRange.length, _rangeSelection.x.length) atPoint:point];
            
            // Draw the insertion
            point.x += _rangeSelection.x.length*_residueWidth;
            [self drawBackgroundGaps:_fakeInsertionRange.length atPoint:point];
            
            // Draw the rest
            if( _fakeDeletionRange.location+_fakeDeletionRange.length+_rangeSelection.x.length < [sequence length]){
                point.x += _fakeInsertionRange.length*_residueWidth;
                [self drawBackgroundForSequence:sequence InRange:NSMakeRange(_fakeDeletionRange.location+_fakeDeletionRange.length+_rangeSelection.x.length, nResidues) atPoint:point];
            }
            
        }
        else if( _fakeInsertionRange.length != 0 &&  NSLocationInRange(i, _rangeSelection.y) ){
            
            if( nSiteLeftVisible > 0 ){
                [self drawBackgroundForSequence:sequence InRange:NSMakeRange(sitePos, nSiteLeftVisible) atPoint:point];
                point.x += nSiteLeftVisible * _residueWidth;
            }
            
            if( nGapVisible > 0 ){
                [self drawBackgroundGaps:_fakeInsertionRange.length atPoint:point];
            }
            
            if( nSiteRightVisible > 0 ){
                point.x += nGapVisible * _residueWidth;
                [self drawBackgroundForSequence:sequence InRange:NSMakeRange(_fakeInsertionRange.location, nSiteRightVisible) atPoint:point];
            }
            
        }
        else if( _fakeDeletionRange.length != 0 &&  NSLocationInRange(i, _rangeSelection.y) ){
            NSUInteger n = 0; // number of sites before the deletion
            if( _fakeDeletionRange.location > sitePos ){
                [self drawBackgroundForSequence:sequence InRange:NSMakeRange(sitePos, _fakeDeletionRange.location-sitePos) atPoint:point];
                n = _fakeDeletionRange.location-sitePos;
            }
            point.x += (_fakeDeletionRange.location-sitePos)*_residueWidth;
            [self drawBackgroundForSequence:sequence InRange:NSMakeRange(_fakeInsertionRange.location, nResidues) atPoint:point];
        }
        else {
            if( nCol > 0){
                NSUInteger nRes = nCol;
                if( nCol < siteViewRange.length && _fakeDeletionRange.length != 0 && _fakeInsertionRange.length == 0  ){
                    nRes -= _fakeDeletionRange.length;
                }
                [self drawBackgroundForSequence:sequence InRange:NSMakeRange(sitePos, nRes) atPoint:point];
            }
            // The sequence is too short and there is an insertion
            if( nCol < siteViewRange.length && _fakeInsertionRange.length != 0 ){
                NSUInteger nGaps = MIN(_fakeInsertionRange.length, siteViewRange.length-nCol);
                point.x += nCol*_residueWidth;
                [self drawBackgroundGaps:nGaps atPoint:point];
            }
        }
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

-(void)drawBackgroundGaps:(NSUInteger)nGaps atPoint:(NSPoint)point{
    
    NSRect rect = NSMakeRect(point.x, point.y, _residueWidth*nGaps, _residueHeight+_rowSpacing);
    NSColor *background;
    
    if( [_backgroundColor objectForKey:@"-"] != nil ){
        background = [_backgroundColor objectForKey: @"-" ];
    }
    else{
        background = [NSColor grayColor];
    }
    [background set];
    NSRectFill(rect);
}

-(void)drawForegroundGaps:(NSUInteger)nGaps atPoint:(NSPoint)point{
    NSColor *foreground = [NSColor grayColor];

    
    NSMutableAttributedString *mutableAttributedString = [[NSMutableAttributedString alloc]init];
    [[mutableAttributedString mutableString] setString:@"-"];
    for ( int i = 1; i < nGaps; i++ ) {
        [[mutableAttributedString mutableString]appendString:@"-" ];
    }
    [mutableAttributedString addAttribute:NSFontAttributeName value:[_attsDict objectForKey: NSFontAttributeName] range:NSMakeRange(0, nGaps)];
    [mutableAttributedString addAttribute:NSForegroundColorAttributeName value:foreground range:NSMakeRange(0, nGaps)];
    
    [mutableAttributedString drawAtPoint:point];
    [mutableAttributedString release];
}

#pragma mark *** Mouse Event Handling ***

- (void)mouseDown:(NSEvent *)anEvent {
    
    _fakeInsertionRange = NSMakeRange(0, 0);
    _fakeDeletionRange  = NSMakeRange(0, 0);
    
    if( [[self sequences] count] == 0 ) return;
    
    NSPoint location = [self convertPoint:[anEvent locationInWindow] fromView:nil];
    
    dragging = NO;
    
    // There is something already selected
    if ( !MFIsEmpty2DRange(_rangeSelection) ) {
        NSUInteger seq  = location.y/(_residueHeight+_rowSpacing);
        NSUInteger site = location.x/_residueWidth;

        // We clicked inside the selection
        if( MFLocationsin2DRange(site, seq, _rangeSelection) ){
            
            // Moving blocks of gaps is not allowed
            MF2DRange range = _rangeSelection;
            NSUInteger i = range.y.location;
            for ( ; i < range.y.location+range.y.length; i++ ) {
                MFSequence *sequence = [[self sequences ]objectAtIndex: i];
                NSUInteger j = range.x.location;
                for ( ; j < range.x.location+range.x.length; j++ ) {
                    if([sequence residueAt:j] != '-') break;
                }
                if(j != range.x.location+range.x.length)break;
            }
            
            // The block is not just gaps
            if(i != range.y.location+range.y.length){
                if(firstDrag) secondaryDrag = YES;
                firstDrag = YES;
                dragging = YES;
                _fakeInsertionRange.location = _rangeSelection.x.location;
                _fakeDeletionRange.location  = _rangeSelection.x.location;
            }
        }
        else{
            // Expand selection when shift is pressed
            if( [anEvent modifierFlags] & NSShiftKeyMask ){
                if( site >= _rangeSelection.x.location + _rangeSelection.x.length){
                    _rangeSelection.x.length = site - _rangeSelection.x.location + 1;
                }
                else {
                    _rangeSelection.x.length += _rangeSelection.x.location - site;
                    _rangeSelection.x.location = site;
                }
                
                if( seq >= _rangeSelection.y.location + _rangeSelection.y.length){
                    _rangeSelection.y.length = seq - _rangeSelection.y.location + 1;
                }
                else {
                    _rangeSelection.y.length += _rangeSelection.y.location - seq;
                    _rangeSelection.y.location = seq;
                }
            }            
            firstDrag = secondaryDrag = NO;
        }
    }
    
    if( !dragging ){
        if( !([anEvent modifierFlags] & NSShiftKeyMask) ){
            _rangeSelection = MFMakeEmpty2DRange();
            if( [[self selectionIndexes] count] > 0 ){
                [self changeSelectionIndexes:[NSIndexSet indexSet] ];
            }
            [_siteSelectionIndexes removeAllIndexes];
            firstDrag = secondaryDrag = NO;
        }
    }
    
    _pingpong = NO;
    
    // should empty site and sequence selection sets
    
    dragStartPoint = location;
    [self setNeedsDisplay:YES];
}


// Drag repositions any selected shapes
- (void)mouseDragged:(NSEvent *)anEvent {
    
    if( [[self sequences] count] == 0 ) return;
    
    dragPoint = [self convertPoint: [anEvent locationInWindow] fromView:nil];

    // Not dragging and did not move enough
    if ( !dragging && !secondaryDrag && fabs(dragPoint.x-dragStartPoint.x) < _residueWidth/4 && fabs(dragPoint.y-dragStartPoint.y) < _rowHeight/4 ) {
        return;
    }
    
    MF2DRange range = [self convertSelectionPoints];
    
    if( dragging ){
        NSUInteger startResidue = dragStartPoint.x/_residueWidth;
        NSUInteger endResidue   = dragPoint.x/_residueWidth;

        // Moved right: insert gaps if needed
        if( endResidue > startResidue){
            NSUInteger nGaps = endResidue - startResidue;
            // change of direction without mouse up: shift right
            if( _fakeDeletionRange.length != 0 ){
                NSUInteger allowedGaps = MIN(_fakeInsertionRange.length, nGaps);
                _fakeInsertionRange.location += allowedGaps;
                _fakeInsertionRange.length   -= allowedGaps;
                
                _fakeDeletionRange.location  += allowedGaps;
                _fakeDeletionRange.length    -= allowedGaps;
                
                _rangeSelection.x.location += allowedGaps;
            }
            // Avoid pushing the sequences
            else if( _pingpong ){
                
            }
            else {
                draggedRight = YES;
                
                NSArray *unselectedSequences = [self unselectedSequencesInRangeSelection];
                NSUInteger maxLengthNotSelected = [MFSequenceUtils maxLength:unselectedSequences];
                
                // move the rangeSelection to its new location but we don't want create empty columns
                //if( _rangeSelection.x.location < maxLengthNotSelected){
                    nGaps = MIN(nGaps, maxLengthNotSelected-_rangeSelection.x.location);
                    _rangeSelection.x.location += nGaps;
                    _fakeInsertionRange.length += nGaps;
                //}
                
            }
        }
        // Moved left: remove gaps if needed
        else if( endResidue < startResidue){
            // Proposed number of gaps to be removed
            NSUInteger nGaps =  startResidue - endResidue;
            
            // Actual number of gaps that we can remove
            NSUInteger actualNGaps = 0;
            
            // If it was previously dragged right without releasing the button: shift the whole sequences
            if( draggedRight ){
                if( nGaps <= _fakeInsertionRange.length ){
                    actualNGaps = nGaps;
                    _fakeInsertionRange.length -= actualNGaps;
                }
                else {
                    actualNGaps = [self test:nGaps beforeSequenceIndex:_rangeSelection.x.location inSiteRange:_rangeSelection.y];
                    _fakeDeletionRange.length   += actualNGaps;
                    _fakeDeletionRange.location -= actualNGaps;
                }
            }
            // We only move the block represented by rangeSelection
            // no change of length unless we move residues in the last columns and the other residues (in the same columns) are gaps!
            else {
                actualNGaps = [self test:nGaps beforeSequenceIndex:_rangeSelection.x.location inSiteRange:_rangeSelection.y];
                if( actualNGaps > 0 ){
                    _fakeDeletionRange.length   += actualNGaps;
                    _fakeDeletionRange.location -= actualNGaps;
                    
                    if ( _fakeDeletionRange.length + _rangeSelection.x.location + _rangeSelection.x.length < [self numberOfSites]) {
                        _fakeInsertionRange.length   += actualNGaps;
                        _fakeInsertionRange.location = _fakeDeletionRange.location+_rangeSelection.x.length;
                    }
                }
                _pingpong = YES;
            }
            
            _rangeSelection.x.location -= actualNGaps;
        }
        dragStartPoint.x = dragPoint.x;
        [self updateFrameSize];
    }
    else{
        _rangeSelection = range;
    }

    [self autoscroll:anEvent];
    [self setNeedsDisplay:YES];
    
}

- (void)mouseUp:(NSEvent *)anEvent{
    
    if( [[self sequences] count] == 0 ) return;
    
    dragEndPoint = [self convertPoint: [anEvent locationInWindow] fromView:nil];
    

    // Shifting (Insertion+deletion)
    if( _fakeInsertionRange.length != 0 && _fakeDeletionRange.length != 0 ){
        NSRange temp = _fakeDeletionRange;
        _fakeInsertionRange = NSMakeRange(0, 0);
        _fakeDeletionRange = NSMakeRange(0, 0);
        [delegate sequencesView:self slideSitesLeftInRange:temp inSequenceRange:_rangeSelection.y by:_rangeSelection.x.length];
    }
    // Inserting
    else if( _fakeInsertionRange.length != 0 ){
        NSUInteger location = _fakeInsertionRange.location;
        NSUInteger length = _fakeInsertionRange.length;
        _fakeInsertionRange = NSMakeRange(0, 0);
        [delegate sequencesView:self insertGaps:length inSequenceRange:_rangeSelection.y atIndex:location];
    }
    // Deletion
    else if( _fakeDeletionRange.length != 0 ){
        NSRange temp = _fakeDeletionRange;
        _fakeDeletionRange = NSMakeRange(0, 0);
        [delegate sequencesView:self removeSitesInRange:temp inSequenceRange:_rangeSelection.y];
    }
    // An empty block at the end of the alignment is selected and that is not allowed
    else if( [MFSequenceUtils isEmptyBlockAtTheEnd:[[self sequences]subarrayWithRange:_rangeSelection.y ] inRange:_rangeSelection.x ] ){
        _rangeSelection = MFMakeEmpty2DRange();
    }

    draggedRight = NO;
    [self setNeedsDisplay:YES];
}

- (void)mouseExited:(NSEvent *)theEvent {
    self.mouseOverSequence = @"";
}

- (void)mouseMoved:(NSEvent *)theEvent {
    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    
    if( point.x < [[self superview]bounds].origin.x || point.y < [[self superview]bounds].origin.y ) [self mouseExited:nil];
    
    NSInteger indexSequence = (NSInteger)(point.y/(_residueHeight+_rowSpacing));
    NSInteger indexSite     = (NSInteger)(point.x/_residueWidth);
    NSInteger length        = [self numberOfSites];
    
    
    // filter points outside the alignment. Also filter out empty alignments
    if(indexSequence >= 0 && indexSequence < [[self sequences]count] && indexSite >= 0 && indexSite < length ){
        
        if( _mouseOverSequenceIndex != indexSequence || _mouseOverSiteIndex != indexSite ){
            MFSequence *seq = [[self sequences] objectAtIndex:indexSequence];
            NSMutableString *str = [[NSMutableString alloc]init];
            if( [seq.dataType isKindOfClass: [MFNucleotide class]] && seq.translated ){
                [str appendString:[NSString stringWithFormat:@"Amino acid %lu (%c -> %@)",indexSite+1,[seq residueAt:indexSite], [seq subCodonSequenceWithRange:NSMakeRange(indexSite, 1)]]];
            }
            else {
                if( [seq.dataType isKindOfClass: [MFNucleotide class]] ){
                   [str appendString:[NSString stringWithFormat:@"Base"]];
                }
                else {
                   [str appendString:[NSString stringWithFormat:@"Amino acid"]];
                }
                [str appendString:[NSString stringWithFormat:@" %lu (%c)", indexSite+1, [seq residueAt:indexSite]]];
            }
            [str appendString:[NSString stringWithFormat:@" in sequence %ld: %@",indexSequence+1, [seq name]]];

            self.mouseOverSequence = str;
            [str release];
            _mouseOverSequenceIndex = indexSequence;
            _mouseOverSiteIndex = indexSite;
        }
    }
    else {
        self.mouseOverSequence = @"";
    }
}


// http://stackoverflow.com/questions/8979639/mouseexited-isnt-called-when-mouse-leaves-trackingarea-while-scrolling#comment34491426_9107224
- (void) createTrackingArea{
    int opts = (NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved | NSTrackingActiveAlways);
    trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:trackingArea];
    
    NSPoint mouseLocation = [[self window] mouseLocationOutsideOfEventStream];
    mouseLocation = [self convertPoint: mouseLocation
                              fromView: nil];
    
    if (NSPointInRect(mouseLocation, [self bounds]) ){
            [self mouseEntered: nil];
    }
    else{
        [self mouseExited: nil];
    }
}
        
- (void)updateTrackingAreas {
    [self removeTrackingArea:trackingArea];
    [trackingArea release];
    [self createTrackingArea];
    [super updateTrackingAreas];
}

//You should also remove the tracking rectangle when your view is removed from its window, which can happen either because the view is moved to a different window, or because the view is removed as part of deallocation. One place to do this is the viewWillMoveToWindow: method, as shown in Compatibility Issues.



#pragma mark *** Overrides Methods ***

- (BOOL)acceptsFirstResponder {
	return YES;
}

- (BOOL)isFlipped{
    return YES;
}

-(void)resetCursorRects{
    [super resetCursorRects];
    [self addCursorRect:[self bounds] cursor:[NSCursor IBeamCursor] ];
}

#pragma mark *** Keyboard Event Handling ***


// An override of the NSResponder method. NSResponder's implementation would just forward the message to the next responder (an NSClipView, in our case) and our overrides like -delete: would never be invoked.
- (void)keyDown:(NSEvent *)event {
    BOOL ok = NO;
    
    if ( !( [event modifierFlags] & NSCommandKeyMask ) && !( [event modifierFlags] & NSAlternateKeyMask ) && _rangeSelection.y.length == 1 && _rangeSelection.x.length > 0 && !_isTranslated) {
        NSString *str = [[event charactersIgnoringModifiers] uppercaseString];
        ok = [[[[self sequences] objectAtIndex:0]dataType] isValid:str];
    }
    if( ok ){
        NSString *str = [[event charactersIgnoringModifiers] uppercaseString];
        [delegate sequencesView:self replaceResiduesInRange:NSMakeRange(_rangeSelection.x.location, 1) atSequenceIndex:_rangeSelection.y.location withString:str];
        
        _rangeSelection.x.length--;
        _rangeSelection.x.location++;
        if(_rangeSelection.x.length == 0 ){
            _rangeSelection = MFMakeEmpty2DRange();
        }
    }
    else {
        // Ask the key binding manager to interpret the event for us.
        [self interpretKeyEvents:[NSArray arrayWithObject:event]];
    }
    
    
}


#pragma mark *** Bindings ***

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)observedObject change:(NSDictionary *)change context:(void *)context {

    // Use the observation context value to distinguish between them. We can do a simple pointer comparison because KVO doesn't do anything at all with the context value, not even retain or copy it.
    if (context == MFSequenceViewSequencesObservationContext) {
        [self updateFrameSize];
        [self setNeedsDisplay:YES];
    }
    else if (context== MFSequenceViewSelectionIndexesObservationContext) {
        if([self selectedSequences] > 0){
            _rangeSelection = MFMakeEmpty2DRange();
        }
        [self setNeedsDisplay:YES];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:observedObject change:change context:context];
        
    }
    
}

- (void)unbind:(NSString *)bindingName {
    if( [bindingName isEqualToString:MFSequenceViewForegroundColorBindingName] ){
        
    }
    [super unbind:bindingName];
}

-(NSDictionary*)foregroundColor{
    return _foregroundColor;
}

-(void)setForegroundColor:(NSDictionary*)colors{
    if ( _foregroundColor != colors ) {
        [_foregroundColor release];
        _foregroundColor = [colors retain];
        [_attsDict setObject:_foregroundColor forKey:NSForegroundColorAttributeName];
    }
    [self setNeedsDisplay:YES];
}

-(NSDictionary*)backgroundColor{
    return _backgroundColor;
}

-(void)setBackgroundColor:(NSDictionary*)colors{
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

-(void)translationDidChange:(NSNotification *)notification{
    BOOL isTranslated = [[[self sequences]objectAtIndex:0]translated];
    
    // it was amino acid before this change
    if(_isTranslated && !isTranslated ){
        if(_rangeSelection.x.length != 0 ){
            _rangeSelection.x.location *= 3;
            _rangeSelection.x.length   *= 3;
            
            // if the sequence length is not a multiple of 3
            if ( _rangeSelection.x.location + _rangeSelection.x.length > [[[self sequences]objectAtIndex:0]length] ) {
                _rangeSelection.x.length = [[[self sequences]objectAtIndex:0]length] - _rangeSelection.x.location;
            }
        }
    }
    else if(!_isTranslated && isTranslated ){
        if(_rangeSelection.x.length != 0 ){
            //  **
            //ACTGTG
            //M  M
            
            // A bit ugly: round up the number of amino acid, then multiply by 3 to get the number of nuceotides and
            // finaly subtsract the original selection to get what's missing on the right side of the selection
            // The right part is the number of missing nuceotides to get an amino acid at the beginning (left side of selection).
            // If the selection is TG then we also need to select 2 nucleotide at the beginning and at the end
            NSUInteger temp = ((((_rangeSelection.x.location+_rangeSelection.x.length+2)/3)*3) -(_rangeSelection.x.location+_rangeSelection.x.length) ) + (_rangeSelection.x.location %3);
            _rangeSelection.x.location /= 3;
            _rangeSelection.x.length = (_rangeSelection.x.length+temp) / 3;
        }
    }
    _isTranslated = isTranslated;
    [self setNeedsDisplay:YES];
}

#pragma mark *** Private functions ***

-(void)updateFrameSize{
    NSSize oldSize = [self frame ].size;
    NSSize size;
    size.width  = _residueWidth  * [self numberOfSites];
    size.height = (_residueHeight+_rowSpacing) * [[self sequences] count] + _rowSpacing;
    
    if( _fakeInsertionRange.length != 0 && _fakeDeletionRange.length == 0 ){
        size.width  += _residueWidth  * _fakeInsertionRange.length;
        [self setFrameSize:size];
        [self viewDidMoveToWindow];
    }
    if( size.width != oldSize.width || size.height != oldSize.height){
        [self setFrameSize:size];
        [self viewDidMoveToWindow];
    }
}

-(NSUInteger)numberOfSites{
    NSUInteger maxLength = 0;
    for (MFSequence *sequence in [self sequences] ) {
        if( [sequence length] > maxLength ){
            maxLength = [sequence length];
        }
    }
    return maxLength;
}

-(NSArray*)unselectedSequencesInRangeSelection{
    NSMutableArray *unselectedSequences = [[NSMutableArray alloc]init];
    
    for ( NSUInteger i = 0; i < [[self sequences] count]; i++ ) {
        if( i >= _rangeSelection.y.location && i < _rangeSelection.y.location+_rangeSelection.y.length) continue;
        [unselectedSequences addObject:[[self sequences] objectAtIndex:i]];
    }
    return [unselectedSequences autorelease];
}


-(NSUInteger)test:(NSUInteger)nGaps beforeSequenceIndex:(NSUInteger)index inSiteRange:(NSRange)aRange{
    NSRange range = NSMakeRange(index, 0);
    
    for ( NSUInteger i = 0; i < nGaps; i++ ) {
        NSUInteger j = 0;
        for ( ; j < aRange.length; j++ ) {
            MFSequence *sequence = [[self sequences]objectAtIndex: aRange.location+j];
            if( [sequence residueAt:range.location-1] != '-' ){
                break;
                
            }
        }
        if( j == aRange.length ){
            range.location--;
            range.length++;
        }
        else{
            break;
        }
    }
    return range.length;
}

// Convert dragStartSelection and dragPoint to a MF2DRange
-(MF2DRange)convertSelectionPoints{
    MF2DRange range;
    
    NSUInteger numberOfSites     = [[[self sequences] objectAtIndex:0]length];
    NSUInteger numberOfSequences = [[self sequences] count];
    
    // We are dragging to the right
    if(dragStartPoint.x < dragPoint.x ){
        range.x.location = dragStartPoint.x/_residueWidth;
        range.x.length = ceil(dragPoint.x/_residueWidth) - range.x.location;
        
        if ( numberOfSites < range.x.location+range.x.length ) {
            range.x.length = numberOfSites - range.x.location;
        }
    }
    else {
        if(dragPoint.x < 0 ){
            dragPoint.x = 0;
        }
        range.x.location = dragPoint.x/_residueWidth;
        range.x.length = ceil(dragStartPoint.x/_residueWidth) - range.x.location;
    }
    
    // We are dragging down
    if(dragStartPoint.y < dragPoint.y ){
        range.y.location = dragStartPoint.y/(_residueHeight + _rowSpacing);
        range.y.length = ceil(dragPoint.y/(_residueHeight + _rowSpacing)) - range.y.location;
        
        if(  numberOfSequences < range.y.location+range.y.length ){
            range.y.length = numberOfSequences - range.y.location;
        }
    }
    else {
        if(dragPoint.y < 0 ){
            dragPoint.y = 0;
        }
        NSInteger temp = MIN(numberOfSequences, ceil(dragStartPoint.y/(_residueHeight + _rowSpacing)));
        range.y.location = dragPoint.y/(_residueHeight + _rowSpacing);
        range.y.length   = temp - range.y.location;
    }
    return range;
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


/*[NSTimer scheduledTimerWithTimeInterval:caretBlinkRate
                                  target:self
                                selector:@selector(updateCaret:)
                                userInfo:nil
                                 repeats:YES];*/
- (void)updateCaret:(NSTimer*)timer {
    _caretBlinkActive = !_caretBlinkActive; //this sets the blink state
    [self setNeedsDisplayInRect:_caretRect];
}


@end
