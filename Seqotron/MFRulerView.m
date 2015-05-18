//
//  MFRulerView.m
//  Seqotron
//
//  Created by Mathieu Fourment on 30/01/14.
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

#import "MFRulerView.h"


@implementation MFRulerView

- (id)initWithFrame:(NSRect)frame
{
    NSLog(@"MFRuler init");
    self = [super initWithFrame:frame];
    if (self) {
        _synchronizedScrollView = nil;
        _colSpacing = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceColumnSpacing"]floatValue];
        _fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontSize"]floatValue];
        _fontName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontName"]copy];
        [self initResidueWidthWithFontSize:_fontSize name:_fontName];
    }
    return self;
}

-(void) dealloc{
    NSLog(@"MFRulerView dealloc");
    [_fontName release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect{
    
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);

    // We always draw the whole ruler
    _visibleRect.size.width = [self bounds].size.width;
    
    NSUInteger nCol     = ceil(_visibleRect.size.width/_residueWidth);
    NSUInteger sitePos  = _visibleRect.origin.x/_residueWidth;
    
    NSPoint startMajorPoint = NSMakePoint(sitePos*_residueWidth-_visibleRect.origin.x + (_residueWidth/2), 0.0);
    NSPoint endMajorPoint   = NSMakePoint(sitePos*_residueWidth-_visibleRect.origin.x + (_residueWidth/2), 6);
    
    NSPoint startMinorPoint = NSMakePoint(sitePos*_residueWidth-_visibleRect.origin.x + (_residueWidth/2), 0.0);
    NSPoint endMinorPoint   = NSMakePoint(sitePos*_residueWidth-_visibleRect.origin.x + (_residueWidth/2), 3);
    
    startMajorPoint.x -= ((sitePos%5)+1)*_residueWidth;
    endMajorPoint.x   -= ((sitePos%5)+1)*_residueWidth;
    
    NSBezierPath* aPath = [NSBezierPath bezierPath];
    NSUInteger majorLabel = sitePos - sitePos%5;
    
    for ( int j = 0; j <= nCol+2; j++ ) {
        if( j%5 == 0 ){
            
            if(majorLabel == 0){
                NSPoint p = startMajorPoint;
                p.x += _residueWidth;
                [aPath moveToPoint:p];
                p = endMajorPoint;
                p.x += _residueWidth;
                [aPath lineToPoint:p];
                [aPath stroke];
                
                NSString *index = [NSString stringWithFormat:@"%d", 1];
                [index drawAtPoint:NSMakePoint(startMajorPoint.x+_residueWidth, 6) withAttributes:nil];
            }
            else {
                [aPath moveToPoint:startMajorPoint];
                [aPath lineToPoint:endMajorPoint];
                [aPath stroke];
                
                NSString *index = [NSString stringWithFormat:@"%lu", majorLabel];
                [index drawAtPoint:NSMakePoint(startMajorPoint.x, 6) withAttributes:nil];
            }
            majorLabel += 5;
        }
        
        [aPath moveToPoint:startMinorPoint];
        [aPath lineToPoint:endMinorPoint];
        [aPath stroke];
        
        startMajorPoint.x += _residueWidth;
        endMajorPoint.x   += _residueWidth;
        
        startMinorPoint.x += _residueWidth;
        endMinorPoint.x   += _residueWidth;
        
    }
}

- (void)drawRect2:(NSRect)dirtyRect{
    
    [[NSColor whiteColor] set];
    NSRectFill(dirtyRect);
    
    // Draw the ruler when we load since the scrollview has not moved yet and no notifications
    // have been received yet
    if( NSIsEmptyRect(_visibleRect) ){
        _visibleRect.size.width = [self bounds].size.width;
    }
    
    
    
    NSUInteger nCol     = ceil(_visibleRect.size.width/(_residueWidth+_colSpacing)); // number of visible residues
    NSUInteger sitePos  = _visibleRect.origin.x/(_residueWidth+_colSpacing); // first visible residue
    
    NSPoint startMajorPoint = NSMakePoint(sitePos*(_residueWidth+_colSpacing)-_visibleRect.origin.x + (_residueWidth/2), 0.0);
    NSPoint endMajorPoint   = NSMakePoint(startMajorPoint.x, 6);
    
    NSPoint startMinorPoint = NSMakePoint(sitePos*(_residueWidth+_colSpacing)-_visibleRect.origin.x + (_residueWidth/2), 0.0);
    NSPoint endMinorPoint   = NSMakePoint(startMinorPoint.x, 3);
    
    startMajorPoint.x -= ((sitePos%5)+1)*(_residueWidth+_colSpacing);
    endMajorPoint.x   -= ((sitePos%5)+1)*(_residueWidth+_colSpacing);
    
    NSBezierPath* aPath = [NSBezierPath bezierPath];
    NSUInteger majorLabel = sitePos - sitePos%5;
    
    for ( NSUInteger j = 0; j <= nCol+2; j++ ) {
        if( j%5 == 0 ){
            
            if(majorLabel == 0){
                NSPoint p = startMajorPoint;
                p.x += (_residueWidth+_colSpacing);
                [aPath moveToPoint:p];
                p.y = 3;
                [aPath lineToPoint:p];
                [aPath stroke];
                
                NSString *index = [NSString stringWithFormat:@"%d", 1];
                [index drawAtPoint:NSMakePoint(startMajorPoint.x+_residueWidth, 6) withAttributes:nil];
            }
            else {
                [aPath moveToPoint:startMajorPoint];
                [aPath lineToPoint:endMajorPoint];
                [aPath stroke];
                
                NSString *index = [NSString stringWithFormat:@"%lu", majorLabel];
                [index drawAtPoint:NSMakePoint(startMajorPoint.x, 6) withAttributes:nil];
            }
            majorLabel += 5;
        }
        NSBezierPath* aPath = [NSBezierPath bezierPath];
        [aPath moveToPoint:startMinorPoint];
        [aPath lineToPoint:endMinorPoint];
        [aPath stroke];
        
        startMajorPoint.x += (_residueWidth+_colSpacing);
        endMajorPoint.x   += (_residueWidth+_colSpacing);
        
        startMinorPoint.x += (_residueWidth+_colSpacing);
        endMinorPoint.x   += (_residueWidth+_colSpacing);
        
    }
}

- (void)setSynchronizedScrollView:(NSScrollView*)scrollview{
    NSView *synchronizedContentView;
    
    // stop an existing scroll view synchronizing
    [self stopSynchronizing];
	
    // don't retain the watched view, because we assume that it will
    // be retained by the view hierarchy for as long as we're around.
    _synchronizedScrollView = scrollview;
	
    // get the content view of the
    synchronizedContentView = [_synchronizedScrollView contentView];
	
    // Make sure the watched view is sending bounds changed
    // notifications (which is probably does anyway, but calling
    // this again won't hurt).
    [synchronizedContentView setPostsBoundsChangedNotifications:YES];
	
    // a register for those notifications on the synchronized content view.
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(synchronizedViewContentBoundsDidChange:)
												 name:NSViewBoundsDidChangeNotification
											   object:synchronizedContentView];
}

