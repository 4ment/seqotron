//
//  MFGraphic.m
//  Seqotron
//
//  Created by Mathieu on 5/12/2014.
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

#import "MFGraphic.h"


static CGFloat MFGraphicHandleWidth = 6.0f;
static CGFloat MFGraphicHandleHalfWidth = 6.0f / 2.0f;

@implementation MFGraphic

- (id)init {
    if ( self = [super init] ) {
        _bounds = NSZeroRect;
        _strokeColor = [[NSColor blackColor] retain];
        _strokeWidth = 0.5f;
        _isDrawingStroke = YES;
        _isDrawingFill = NO;
        _fillColor = [[NSColor whiteColor] retain];
        
    }
    return self;
    
}

-(void)dealloc{
    [_strokeColor release];
    [_fillColor release];
    [super dealloc];
}

- (NSRect)bounds {
    return _bounds;
}

- (void)setBounds:(NSRect)bounds {
    _bounds = bounds;
    
}

- (CGFloat)xPosition {
    return [self bounds].origin.x;
}
- (CGFloat)yPosition {
    return [self bounds].origin.y;
}
- (CGFloat)width {
    return [self bounds].size.width;
}
- (CGFloat)height {
    return [self bounds].size.height;
}
- (void)setXPosition:(CGFloat)xPosition {
    NSRect bounds = [self bounds];
    bounds.origin.x = xPosition;
    [self setBounds:bounds];
}
- (void)setYPosition:(CGFloat)yPosition {
    NSRect bounds = [self bounds];
    bounds.origin.y = yPosition;
    [self setBounds:bounds];
}
- (void)setWidth:(CGFloat)width {
    NSRect bounds = [self bounds];
    bounds.size.width = width;
    [self setBounds:bounds];
}
- (void)setHeight:(CGFloat)height {
    NSRect bounds = [self bounds];
    bounds.size.height = height;
    [self setBounds:bounds];
}

- (BOOL)isDrawingStroke {
    return _isDrawingStroke;
}

- (NSColor *)strokeColor {
    return [[_strokeColor retain] autorelease];
}

- (void)setStrokeColor:(NSColor*)color {
    _strokeColor = color;
}

- (CGFloat)strokeWidth {
    return _strokeWidth;
}

- (void)setStrokeWidth:(CGFloat)color {
    _strokeWidth = color;
}

- (BOOL)isDrawingFill {
    return _isDrawingFill;
}

- (NSColor *)fillColor {
    return [[_fillColor retain] autorelease];
}

- (void)setColor:(NSColor *)color {
    // Can we fill the graphic?
    if ([self canSetDrawingFill]) {
        // Are we filling it? If not, start, using the new color.
        if (![self isDrawingFill]) {
            [self setValue:[NSNumber numberWithBool:YES] forKey:@"drawingFill"];
        }
        [self setValue:color forKey:@"fillColor"];

    }
    
}

- (NSRect)drawingBounds2 {
    CGFloat outset = MFGraphicHandleHalfWidth;
    
    CGFloat inset = 0.0f - outset;
    NSRect drawingBounds = NSInsetRect([self bounds], inset, inset);
    
    // -drawHandleInView:atPoint: draws a one-unit drop shadow too.
    drawingBounds.size.width += 1.0f;
    drawingBounds.size.height += 1.0f;
    return drawingBounds;
}

- (NSRect)drawingBounds {
    CGFloat outset = MFGraphicHandleHalfWidth;
    if ([self isDrawingStroke]) {
        CGFloat strokeOutset = [self strokeWidth] / 2.0f;
        if (strokeOutset > outset) {
            outset = strokeOutset;
        }
    }
    CGFloat inset = 0.0f - outset;
    NSRect drawingBounds = NSInsetRect([self bounds], inset, inset);
    
    // -drawHandleInView:atPoint: draws a one-unit drop shadow too.
    drawingBounds.size.width += 1.0f;
    drawingBounds.size.height += 1.0f;
    return drawingBounds;
    
}

- (void)drawContentsInView:(NSView *)view isSelected:(BOOL)isSelected{
    
    // If the graphic is so so simple that it can be boiled down to a bezier path then just draw a bezier path. It's -bezierPathForDrawing's responsibility to return a path with the current stroke width.
    NSBezierPath *path = [self bezierPathForDrawing];
    if (path) {
        
        if ([self isDrawingStroke]) {
            [[self strokeColor] set];
            [path stroke];
        }
    }
    
}

- (NSBezierPath *)bezierPathForDrawing {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}


- (void)drawHandlesInView:(NSView *)view {
    
    // Draw handles at the corners and on the sides.
    NSRect bounds = [self bounds];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMinX(bounds), NSMinY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMidX(bounds), NSMinY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMaxX(bounds), NSMinY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMinX(bounds), NSMidY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMaxX(bounds), NSMidY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMinX(bounds), NSMaxY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMidX(bounds), NSMaxY(bounds))];
    [self drawHandleInView:view atPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];
    
}


- (void)drawHandleInView:(NSView *)view atPoint:(NSPoint)point {
    
    // Figure out a rectangle that's centered on the point but lined up with device pixels.
    NSRect handleBounds;
    handleBounds.origin.x = point.x - MFGraphicHandleHalfWidth;
    handleBounds.origin.y = point.y - MFGraphicHandleHalfWidth;
    handleBounds.size.width = MFGraphicHandleWidth;
    handleBounds.size.height = MFGraphicHandleWidth;
    handleBounds = [view centerScanRect:handleBounds];
    
    // Draw the shadow of the handle.
    NSRect handleShadowBounds = NSOffsetRect(handleBounds, 1.0f, 1.0f);
    [[NSColor controlDarkShadowColor] set];
    NSRectFill(handleShadowBounds);
    
    // Draw the handle itself.
    [[NSColor knobColor] set];
    NSRectFill(handleBounds);
    
}

- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds {
    
    // Live to be overridden.
    return nil;
    
}


- (void)finalizeEditingView:(NSView *)editingView {
    
    // Live to be overridden.
    
}

- (BOOL)canSetDrawingFill {
    
    // The default implementation of -drawContentsInView: can draw fills.
    return YES;
    
}


- (BOOL)canSetDrawingStroke {
    
    // The default implementation of -drawContentsInView: can draw strokes.
    return YES;
    
}

@end
