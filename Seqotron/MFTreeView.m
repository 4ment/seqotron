//
//  MFTreeView.m
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

#import "MFTreeView.h"

#import "MFGraphic.h"
#import "MFTextGraphic.h"
#import "MFLineGraphic.h"
#import "MFString.h"
#import "NSObject+TDBindings.h"

NSString *MFDepthKey = @"?MFTreeView.depth";

@implementation MFTreeView

@synthesize taxaShown = _taxaShown;


-(id)initWithFrame:(NSRect)frameRect{
    
    if( self = [super initWithFrame:frameRect] ){
        _trees = [[NSMutableArray alloc]init];
        _selectionIndexes = [[NSIndexSet alloc]init];
        _fontName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultTreeFontName"]copy];
        _fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultTreeFontSize"]floatValue];
        _font = [NSFont fontWithName:_fontName size:_fontSize];
        _taxonSpacing = _taxonSpacingDefault = 10;
        _attsDict = [[NSMutableDictionary alloc] init];
        [_attsDict setObject:_font forKey:NSFontAttributeName];
        _attributedString = [[NSMutableAttributedString alloc] initWithString:@"A" attributes:_attsDict];
        _taxonHeight = [_attributedString size].height;// [_font capHeight];
        _backgroundColor = [NSColor whiteColor];
        _taxaShown = YES;
        _scaleBarShown = YES;
        _showXAxis = NO;
        
        _graphicTaxa           = [[NSMutableDictionary alloc]init];
        _graphicBranch         = [[NSMutableDictionary alloc]init];
        _graphicBranchLabel    = [[NSMutableDictionary alloc]init];
        _graphicVerticalBranch = [[NSMutableDictionary alloc]init];
        
        // Horizontal
        _rootOffset = 10.0f;
        _rootLength = _rootOffset/2.0;
        _rightMargin = 2.0f;
        _branchTipSpace = 2.0f;
        _maximumNameLength = 0;
        
        // Vertical
        _bottomSpace = 10; //space between the last taxon and the edge of the view
        
        // Scale bar
        _scaleBarWidth  = 0;
        _scaleBarFontSize = _fontSize;
        NSFont *font = [NSFont fontWithName:_fontName size:_scaleBarFontSize];
        NSMutableDictionary *attsDict = [NSMutableDictionary dictionaryWithObjectsAndKeys:font, NSFontAttributeName, nil];
        _scaleBarValue = [[NSMutableAttributedString alloc] initWithString:@"A" attributes:attsDict];
        _scaleBarFontHeight = [font capHeight];
        _scaleBarSpace = 10;
        
        _observingSuperview = NO;
        
        _selectedNodes = [[NSArray array]retain];
        _branchAttribute = [[NSString alloc]init];
        
        [self createTrackingArea];
    }
    return self;
}


- (void)dealloc{
    NSLog(@"MFTreeView dealloc");
    if (_observingSuperview) {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
    [_trees release];
    [_attsDict release];
    [_graphicTaxa release];
    [_trackingArea release];
    [_scaleBarValue release];
    [_graphicBranch release];
    [_selectedNodes release];
    [_branchAttribute release];
    [_selectionIndexes release];
    [_attributedString release];
    [_graphicBranchLabel release];
    [_graphicVerticalBranch release];
    [super dealloc];
}

+ (void)initialize{
    [self exposeBinding:@"trees"];
    [self exposeBinding:@"selectedNodes"];
}

- (BOOL)isFlipped{
    return YES;
}

- (BOOL)acceptsFirstResponder {
    return YES;
}


-(void)setTrees:(NSMutableArray *)trees{
    [_trees release];
    _trees = [trees retain];
}

-(NSArray*)trees{
    return _trees;
}

-(void)setSelectionIndexes:(NSIndexSet*)indexes{
    [_selectionIndexes release];
    _selectionIndexes = [indexes copy];
    
    if( !_observingSuperview ){
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(superviewResized:)
                                                      name:NSViewFrameDidChangeNotification object:[self superview]];
        _observingSuperview = YES;
    }
    
    // first time
    if( [_graphicBranch count] == 0 ){
        [self setUpSelectedTree];
    }
}

-(NSIndexSet*)selectionIndexes{
    return _selectionIndexes;
}

- (void)setUpSelectedTree{
    MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
    
    [self updateFrameSize:theTree];
    [self calculateBranchScaler:theTree];
    
    if( _scaleBarShown ){
        [self updateScaleBar];
    }
    [self createGraphicsForTree:theTree];
    [self updateGraphicsForTree:theTree];
    
    [self setNeedsDisplay:YES];
}

