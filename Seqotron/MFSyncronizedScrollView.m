//
//  MFSyncronizedScrollView.m
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

#import "MFSyncronizedScrollView.h"

// https://developer.apple.com/library/mac/documentation/Cocoa/Conceptual/NSScrollViewGuide/Articles/SynchroScroll.html#//apple_ref/doc/uid/TP40003537-SW5

@implementation MFSyncronizedScrollView

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _synchronizeVertical = YES;
        [self setVerticalScrollElasticity:NSScrollElasticityNone];
        [self setHorizontalScrollElasticity:NSScrollElasticityNone];
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
	
    // Drawing code here.
}

- (void)setSynchronizedScrollView:(NSScrollView*)scrollview onVertical:(BOOL)vertical{
    NSView *synchronizedContentView;
	_synchronizeVertical = vertical;
    
    // stop an existing scroll view synchronizing
    [self stopSynchronizing];
	
    // don't retain the watched view, because we assume that it will
    // be retained by the view hierarchy for as long as we're around.
    synchronizedScrollView = scrollview;
	
    // get the content view of the
    synchronizedContentView = [synchronizedScrollView contentView];
	
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
	
    // get the origin of the NSClipView of the scroll view that
    // we're watching
    NSPoint changedBoundsOrigin = [changedContentView documentVisibleRect].origin;;
	
    // get our current origin
    NSPoint curOffset = [[self contentView] bounds].origin;
    NSPoint newOffset = curOffset;
	
    // scrolling is synchronized in the vertical plane
    // so only modify the y component of the offset
    if(_synchronizeVertical) newOffset.y = changedBoundsOrigin.y;
    else newOffset.x = changedBoundsOrigin.x;
	
    // if our synced position is different from our current
    // position, reposition our content view
    if (!NSEqualPoints(curOffset, changedBoundsOrigin)){
		// note that a scroll view watching this one will
		// get notified here
		[[self contentView] scrollToPoint:newOffset];
		// we have to tell the NSScrollView to update its
		// scrollers
		[self reflectScrolledClipView:[self contentView]];
    }
}

- (void)stopSynchronizing{
    if (synchronizedScrollView != nil) {
		NSView* synchronizedContentView = [synchronizedScrollView contentView];
		
		// remove any existing notification registration
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:NSViewBoundsDidChangeNotification
													  object:synchronizedContentView];
		
		// set synchronizedScrollView to nil
		synchronizedScrollView=nil;
    }
}

@end
