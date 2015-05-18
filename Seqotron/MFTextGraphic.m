//
//  MFTextGraphic.m
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

#import "MFTextGraphic.h"

@implementation MFTextGraphic


-(id)initWithString:(NSString*)string attributes:(NSDictionary*)attrs{
    if( self = [super init]){
        _contents = [[NSTextStorage alloc]initWithString:string attributes:attrs];
        
        NSRect bounds = [self bounds];
        NSSize naturalSize = [self naturalSize];
        [self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, naturalSize.width, naturalSize.height)];
        _contents.delegate = self;
    }
    return self;
}

-(id)initWithString:(NSString*)string{
    if( self = [super init]){
        _contents = [[NSTextStorage alloc]initWithString:string];
        [_contents addAttribute:NSFontAttributeName
                          value:[NSFont fontWithName:@"Courier" size:12]
                          range:NSMakeRange(0, [_contents length])];
//        [_contents addAttribute:NSBackgroundColorAttributeName
//                          value:[NSColor redColor]
//                          range:NSMakeRange(0, [_contents length])];
        
        NSRect bounds = [self bounds];
        NSSize naturalSize = [self naturalSize];
        [self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, naturalSize.width, naturalSize.height)];
        _contents.delegate = self;
        _updateBounds = NO;
    }
    return self;
}

- (void)dealloc {
    
    // Do the regular Cocoa thing.
    [_contents setDelegate:nil];
    [_contents release];
    [super dealloc];
    
}

- (NSString*)description{
    return [NSString stringWithFormat: @"MFTextGraphic %@ x %f y %f w %f h %f", [_contents string], _bounds.origin.x,_bounds.origin.y, _bounds.size.width, _bounds.size.height ];
}

- (NSTextStorage *)contents {
    return _contents;
    
}

- (BOOL)isDrawingStroke {
    
    // We never draw a stroke on this kind of graphic.
    return NO;
    
}

- (NSRect)drawingBounds {
    if (_updateBounds ) {
        NSRect bounds = [self bounds];
        NSSize naturalSize = [self naturalSize];
        [self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, naturalSize.width, naturalSize.height)];
        
        _updateBounds = NO;
    }
    // The drawing bounds must take into account the focus ring that might be drawn by this class' override of -drawContentsInView:isBeingCreatedOrEdited:. It can't forget to take into account drawing done by -drawHandleInView:atPoint: though. Because this class doesn't override -drawHandleInView:atPoint:, it should invoke super to let SKTGraphic take care of that, and then alter the results.
    return NSUnionRect([super drawingBounds], NSInsetRect([self bounds], -1.0f, -1.0f));
}


- (void)drawContentsInView2:(NSView *)view isBeingCreateOrEdited:(BOOL)isBeingCreatedOrEditing {
    
    // Draw the fill color if appropriate.
    NSRect bounds = [self bounds];
//    if ([self isDrawingFill]) {
//        [[self fillColor] set];
//        NSRectFill(bounds);
//    }
    
    // If this graphic is being created it has no text. If it is being edited then the editor returned by -newEditingViewWithSuperviewBounds: will draw the text.
    if (isBeingCreatedOrEditing) {
        
        // Just draw a focus ring.
        [[NSColor knobColor] set];
        NSFrameRect(NSInsetRect(bounds, -1.0, -1.0));
        
    }
    else {
        
        // Don't bother doing anything if there isn't actually any text.
        NSTextStorage *contents = [self contents];
        if ( [contents length] > 0 ) {
            
            // Get a layout manager, size its text container, and use it to draw text. -glyphRangeForTextContainer: forces layout and tells us how much of text fits in the container.
            NSLayoutManager *layoutManager = [[self class] sharedLayoutManager];
            NSTextContainer *textContainer = [[layoutManager textContainers] objectAtIndex:0];
            [textContainer setContainerSize:bounds.size];
            [contents addLayoutManager:layoutManager];
            NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
            if (glyphRange.length > 0 ) {
                [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:bounds.origin];
                [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:bounds.origin];
            }
            [contents removeLayoutManager:layoutManager];
            
        }
        
    }
    
}