-(void)updateScaleBar{
    _scaleBarWidth = self.frame.size.width/10.0;
    CGFloat w = _scaleBarWidth/_treeScaler;
    NSString *value;
    if ( w < 1e-3) {
        value = [NSString stringWithFormat:@"%.2e",w];
    }
    else {
        value = [NSString stringWithFormat:@"%.4f",w];
    }
    [[_scaleBarValue mutableString] setString:value];
}


-(void)calculateBranchScaler:(MFTree*)tree{
    _treeScaler = CGFLOAT_MAX;
    _maximumDepth = 0;
    _maximumNameLength = 0;
    
    NSRect bounds = [self frame];
    CGFloat width = bounds.size.width - _rightMargin - _rootOffset;
    
    
    if( _taxaShown ){
        width -= _branchTipSpace;
        
        [tree enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPreorder usingBlock:^(MFNode *node){
            if( [node isRoot] ){
                [node setAttribute:[NSNumber numberWithFloat:0] forKey:MFDepthKey];
            }
            else {
                CGFloat depth = [[[node parent] attributeForKey:MFDepthKey]floatValue] + [node branchLength];
                [node setAttribute:[NSNumber numberWithFloat:depth] forKey:MFDepthKey];
                
                if( [node isLeaf] ){
                    NSMutableString *mutString = [_attributedString mutableString];
                    [mutString setString:node.name];
                    
                    CGFloat s = (width - [_attributedString size].width)/depth;
                    if(s < _treeScaler){
                        _treeScaler = s;
                    }
                    
                    if( [_attributedString size].width  > _maximumNameLength ){
                        _maximumNameLength = [_attributedString size].width;
                    }
                }
            }
        }];
    }
    else {
        [tree enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPreorder usingBlock:^(MFNode *node){
            if( [node isRoot] ){
                [node setAttribute:[NSNumber numberWithFloat:0] forKey:MFDepthKey];
            }
            else {
                CGFloat depth = [[[node parent] attributeForKey:MFDepthKey]floatValue] + [node branchLength];
                [node setAttribute:[NSNumber numberWithFloat:depth] forKey:MFDepthKey];
                
                if( [node isLeaf] ){
                    if( depth > _maximumDepth ){
                        _maximumDepth = depth;
                    }
                }
                
            }
        }];
        _treeScaler = width/_maximumDepth;
    }
}

-(void)createGraphicsForTree:(MFTree*)tree{

    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:_font,NSFontAttributeName, nil];
    
    [tree enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPostorder usingBlock:^(MFNode *node){
        
        
        if( [node isLeaf] ){
            // Taxon text
            MFTextGraphic *textGraphic = [[MFTextGraphic alloc]initWithString:[node name] attributes:attrs];
            [_graphicTaxa setObject:textGraphic forKey:[NSValue valueWithNonretainedObject:node]];
            [textGraphic release];
            
            // Taxon branch
            MFLineGraphic *horizontal = [[MFLineGraphic alloc]init];
            [_graphicBranch setObject:horizontal forKey:[NSValue valueWithNonretainedObject:node]];
            [horizontal release];
        }
        else {
            // Node branch
            MFLineGraphic *horizontal = [[MFLineGraphic alloc]init];
            [_graphicBranch setObject:horizontal forKey:[NSValue valueWithNonretainedObject:node]];
            [horizontal release];
            
            // Vertical branch
            MFLineGraphic *vertical = [[MFLineGraphic alloc]init];
            [_graphicVerticalBranch setObject:vertical forKey:[NSValue valueWithNonretainedObject:node]];
            [vertical release];
        }
        
        // Always init with a non-empty string otherwise the initial font is ignored when we
        // set another string in nstextstorage
        MFTextGraphic *horizontalLabel = [[MFTextGraphic alloc]initWithString:@" " attributes:attrs];
        [_graphicBranchLabel setObject:horizontalLabel forKey:[NSValue valueWithNonretainedObject:node]];
        [horizontalLabel release];
    }];
}


