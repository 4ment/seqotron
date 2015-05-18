//
//  MFBranchGraphic.h
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

@interface MFLineGraphic : MFGraphic{

    // YES if the line's ending is to the right or below, respectively, it's beginning, NO otherwise. Because we reuse SKTGraphic's "bounds" property, we have to keep track of the corners of the bounds at which the line begins and ends. A more natural thing to do would be to just record two points, but then we'd be wasting an NSRect's worth of ivar space per instance, and have to override more SKTGraphic methods to boot. This of course raises the question of why SKTGraphic has a bounds property when it's not readily applicable to every conceivable subclass. Perhaps in the future it won't, but right now in Sketch it's the handy thing to do for four out of five subclasses.
    BOOL _pointsRight;
    BOOL _pointsDown;
}

- (NSPoint)beginPoint;

- (NSPoint)endPoint;

- (void)setBeginPoint:(NSPoint)beginPoint;

- (void)setEndPoint:(NSPoint)endPoint;

@end