- (void)synchronizedViewContentBoundsDidChange:(NSNotification *)notification{
    // get the changed content view from the notification
    NSClipView *changedContentView = [notification object];
	
    if( !NSEqualRects(_visibleRect, [changedContentView documentVisibleRect]) ){
        _visibleRect = [changedContentView documentVisibleRect];
        [self setNeedsDisplay:YES];
    }
}

- (void)stopSynchronizing{
    if (_synchronizedScrollView != nil) {
		NSView* synchronizedContentView = [_synchronizedScrollView contentView];
		
		// remove any existing notification registration
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSViewBoundsDidChangeNotification
													  object:synchronizedContentView];
		
		// set synchronizedScrollView to nil
		_synchronizedScrollView=nil;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)observedObject change:(NSDictionary *)change context:(void *)context {
    if ( [keyPath isEqualToString:@"residueWidth"] ) {
        //_fontSize = [[change objectForKey:NSKeyValueChangeNewKey]floatValue];
        //[self initSize];
        _residueWidth = [[change objectForKey:NSKeyValueChangeNewKey]floatValue];
        [self setNeedsDisplay:YES];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:observedObject change:change context:context];
    }
}

-(void)initResidueWidthWithFontSize:(CGFloat)fontSize name:(NSString*)fontName{
    NSMutableDictionary *attsDict = [[NSMutableDictionary alloc] init];
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
    [attsDict setObject:font forKey:NSFontAttributeName];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"A" attributes:attsDict];
    _residueWidth  = [string size].width;
    [string release];
    [attsDict release];
}

- (BOOL)isFlipped{
    return NO;
}

@end