- (void)updateBranchAttributes{
    if ( ![_branchAttribute isEqualToString:@""] ) {
        MFTree *tree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
        [tree enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPostorder usingBlock:^(MFNode *node){
            
            
            if( [_branchAttribute isEqualToString:@"Branch Length"] ){
                // Node branch
                MFLineGraphic *horizontal = [_graphicBranch objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                MFTextGraphic *textGraphic = [_graphicBranchLabel objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                NSString *value = [NSString stringWithFormat:@"%f", [node branchLength] ];
                [textGraphic setXPosition:horizontal.xPosition];
                [textGraphic setYPosition:horizontal.yPosition];
                [[textGraphic contents]beginEditing];
                [[textGraphic contents]replaceCharactersInRange:NSMakeRange(0, [[textGraphic contents ]length]) withString:value];
                [[textGraphic contents]endEditing];
                
            }
            else if( [_branchAttribute isEqualToString:@"Name"] ){
                // Node branch
                MFLineGraphic *horizontal = [_graphicBranch objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                MFTextGraphic *textGraphic = [_graphicBranchLabel objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                NSString *value = node.name;
                [textGraphic setXPosition:horizontal.xPosition];
                [textGraphic setYPosition:horizontal.yPosition];
                [[textGraphic contents]beginEditing];
                [[textGraphic contents]replaceCharactersInRange:NSMakeRange(0, [[textGraphic contents ]length]) withString:value];
                [[textGraphic contents]endEditing];
                
            }
            else if ( [[node attributes]objectForKey:_branchAttribute]) {
                // Node branch
                MFLineGraphic *horizontal = [_graphicBranch objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                MFTextGraphic *textGraphic = [_graphicBranchLabel objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                NSString *value = [[node attributes]objectForKey:_branchAttribute];
                [textGraphic setXPosition:horizontal.xPosition];
                [textGraphic setYPosition:horizontal.yPosition];
                [[textGraphic contents]beginEditing];
                [[textGraphic contents]replaceCharactersInRange:NSMakeRange(0, [[textGraphic contents ]length]) withString:value];
                [[textGraphic contents]endEditing];
            }
            else {
                MFTextGraphic *textGraphic = [_graphicBranchLabel objectForKey:[NSValue valueWithNonretainedObject:node]];
                [[textGraphic contents]beginEditing];
                [[textGraphic contents]replaceCharactersInRange:NSMakeRange(0, [[textGraphic contents ]length]) withString:@" "];
                [[textGraphic contents]endEditing];
            }
        }];
    }
}
// We don't need to update the other graphic objects when we use this method
- (void)showBranchAttribute:(NSString*)attribute{
    if ( ![attribute isEqualToString:_branchAttribute] ) {
        [_branchAttribute release];
        _branchAttribute = [attribute retain];
        
        [self updateBranchAttributes];
        
        [self setNeedsDisplay:YES];
    }
}

- (void)updateGraphicsForTree:(MFTree*)tree{
    
    CGFloat yspace = _taxonSpacing;
    
    __block CGFloat y = _taxonHeight;
    [tree enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPostorder usingBlock:^(MFNode *node){
        
        CGFloat distanceFromRoot = [[node attributeForKey:MFDepthKey] floatValue];
        
        if( [node isLeaf] ){
            CGFloat x1 = distanceFromRoot * _treeScaler + _rootOffset;
            CGFloat x2 = x1-[node branchLength]*_treeScaler;
            
            if( _taxaShown ){
                // Taxon text
                MFTextGraphic *textGraphic = [_graphicTaxa objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                [textGraphic setXPosition:x1];
                [textGraphic setYPosition:y-_taxonHeight];
            }
            
            // Taxon branch
            MFLineGraphic *horizontal = [_graphicBranch objectForKey:[NSValue valueWithNonretainedObject:node]];
            CGFloat y2 = y-_taxonHeight/2;
            [horizontal setBeginPoint:NSMakePoint(x1, y2)];
            [horizontal setEndPoint:NSMakePoint(x2, y2)];
            
            // Branch attribute
            if( ![_branchAttribute isEqualToString:@""] ){
                MFTextGraphic *textGraphic = [_graphicBranchLabel objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                [textGraphic setXPosition:x2];
                [textGraphic setYPosition:y2];
            }
            
            y += yspace + _taxonHeight;
            
        }
        else {
            // Node branch
            MFLineGraphic *horizontal = [_graphicBranch objectForKey:[NSValue valueWithNonretainedObject:node]];
            MFLineGraphic *son1 = [_graphicBranch objectForKey:[NSValue valueWithNonretainedObject:[node childAtIndex:0]]];
            MFLineGraphic *son2 = [_graphicBranch objectForKey:[NSValue valueWithNonretainedObject:[node childAtIndex:1]]];
            CGFloat yson1 = [son1 endPoint].y;
            CGFloat yson2 = [son2 endPoint].y;
            CGFloat y = yson1+(yson2-yson1)/2.0;
            
            CGFloat x1 = distanceFromRoot *_treeScaler + _rootOffset;
            CGFloat x2 = x1-[node branchLength]*_treeScaler;
            
            
            if ( [node isRoot] ) {
                x2 = x1-_rootLength;
            }
            
            [horizontal setBeginPoint:NSMakePoint(x1, y)];
            [horizontal setEndPoint:NSMakePoint(x2, y)];

            // Branch attribute
            if( ![_branchAttribute isEqualToString:@""] ){
                MFTextGraphic *textGraphic = [_graphicBranchLabel objectForKey:[NSValue valueWithNonretainedObject:node]];
                
                [textGraphic setXPosition:x2];
                [textGraphic setYPosition:y];
            }
            
            // Vertical branch
            MFLineGraphic *vertical = [_graphicVerticalBranch objectForKey:[NSValue valueWithNonretainedObject:node]];//[[MFBranchGraphic alloc]init];
            [vertical setBeginPoint:NSMakePoint(x1, yson1)];
            [vertical setEndPoint:NSMakePoint(x1, yson2)];
        }
    }];
}


- (void)reloadData{
    
    MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
    [self updateFrameSize:theTree];
    [self calculateBranchScaler:theTree];
    
    if( _scaleBarShown ){
        [self updateScaleBar];
    }
    [self updateBranchAttributes];
    [self updateGraphicsForTree:theTree];
    
    [self setNeedsDisplay:YES];
}

#pragma mark *** Drawing ***

- (void)drawRect:(NSRect)dirtyRect{
    
    // Draw background
    [_backgroundColor set];
    NSRectFill(dirtyRect);
    
    if([_trees count] == 0 )return;
    
    if( _showXAxis ){
        
    }
    
    if( _scaleBarShown ){
        CGFloat x = self.frame.size.width * 0.3;
        MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
        CGFloat y = (_taxonSpacing + _taxonHeight) * [theTree taxonCount];
        
        NSPoint p = NSMakePoint(x, y);
        if ( NSPointInRect(p, dirtyRect)) {
            [_scaleBarValue drawAtPoint:p];
            
            y += _scaleBarSpace + _scaleBarFontHeight;
            NSBezierPath *path = [NSBezierPath bezierPath];
            [path moveToPoint: NSMakePoint(x, y)];
            [path lineToPoint:NSMakePoint(x+_scaleBarWidth, y)];
            [path stroke];
        }
    }
    
    // Draw taxa
    if( _taxaShown ){

        for (NSValue *vnode  in [_graphicTaxa allKeys]) {
            MFTextGraphic *graphic = [_graphicTaxa objectForKey:vnode];
            MFNode *node = [vnode nonretainedObjectValue];
            
            NSRect graphicDrawingBounds = [graphic drawingBounds];
            NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
            
            if (NSIntersectsRect(dirtyRect, graphicDrawingBounds)) {
                
                [currentContext saveGraphicsState];
                BOOL isSelected = _selectionMode == 0 && [_selectedNodes indexOfObject:node] != NSNotFound;
    
                [graphic drawContentsInView:self isSelected:isSelected];
                
                [currentContext restoreGraphicsState];
            }
        }
    }
    
    // Draw branches
    for (NSValue *vnode  in [_graphicBranch allKeys]) {
        MFGraphic *graphic = [_graphicBranch objectForKey:vnode];
        MFNode *node = [vnode nonretainedObjectValue];
        
        NSRect graphicDrawingBounds = [graphic drawingBounds];
        NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
        
        if (NSIntersectsRect(dirtyRect, graphicDrawingBounds)) {
            
            [currentContext saveGraphicsState];
            
            [NSBezierPath clipRect:graphicDrawingBounds];
            
            BOOL isSelected = _selectionMode != 0 && [_selectedNodes indexOfObject:node] != NSNotFound;
            [graphic drawContentsInView:self isSelected:isSelected];
            
            [currentContext restoreGraphicsState];
        }
    }
    
    // Draw vertical branches
    for (MFGraphic *graphic  in [_graphicVerticalBranch allValues]) {
        NSRect graphicDrawingBounds = [graphic drawingBounds];
        NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
        
        if (NSIntersectsRect(dirtyRect, graphicDrawingBounds)) {
            
            [currentContext saveGraphicsState];
            [NSBezierPath clipRect:graphicDrawingBounds];
            [graphic drawContentsInView:self isSelected:NO];
            
            [currentContext restoreGraphicsState];
        }
    }
    
    // Draw branch attribute
    if ( ![_branchAttribute isEqualToString:@""]) {
        for (MFTextGraphic *graphic  in [_graphicBranchLabel allValues]) {
            if( [[[graphic contents] string] isEmpty] ) continue;
            
            NSRect graphicDrawingBounds = [graphic drawingBounds];
            NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
            
            if (NSIntersectsRect(dirtyRect, graphicDrawingBounds)) {
                
                [currentContext saveGraphicsState];
                [NSBezierPath clipRect:graphicDrawingBounds];
                [graphic drawContentsInView:self isSelected:NO];
                
                [currentContext restoreGraphicsState];
            }
        }
    }
    
    // If the user is in the middle of selecting draw the selection rectangle.
    if (!NSEqualRects(_marqueeSelectionBounds, NSZeroRect)) {
        [[NSColor knobColor] set];
        NSFrameRect(_marqueeSelectionBounds);
    }
    
}

#pragma mark *** Resizing Methods ****

- (void)superviewResized:(NSNotification *)notification{
    if( [_selectionIndexes count] > 0 ){
        NSSize treeviewSize = self.frame.size;
        MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
        [self updateFrameSize:theTree];
        
        if (treeviewSize.width != self.frame.size.width) {
            [self calculateBranchScaler:theTree];
            if(_scaleBarShown){
                [self updateScaleBar];
            }
        }
        [self updateGraphicsForTree:theTree];
        
        [self setNeedsDisplay:YES];
    }
}

- (void)updateFrameSize:(MFTree*)theTree{
    NSSize superviewSize = [[self superview]frame].size;
    NSSize treeViewSize = [[self superview]frame].size;
    
    CGFloat proposedHeight = _taxonSpacing*([theTree taxonCount]-1) + _taxonHeight*[theTree taxonCount] + _bottomSpace;
    if( _scaleBarShown ){
        proposedHeight += _scaleBarFontHeight + _taxonSpacing + _scaleBarSpace;
    }
    
    if( superviewSize.height > proposedHeight ){
        if( _scaleBarShown ){
            _taxonSpacing = (superviewSize.height -  [theTree taxonCount]*_taxonHeight-_scaleBarFontHeight-_scaleBarSpace-_bottomSpace)/[theTree taxonCount];
        }
        else {
            _taxonSpacing = (superviewSize.height -  [theTree taxonCount]*_taxonHeight-_bottomSpace)/ ([theTree taxonCount]-1);
        }
    }
    else {
        treeViewSize.height = proposedHeight;
    }
    
    // Width
    CGFloat width = _maximumNameLength + _rootOffset + _rightMargin + _branchTipSpace + 10;
    if( width >= superviewSize.width ){
        treeViewSize.width = width;
    }
    else if( treeViewSize.width < superviewSize.width ){
        treeViewSize.width = superviewSize.width;
    }
    
    if( !NSEqualSizes([self frame].size, treeViewSize) ){
        [self setFrameSize:treeViewSize];
    }
}

// inc can be negative too
-(void)incrementTaxonSpacing:(CGFloat)inc{
    
    MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
    NSSize superviewSize = [[self superview]frame].size;
    
    CGFloat proposedHeight = (_taxonSpacing+inc)*([theTree taxonCount]-1) + _taxonHeight*[theTree taxonCount] + _bottomSpace;
    if( _scaleBarShown ){
        proposedHeight += _scaleBarFontHeight + _taxonSpacing + inc + _scaleBarSpace;
    }
    
    // The proposed increment creates a TreeView bigger than its superview so we accept this change
    if( superviewSize.height < proposedHeight ){
        _taxonSpacing += inc;
        NSSize size = self.frame.size;
        size.height = proposedHeight;
        [self setFrameSize:size];
        
        [self updateGraphicsForTree:theTree];
        [self setNeedsDisplay:YES];
    }
    // The proposed increment would create a TreeView smaller than its superview and we don't want this
    else {
        CGFloat taxonSpacing;
        if( _scaleBarShown ){
            taxonSpacing = (superviewSize.height -  [theTree taxonCount]*_taxonHeight-_scaleBarFontHeight-_scaleBarSpace-_bottomSpace)/[theTree taxonCount];
        }
        else {
            taxonSpacing = (superviewSize.height -  [theTree taxonCount]*_taxonHeight-_bottomSpace)/ ([theTree taxonCount]-1);
        }
        if( taxonSpacing != _taxonSpacing ){
            _taxonSpacing = taxonSpacing;
            [self setFrameSize:superviewSize];
            
            [self updateGraphicsForTree:theTree];
            [self setNeedsDisplay:YES];
        }
    }
}

- (void)incrementWidth:(CGFloat)inc{
    MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
    NSSize superviewSize = [[self superview]frame].size;
    NSSize treeviewSize  = self.frame.size;
    
    if ( treeviewSize.width+inc > superviewSize.width) {
        treeviewSize.width += inc;
    }
    else if( treeviewSize.width != superviewSize.width ){
        treeviewSize.width = superviewSize.width;
    }
    
    if ( [self frame].size.width != treeviewSize.width ) {
        [self setFrameSize:treeviewSize];
        [self calculateBranchScaler:theTree];
        
        if( _scaleBarShown ){
            [self updateScaleBar];
        }
        [self updateGraphicsForTree:theTree];
        [self setNeedsDisplay:YES];
    }
}

- (void)setDefaultSize{
    MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
    NSSize superviewSize = [[self superview]frame].size;
    NSSize treeviewSize  = [self frame].size;
    
    // Height
    CGFloat proposedHeight = _taxonSpacingDefault*([theTree taxonCount]-1) + _taxonHeight*[theTree taxonCount] + _bottomSpace;
    if( _scaleBarShown ){
        proposedHeight += _scaleBarFontHeight + _taxonSpacingDefault + _scaleBarSpace;
    }
    
    if( superviewSize.height < proposedHeight ){
        _taxonSpacing = _taxonSpacingDefault;
        treeviewSize.height = proposedHeight;
    }
    else {
        if( _scaleBarShown ){
            _taxonSpacing = (superviewSize.height -  [theTree taxonCount]*_taxonHeight-_scaleBarFontHeight-_scaleBarSpace-_bottomSpace)/[theTree taxonCount];
        }
        else {
            _taxonSpacing = (superviewSize.height -  [theTree taxonCount]*_taxonHeight-_bottomSpace)/ ([theTree taxonCount]-1);
        }
        treeviewSize.height = superviewSize.height;
    }
    
    // Width
    CGFloat width = _maximumNameLength + _rootOffset + _rightMargin + _branchTipSpace + 10;
    if( width >= superviewSize.width ){
        treeviewSize.width = width;
    }
    else {
        treeviewSize.width = superviewSize.width;
    }
    
    if ( !NSEqualSizes([self frame].size, treeviewSize) ) {
        [self setFrameSize:treeviewSize];
        [self calculateBranchScaler:theTree];
        
        if( _scaleBarShown ){
            [self updateScaleBar];
        }
        [self updateGraphicsForTree:theTree];
        [self setNeedsDisplay:YES];
    }
}

- (void)setSelectedNodes:(NSArray*)nodes{

    if( nodes != _selectedNodes ){
        [_selectedNodes release];
        _selectedNodes = [nodes retain];
        [self setNeedsDisplay:YES];
    }
}

- (NSArray*)selectedNodes{
    return _selectedNodes;
}

- (void)setSelectionMode:(NSInteger)mode{
    if ( mode != _selectionMode) {
        _selectionMode = mode;
        [self setNeedsDisplay:YES];
    }
}

-(NSInteger)selectionMode{
    return _selectionMode;
}

-(BOOL)taxaShown{
    return _taxaShown;
}

-(void)setTaxaShown:(BOOL)isTaxaShown{
    if( isTaxaShown != _taxaShown){
        _taxaShown = isTaxaShown;
        MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
        [self calculateBranchScaler:theTree];
        if(_scaleBarShown){
            [self updateScaleBar];
        }
        [self updateGraphicsForTree:theTree];
        [self setNeedsDisplay:YES];
    }
}

-(BOOL)scaleBarShown{
    return _scaleBarShown;
}

-(void)setScalBarShown:(BOOL)isScaleBarShown{
    if( _scaleBarShown != isScaleBarShown){
        _scaleBarShown = isScaleBarShown;
        MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
        [self calculateBranchScaler:theTree];
        if(_scaleBarShown){
            [self updateScaleBar];
        }
        [self updateGraphicsForTree:theTree];
        [self setNeedsDisplay:YES];
    }
}


- (NSArray *)nodesOfGraphics:(NSDictionary*)graphics intersectingRect:(NSRect)rect {
    NSMutableArray *nodeArrayToReturn = [NSMutableArray array];
    for ( NSValue *vnode in [graphics allKeys] ) {
        MFGraphic *graphic = [graphics objectForKey:vnode];
        if (NSIntersectsRect(rect, [graphic drawingBounds])) {
            [nodeArrayToReturn addObject:[vnode nonretainedObjectValue]];
        }
    }
    return nodeArrayToReturn;
}

- (NSArray *)nodesOfGraphics:(NSDictionary*)graphics atPoint:(NSPoint)point {
    NSMutableArray *nodeArrayToReturn = [NSMutableArray array];
    for ( NSValue *vnode in [graphics allKeys] ) {
        MFGraphic *graphic = [graphics objectForKey:vnode];
        if (NSPointInRect(point, [graphic drawingBounds])) {
            [nodeArrayToReturn addObject:[vnode nonretainedObjectValue]];
        }
    }
    return nodeArrayToReturn;
}

- (BOOL)setColorForSelected:(NSColor*)color{
    BOOL done = NO;
    
    if ( [_selectedNodes count] > 0 ) {
        if ( _selectionMode == 0 ) {
            for (NSValue *vnode in [_graphicTaxa allKeys]) {
                MFNode *node = [vnode nonretainedObjectValue];
                
                if ( [_selectedNodes indexOfObject:node] != NSNotFound ) {
                    MFGraphic *graphic = [_graphicTaxa objectForKey:vnode];
                    [graphic setColor:color];
                }
            }
            //[[_graphicTaxa allValues] makeObjectsPerformSelector:@selector(setColor:)withObject:color];
        }
        else{
            for (NSValue *vnode in [_graphicBranch allKeys]) {
                MFNode *node = [vnode nonretainedObjectValue];
                if ( [_selectedNodes indexOfObject:node] != NSNotFound ) {
                    MFGraphic *graphic = [_graphicBranch objectForKey:vnode];
                    [graphic setColor:color];
                }
            }
        }
        [self setNeedsDisplay:YES];
    }
    return done;
}

- (void)setFontSize:(CGFloat)fontSize{
    _fontSize = fontSize;
    
    _font = [NSFont fontWithName:_fontName size:_fontSize];
    [_attsDict setObject:_font forKey:NSFontAttributeName];
    [_attributedString setAttributes:_attsDict range:NSMakeRange(0, [_attributedString length])];
    
    MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
    
    [self updateFrameSize:theTree];
    [self calculateBranchScaler:theTree];
    
    if( _scaleBarShown ){
        [self updateScaleBar];
    }
    
    for (NSValue *vnode in [_graphicTaxa allKeys]) {
        MFTextGraphic *graphic = [_graphicTaxa objectForKey:vnode];
        [[graphic contents]setFont:_font];
    }
    [self updateGraphicsForTree:theTree];
    [self setNeedsDisplay:YES];
}

#pragma mark *** Tree Manipulation ***

- (void)rotateSelectedBranch{
    if( [_selectedNodes count] == 1 && _selectionMode > 0 ){
        MFNode *node = [_selectedNodes objectAtIndex:0];
        [node rotate];
        MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
        [self updateBranchAttributes];
        [self updateGraphicsForTree:theTree];
        
        [self setNeedsDisplay:YES];
    }
}

- (void)rootAtSelectedBranch{
    if( [_selectedNodes count] == 1 && _selectionMode > 0 ){
        MFTree *theTree = [_trees objectAtIndex:[_selectionIndexes firstIndex]];
        [theTree setRootAtNode:[_selectedNodes objectAtIndex:0]];
        [self updateFrameSize:theTree];
        [self calculateBranchScaler:theTree];
        
        if( _scaleBarShown ){
            [self updateScaleBar];
        }
        [self updateBranchAttributes];
        [self updateGraphicsForTree:theTree];
        [self setNeedsDisplay:YES];
    }
}


#pragma mark *** Mouse Event Handling ***

- (void)mouseDown:(NSEvent *)event {
    
    if( [_trees count] == 0 ) return;
    
    NSPoint originalMouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
    while ( [event type] != NSLeftMouseUp ) {
        event = [[self window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask)];
        [self autoscroll:event];
        NSPoint currentMouseLocation = [self convertPoint:[event locationInWindow] fromView:nil];
        
        // Figure out a new a selection rectangle based on the mouse location.
        NSRect newMarqueeSelectionBounds = NSMakeRect(fmin(originalMouseLocation.x, currentMouseLocation.x), fmin(originalMouseLocation.y, currentMouseLocation.y), fabs(currentMouseLocation.x - originalMouseLocation.x), fabs(currentMouseLocation.y - originalMouseLocation.y));

        if( NSEqualPoints(originalMouseLocation, currentMouseLocation) ){
            NSArray *nodes;
            if( _selectionMode == 0 ){
                nodes = [self nodesOfGraphics: _graphicTaxa atPoint:currentMouseLocation];
            }
            else{
                nodes = [self nodesOfGraphics: _graphicBranch atPoint:currentMouseLocation];
            }
            NSMutableArray *mut = [NSMutableArray array];
            if( [nodes count] > 0 ){
                if ( [_selectedNodes count] > 0 && [event modifierFlags] & NSCommandKeyMask ) {
                    [mut addObjectsFromArray:_selectedNodes];
                    for (NSObject *node in nodes) {
                        if ( [_selectedNodes indexOfObject:node] == NSNotFound ) {
                            [mut addObject:node];
                        }
                        else {
                            [mut removeObject:node];
                        }
                    }
                }
                else if ( [_selectedNodes count] > 0 ) {

                    for (MFNode *node in nodes) {
                        if ( [_selectedNodes indexOfObject:node] == NSNotFound ) {
                            [mut addObject:node];
                        }
                    }
                }
                else{
                    [mut addObjectsFromArray:nodes];
                }
            }
            [self setSelectedNodes:mut];
            [self propagateValue:mut forBinding:@"selectedNodes"];
        }
        else if (!NSEqualRects(newMarqueeSelectionBounds, _marqueeSelectionBounds)) {
            
            // Erase the old selection rectangle and draw the new one.
            [self setNeedsDisplayInRect:_marqueeSelectionBounds];
            _marqueeSelectionBounds = newMarqueeSelectionBounds;
            [self setNeedsDisplayInRect:_marqueeSelectionBounds];
            
            NSArray *nodesOfGraphicsInRubberBand;
            
            if( _selectionMode == 0 ){
                nodesOfGraphicsInRubberBand = [self nodesOfGraphics:_graphicTaxa intersectingRect:_marqueeSelectionBounds];
            }
            else {
                nodesOfGraphicsInRubberBand = [self nodesOfGraphics:_graphicBranch intersectingRect:_marqueeSelectionBounds];
            }
            [self setSelectedNodes:nodesOfGraphicsInRubberBand];
            [self propagateValue:nodesOfGraphicsInRubberBand forBinding:@"selectedNodes"];
        }
    }
    
    // Schedule the drawing of the place wherew the rubber band isn't anymore.
    if( !NSIsEmptyRect(_marqueeSelectionBounds) ){
        [self setNeedsDisplayInRect:_marqueeSelectionBounds];
        // Make it not there.
        _marqueeSelectionBounds = NSZeroRect;
    }
}

- (void)mouseMoved:(NSEvent *)theEvent {
//    NSLog(@"mouse moved");
//    NSPoint point = [self convertPoint:[theEvent locationInWindow] fromView:nil];
//    
//    for ( NSValue *vnode in [_graphicTaxa allKeys] ) {
//        MFGraphic *graphic = [_graphicTaxa objectForKey:vnode];
//        MFNode *node = [vnode nonretainedObjectValue];
//        if (NSPointInRect(point, [graphic drawingBounds])) {
//            NSLog(@"TAXA %@",node);
//        }
//    }
//    
//    for ( NSValue *vnode in [_graphicBranch allKeys] ) {
//        MFGraphic *graphic = [_graphicBranch objectForKey:vnode];
//        MFNode *node = [vnode nonretainedObjectValue];
//        if (NSPointInRect(point, [graphic drawingBounds])) {
//            NSLog(@"BRANCH %@",node);
//        }
//    }
//    
//    for ( NSValue *vnode in [_graphicVerticalBranch allKeys] ) {
//        MFGraphic *graphic = [_graphicVerticalBranch objectForKey:vnode];
//        MFNode *node = [vnode nonretainedObjectValue];
//        if (NSPointInRect(point, [graphic drawingBounds])) {
//            NSLog(@"BRANCH V %@",node);
//        }
//    }
}

// http://stackoverflow.com/questions/8979639/mouseexited-isnt-called-when-mouse-leaves-trackingarea-while-scrolling#comment34491426_9107224
- (void) createTrackingArea{
    int opts = (NSTrackingMouseEnteredAndExited|NSTrackingMouseMoved | NSTrackingActiveAlways);
    _trackingArea = [ [NSTrackingArea alloc] initWithRect:[self bounds]
                                                 options:opts
                                                   owner:self
                                                userInfo:nil];
    [self addTrackingArea:_trackingArea];
    
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
    [self removeTrackingArea:_trackingArea];
    [_trackingArea release];
    [self createTrackingArea];
    [super updateTrackingAreas];
}

@end
