//
//  MFPrefsWindowController.h
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
#import "DBPrefsWindowController.h"
#import "MFSimpleAlignmentView.h"

@interface MFPrefsWindowController : DBPrefsWindowController <NSWindowDelegate>{
    IBOutlet NSView *_colorView;
    IBOutlet NSMatrix *_matrix;
    IBOutlet MFSimpleAlignmentView *_alignmentView;
    IBOutlet NSSegmentedControl *_segmentedDataType;
    IBOutlet NSSegmentedControl *_segmented;
    IBOutlet NSTableView *_tableView;
    IBOutlet NSArrayController *_schemeController;
    
    NSMutableArray *_schemes;
    NSMutableDictionary *_colors;
    NSUInteger _firstUserIndex;
    
    BOOL _editingForeground;
    BOOL _newScheme;
    NSString *_newSchemeFilename;
    NSUInteger _selectedDatatypeSegment;
    
    NSString *_currentScheme;
    
    NSMutableArray *_sequences;
}

@property (retain, readwrite) NSMutableArray *schemes;
@property (retain, readwrite) NSMutableArray *sequences;

@end
