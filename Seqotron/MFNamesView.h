//
//  MFNamesView.h
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


@interface MFNamesView : NSView {

    NSMutableDictionary *_attsDict;
    CGFloat _residueHeight;
    CGFloat _residueWidth;
    CGFloat _lineGap;
    
    NSPoint dragStartPoint;
    NSPoint dragPoint;
    NSArray *_sequences;
    NSIndexSet *_selectionIndexes;
}

@property (readwrite,copy) NSString *fontName;
@property (readwrite) CGFloat fontSize;
@property (readwrite) CGFloat rowSpacing;

@end

