//
//  MFTreeDocument.h
//  Seqotron
//
//  Created by Mathieu Fourment on 14/12/2014.
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

#import "MFTreeView.h"

@interface MFTreeWindowController : NSWindowController <NSToolbarDelegate>{
    IBOutlet NSView *_arrowsView;
    IBOutlet NSScrollView *_scrollView;
    IBOutlet NSArrayController *_treesController;
    IBOutlet MFTreeView *_treeView;
    IBOutlet NSSearchField *_searchField;
    IBOutlet NSPopUpButton *_popUpButtonInternalNodes;
    
    IBOutlet NSView *_saveDialogCustomView;
    IBOutlet NSComboBox   *_saveFileFormat;
    
    NSMutableArray *_nodeAttributes;
    
    NSString *_searchKey;
    NSMutableArray *_searchNodes;
    
    NSFont *_font;
    CGFloat _fontSize;
    NSString *_fontName;
    
    NSArray *_selectedNodes;
}

@property (retain, readwrite) NSMutableArray *nodeAttributes;

@property(nonatomic,assign) NSView *saveDialogCustomView;
@property(nonatomic,assign) NSComboBox   *saveFileFormat;
@property (readwrite) BOOL taxaShown;
@property (readwrite) NSInteger selectionMode;

- (void)setSelectedNodes:(NSArray *)selectedNodes;

-(NSArray*)selectedNodes;

@end
