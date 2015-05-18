//
//  MFTreeView.h
//  Seqotron
//
//  Created by Mathieu Fourment on 11/11/2014.
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

#import "MFTree.h"

@interface MFTreeView : NSView{
    NSMutableArray *_trees;
    
    NSIndexSet *_selectionIndexes;
    
    NSColor *_backgroundColor;
    
    CGFloat _rootOffset;// offset on the left (i.e. where the root starts)
    CGFloat _rightMargin;
    CGFloat _branchTipSpace; // space between a taxon and its branch
    CGFloat _rootLength;
    
    // scale bar
    CGFloat _scaleBarWidth; // width of the bar (line) in pixels
    CGFloat _scaleBarSpace; // space between text and bar in pixels
    CGFloat _scaleBarFontSize; // font size
    CGFloat _scaleBarFontHeight; // height of the text alone
    NSMutableAttributedString *_scaleBarValue; // text of the scale bar (e.g 0.01)
    
    NSPoint _dragStartPoint;
    NSPoint _dragPoint;
    
    CGFloat _treeScaler;
    CGFloat _maximumDepth;
    BOOL _taxaShown;
    
    NSFont *_font;
    NSString *_fontName;
    CGFloat _fontSize;
    CGFloat _lineGap;
    CGFloat _taxonHeight;
    CGFloat _taxonSpacing; // spacing between taxa
    CGFloat _taxonSpacingDefault;
    
    NSMutableDictionary *_attsDict;
    NSMutableAttributedString *_attributedString;
    
    BOOL _showXAxis;
    BOOL _scaleBarShown;
    
    NSMutableDictionary *_graphicTaxa;
    NSMutableDictionary *_graphicBranch;
    NSMutableDictionary *_graphicBranchLabel;
    NSMutableDictionary *_graphicVerticalBranch;
    
    CGFloat _maximumNameLength;
    
    CGFloat _bottomSpace;
    
    BOOL _observingSuperview;
    
    NSInteger _selectionMode;
    NSArray *_selectedNodes;
    NSRect _marqueeSelectionBounds;
    
    NSString *_branchAttribute;
    NSTrackingArea *_trackingArea;
}

@property (readwrite)BOOL taxaShown;

//@property (readwrite, retain)NSMutableArray *trees;

- (void)setTrees:(NSMutableArray *)trees;
- (NSArray*)trees;

- (void)setSelectionIndexes:(NSIndexSet*)indexes;
- (NSIndexSet*)selectionIndexes;

- (void)setSelectedNodes:(NSArray*)nodes;
- (NSArray*)selectedNodes;

- (void)incrementTaxonSpacing:(CGFloat)inc;

- (void)incrementWidth:(CGFloat)inc;

- (void)setDefaultSize;

- (void)showBranchAttribute:(NSString*)attribute;

- (BOOL)setColorForSelected:(NSColor*)color;

- (void)rotateSelectedBranch;

- (void)rootAtSelectedBranch;

- (void)setFontSize:(CGFloat)fontSize;

- (void)reloadData;

/*- (MFTree*)objectInTreesAtIndex:(NSUInteger)index;
-(NSArray*)treesAtIndexes:(NSIndexSet*)indexes;
- (NSUInteger)countOfTrees;
- (void)insertObject:(MFTree *)tree inTreesAtIndex:(NSUInteger)index;
- (void)insertTrees:(NSArray*)trees atIndexes:(NSIndexSet*)indexes;
- (void)removeObjectFromTreesAtIndex:(NSUInteger)index;
- (void)removeTreesAtIndexes:(NSIndexSet*)indexes;
- (NSIndexSet*)selectionIndexes;
- (void)setSelectionIndexes:(NSIndexSet*)indexes;*/


@end
