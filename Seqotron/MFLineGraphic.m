//
//  MFLineGraphic.m
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

#import "MFLineGraphic.h"

@implementation MFLineGraphic

- (NSString*)description{
    return [NSString stringWithFormat: @"MFLineGraphic x %f y %f w %f h %f",_bounds.origin.x,_bounds.origin.y, _bounds.size.width, _bounds.size.height ];
}

- (void)drawContentsInView:(NSView *)view isSelected:(BOOL)isSelected{
    
    // If the graphic is so so simple that it can be boiled down to a bezier path then just draw a bezier path. It's -bezierPathForDrawing's responsibility to return a path with the current stroke width.
    NSBezierPath *path = [self bezierPathForDrawing];
    if (path) {
        if(isSelected){
            CGFloat x = NSMinX([self bounds]);
            CGFloat y = NSMinY([self bounds]);
            CGFloat xx = NSMaxX([self bounds]);
            CGFloat stroke2 = [self strokeWidth]*6;
            NSRect rect = NSMakeRect(x, y-stroke2, xx-x, stroke2*2);
            [[NSColor knobColor] set];
            NSRectFill(rect);
        }
        if ([self isDrawingStroke]) {
            [[self strokeColor] set];
            [path stroke];
        }
    }
    
}

- (NSBezierPath *)bezierPathForDrawing {
    NSBezierPath *path = [NSBezierPath bezierPath];
    [path moveToPoint:[self beginPoint]];
    [path lineToPoint:[self endPoint]];
    [path setLineWidth:[self strokeWidth]];
    return path;
}

- (NSPoint)beginPoint {
    
    // Convert from our odd storage format to something natural.
    NSPoint beginPoint;
    NSRect bounds = [self bounds];
    beginPoint.x = _pointsRight ? NSMinX(bounds) : NSMaxX(bounds);
    beginPoint.y = _pointsDown ? NSMinY(bounds) : NSMaxY(bounds);
    return beginPoint;
    
}

- (NSPoint)endPoint {
    
    // Convert from our odd storage format to something natural.
    NSPoint endPoint;
    NSRect bounds = [self bounds];
    endPoint.x = _pointsRight ? NSMaxX(bounds) : NSMinX(bounds);
    endPoint.y = _pointsDown ? NSMaxY(bounds) : NSMinY(bounds);
    return endPoint;
    
}

- (void)setBeginPoint:(NSPoint)beginPoint {
    
    // It's easiest to compute the results of setting these points together.
    [self setBounds:[[self class] boundsWithBeginPoint:beginPoint endPoint:[self endPoint] pointsRight:&_pointsRight down:&_pointsDown]];
    
}


- (void)setEndPoint:(NSPoint)endPoint {
    
    // It's easiest to compute the results of setting these points together.
    [self setBounds:[[self class] boundsWithBeginPoint:[self beginPoint] endPoint:endPoint pointsRight:&_pointsRight down:&_pointsDown]];
    
}

- (BOOL)canSetDrawingFill {
    
    // Don't let the user think we can fill a line.
    return NO;
    
}


- (BOOL)canSetDrawingStroke {
    
    // Don't let the user think can ever not stroke a line.
    return NO;
    
}

- (BOOL)isDrawingFill {
    
    // You can't fill a line.
    return NO;
    
}


- (BOOL)isDrawingStroke {
    
    // You can't not stroke a line.
    return YES;
    
}

- (void)setColor:(NSColor *)color {
    
    // Because lines aren't filled we'll consider the stroke's color to be the one.
    [self setValue:color forKey:@"strokeColor"];
    
}

+ (NSRect)boundsWithBeginPoint:(NSPoint)beginPoint endPoint:(NSPoint)endPoint pointsRight:(BOOL *)outPointsRight down:(BOOL *)outPointsDown {
    
    // Convert the begin and end points of the line to its bounds and flags specifying the direction in which it points.
    BOOL pointsRight = beginPoint.x<endPoint.x;
    BOOL pointsDown = beginPoint.y<endPoint.y;
    CGFloat xPosition = pointsRight ? beginPoint.x : endPoint.x;
    CGFloat yPosition = pointsDown ? beginPoint.y : endPoint.y;
    CGFloat width = fabs(endPoint.x - beginPoint.x);
    CGFloat height = fabs(endPoint.y - beginPoint.y);
    if (outPointsRight) {
        *outPointsRight = pointsRight;
    }
    if (outPointsDown) {
        *outPointsDown = pointsDown;
    }
    return NSMakeRect(xPosition, yPosition, width, height);
    
}

@end