- (void)drawContentsInView:(NSView *)view isSelected:(BOOL)isSelected {
    
    if (_updateBounds ) {
        NSRect bounds = [self bounds];
        NSSize naturalSize = [self naturalSize];
        [self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, naturalSize.width, naturalSize.height)];
        
        _updateBounds = NO;
    }
    
    NSRect bounds = [self bounds];
    if ([self isDrawingFill]) {
        [[self fillColor] set];
        NSRectFill(bounds);
    }

//    NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
//    NSTextContainer *textContainer = [[NSTextContainer alloc] init];
//    
//    [layoutManager addTextContainer:textContainer];
//    [textContainer release];
//    [_contents addLayoutManager:layoutManager];
//    
//    [layoutManager release];
    // Get a layout manager, size its text container, and use it to draw text. -glyphRangeForTextContainer: forces layout and tells us how much of text fits in the container.
    
    NSLayoutManager *layoutManager = [[self class] sharedLayoutManager];
    NSTextContainer *textContainer = [[layoutManager textContainers] objectAtIndex:0];
    [textContainer setContainerSize:bounds.size];
    [_contents addLayoutManager:layoutManager];
    
    NSRange glyphRange = [layoutManager glyphRangeForTextContainer:textContainer];
    
    [view lockFocus];
    if ( isSelected) {
        [[NSColor knobColor] set];
        NSRectFill(bounds);
        //NSFrameRect(NSInsetRect(bounds, -1.0, -1.0));
    }
    else {
        [layoutManager drawBackgroundForGlyphRange:glyphRange atPoint:bounds.origin];
    }
    [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:bounds.origin];
    [view unlockFocus];
    
    [_contents removeLayoutManager:layoutManager];
    
}


+ (NSLayoutManager *)sharedLayoutManager {
    
    // Return a layout manager that can be used for any drawing.
    static NSLayoutManager *layoutManager = nil;
    if (!layoutManager) {
        NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(1.0e7f, 1.0e7f)];
        layoutManager = [[NSLayoutManager alloc] init];
        [textContainer setWidthTracksTextView:NO];
        [textContainer setHeightTracksTextView:NO];
        [layoutManager addTextContainer:textContainer];
        [textContainer release];
    }
    return layoutManager;
}

- (NSSize)naturalSize {
    
    // Figure out how big this graphic would have to be to show all of its contents. -glyphRangeForTextContainer: forces layout.
    NSLayoutManager *layoutManager = [[self class] sharedLayoutManager];
    NSTextContainer *textContainer = [[layoutManager textContainers] objectAtIndex:0];
    [textContainer setContainerSize:NSMakeSize(1.0e7f, 1.0e7f)];
    NSTextStorage *contents = [self contents];
    [contents addLayoutManager:layoutManager];
    [layoutManager glyphRangeForTextContainer:textContainer];
    NSSize naturalSize = [layoutManager usedRectForTextContainer:textContainer].size;
    [contents removeLayoutManager:layoutManager];
    return naturalSize;
    
}

- (void)setHeightToMatchContents {
    NSRect bounds = [self bounds];
    NSSize naturalSize = [self naturalSize];
    [self setBounds:NSMakeRect(bounds.origin.x, bounds.origin.y, naturalSize.width, naturalSize.height)];
    
}

// Conformance to the NSTextStorageDelegate protocol.
// In my case setHeightToMatchContents is called after drawRect so it does not have the right bounds
- (void)textStorageDidProcessEditing:(NSNotification *)notification {
    // The work we're going to do here involves sending -glyphRangeForTextContainer: to a layout manager, but you can't send that message to a layout manager attached to a text storage that's still responding to -endEditing, so defer the work to a point where -endEditing has returned.
    //[self performSelector:@selector(setHeightToMatchContents) withObject:nil afterDelay:0.0];
    _updateBounds = YES;
}
@end
