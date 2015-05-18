//
//  MFSimpleAlignmentView.h
//  Seqotron
//
//  Created by Mathieu Fourment on 3/03/2015.
//  Copyright (c) 2015 Mathieu Fourment. All rights reserved.
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

@interface MFSimpleAlignmentView : NSView{
    NSArray *_sequences;
    CGFloat _fontSize;
    NSString *_fontName;
    CGFloat _rowSpacing;
    CGFloat _residueWidth;
    CGFloat _residueHeight;
    CGFloat _rowHeight;
    CGFloat _lineGap;
    NSMutableDictionary *_attsDict;
    NSMutableDictionary *_foregroundColor;
    NSMutableDictionary *_backgroundColor;
    BOOL _drawBackground;
    NSColor *_canvasColor;
}

@property (retain, readwrite) NSArray *sequences;
@property (nonatomic,retain, readwrite) NSMutableDictionary *foregroundColor;
@property (nonatomic,retain, readwrite) NSMutableDictionary *backgroundColor;
@property CGFloat residueHeight;

@end
