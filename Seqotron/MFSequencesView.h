//
//  MFSequencesView.h
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

#import <Cocoa/Cocoa.h>

#include "MFDefines.h"

#import "MFAbstractSequencesView.h"

extern NSString *MFSequenceViewForegroundColorBindingName;
extern NSString *MFSequenceViewBackgroundColorBindingName;

extern NSString *MFTranslationDidChangeNotification;

@interface MFSequencesView : MFAbstractSequencesView{
    @public
    IBOutlet id delegate;
    
    
    @private
    NSPoint dragStartPoint;
    NSPoint dragPoint;
    NSPoint dragEndPoint;
    
    BOOL firstDrag;
    BOOL secondaryDrag;
    BOOL draggedRight;
    BOOL dragging;
    BOOL _pingpong;
    
    NSMutableDictionary *_attsDict;
    NSDictionary *_foregroundColor;
    NSDictionary *_backgroundColor;
    
    BOOL _drawBackground;
    NSColor *_canvasColor;
    
    
    NSMutableIndexSet *_siteSelectionIndexes;
    MF2DRange _rangeSelection;
    NSColor *_marqueeColor;
    CGFloat _marqueeAlpha;
    
    BOOL _isTranslated;
    NSUInteger _maximumNumberOfSites;
    
    NSColor *_unknownBackgroundColor;
    NSMutableAttributedString *_mutableAttributedString;
    
    NSRange _fakeInsertionRange;
    NSRange _fakeDeletionRange;
    
    NSTrackingArea * trackingArea;
    NSString *_mouseOverSequence;
    NSInteger _mouseOverSequenceIndex;
    NSInteger _mouseOverSiteIndex;

    NSRect _caretRect;
    BOOL _caretBlinkActive;
}

@property (readwrite) MF2DRange rangeSelection;
@property (readwrite, copy)NSString *mouseOverSequence;

@property (readwrite, assign) id delegate;  // Don't retain or copy

-(void)updateFrameSize;

-(void)setForegroundColor:(NSDictionary*)colors;

-(NSDictionary*)foregroundColor;

-(void)setBackgroundColor:(NSDictionary*)colors;

-(NSDictionary*)backgroundColor;

@end

@interface NSObject (MFSequencesViewDelegate)

- (void)sequencesView:(MFSequencesView *)inSequenceView insertGaps:(NSUInteger)nGaps inSequenceRange:(NSRange)sequenceRange atIndex:(NSUInteger)index;

- (void)sequencesView:(MFSequencesView *)inSequenceView deleteGaps:(NSRange)gapRange inSequenceRange:(NSRange)sequenceRange;

- (void)sequencesView:(MFSequencesView *)inSequenceView insertSites:(NSArray*)sites atIndex:(NSUInteger)index inSequenceRange:(NSRange)sequenceRange;

- (void)sequencesView:(MFSequencesView *)inSequenceView removeSitesInRange:(NSRange)siteRange inSequenceRange:(NSRange)sequenceRange;

- (void)sequencesView:(MFSequencesView *)inSequenceView insertSites:(NSArray*)sites atIndexes:(NSIndexSet*)indexes inSequenceRange:(NSRange)sequenceRange;

- (void)sequencesView:(MFSequencesView *)inSequenceView removeSitesAtIndexes:(NSIndexSet*)siteIndexes inSequenceRange:(NSRange)sequenceRange;

- (void)sequencesView:(MFSequencesView *)inSequenceView slideSitesLeftInRange:(NSRange)siteRange inSequenceRange:(NSRange)sequenceRange by:(NSUInteger)amount;

- (void)sequencesView:(MFSequencesView *)inSequenceView slideSitesRightInRange:(NSRange)siteRange inSequenceRange:(NSRange)sequenceRange by:(NSUInteger)amount;

- (void)sequencesView:(MFSequencesView *)inSequenceView replaceResiduesInRange:(NSRange)range atSequenceIndex:(NSUInteger)sequenceIndex withString:(NSString*)string;
@end
