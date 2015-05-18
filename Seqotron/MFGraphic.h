//
//  MFGraphic.h
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

@interface MFGraphic : NSObject{
    NSRect _bounds;
    BOOL _isDrawingStroke;
    NSColor *_strokeColor;
    CGFloat _strokeWidth;
    BOOL _isDrawingFill;
    NSColor *_fillColor;
}


- (NSRect)bounds;

- (void)setBounds:(NSRect)bounds;

- (CGFloat)xPosition;

- (CGFloat)yPosition;

- (CGFloat)width;

- (CGFloat)height;

- (void)setXPosition:(CGFloat)xPosition;

- (void)setYPosition:(CGFloat)yPosition;

- (void)setWidth:(CGFloat)width;

- (void)setHeight:(CGFloat)height;

- (BOOL)isDrawingStroke;

- (NSColor *)strokeColor;

- (void)setStrokeColor:(NSColor*)color;

- (CGFloat)strokeWidth;

- (void)setStrokeWidth:(CGFloat)color;


- (BOOL)isDrawingFill;
- (NSColor *)fillColor;

#pragma mark *** Drawing ***

// Return the bounding box of everything the receiver might draw when sent a -draw...InView: message. The default implementation of this method returns a bounds that assumes the default implementations of -drawContentsInView: and -drawHandlesInView:. Subclasses that override this probably have to override +keyPathsForValuesAffectingDrawingBounds too.
- (NSRect)drawingBounds;

// Draw the contents the receiver in a specific view. Use isBeingCreatedOrEditing if the graphic draws differently during its creation or while it's being edited. The default implementation of this method just draws the result of invoking -bezierPathForDrawing using the current fill and stroke parameters. Subclasses have to override either this method or -bezierPathForDrawing. Subclasses that override this may have to override +keyPathsForValuesAffectingDrawingBounds, +keyPathsForValuesAffectingDrawingContents, and -drawingBounds too.
- (void)drawContentsInView:(NSView *)view isSelected:(BOOL)isSelected;

// Return a bezier path that can be stroked and filled to draw the graphic, if the graphic can be drawn so simply, nil otherwise. The default implementation of this method returns nil. Subclasses have to override either this method or -drawContentsInView:. Any returned bezier path should already have the graphic's current stroke width set in it.
- (NSBezierPath *)bezierPathForDrawing;

// Draw the handles of the receiver in a specific view. The default implementation of this method just invokes -drawHandleInView:atPoint: for each point at the corners and on the sides of the rectangle returned by -bounds. Subclasses that override this probably have to override -handleUnderPoint: too.
- (void)drawHandlesInView:(NSView *)view;

// Draw handle at a specific point in a specific view. Subclasses that override -drawHandlesInView: can invoke this to easily draw handles whereever they like.
- (void)drawHandleInView:(NSView *)view atPoint:(NSPoint)point;


// Set the color of the graphic, whatever that means. The default implementation of this method just sets isDrawingFill to YES and fillColor to the passed-in color. In Sketch this method is invoked when the user drops a color chip on the graphic or uses the color panel to change the color of all of the selected graphics.
- (void)setColor:(NSColor *)color;

// Return YES if it's useful to let the user toggle drawing of the fill or stroke, NO otherwise. The default implementations of these methods return YES.
- (BOOL)canSetDrawingFill;
- (BOOL)canSetDrawingStroke;

#pragma mark *** Editing ***

// Given that the receiver has just been created or double-clicked on or something, create and return a view that can present its editing interface to the user, or return nil. The returned view should be suitable for becoming a subview of a view whose bounds is passed in. Its frame should match the bounds of the receiver. The receiver should not assume anything about the lifetime of the returned editing view; it may remain in use even after subsequent invocations of this method, which should, again, create a new editing view each time. In other words, overrides of this method should be prepared for a graphic to have more than editing view outstanding. The default implementation of this method returns nil. In Sketch SKTText overrides it.
- (NSView *)newEditingViewWithSuperviewBounds:(NSRect)superviewBounds NS_RETURNS_NOT_RETAINED;

// Given an editing view that was returned by a previous invocation of -newEditingViewWithSuperviewBounds:, tear down whatever connections exist between it and the receiver.
- (void)finalizeEditingView:(NSView *)editingView;


@end
