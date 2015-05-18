//
//  MFWindowController.h
//  Seqotron
//
//  Created by Mathieu Fourment on 6/08/2014.
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

#import "MFSequencesView.h"
#import "MFNamesView.h"
#import "MFRulerView.h"
#import "MFSyncronizedScrollView.h"

#import "MFTreeBuilderController.h"
#import "MFAlignerController.h"
#import "MFDistanceMatrixOperation.h"


@interface MFWindowController : NSWindowController<NSSpeechSynthesizerDelegate,NSWindowDelegate,NSToolbarDelegate>{
@private
    
    // The values underlying the key-value coding (KVC) and observing (KVO) compliance described below.
    IBOutlet NSArrayController *_sequencesController;
    
    // Other objects we expect to find in the nib.
    IBOutlet MFSequencesView *_sequencesView;
    IBOutlet MFNamesView *_namesView;
    IBOutlet MFRulerView *_rulerView;
    
    IBOutlet MFSyncronizedScrollView *_sequencesScrollView;
    IBOutlet MFSyncronizedScrollView *_namesScrollView;
    
    IBOutlet NSPopUpButton *_dataTypePopUp;
    IBOutlet NSPopUpButton *_geneticCodePopUp;
    
    IBOutlet NSArrayController *_coloringController;
    IBOutlet NSArrayController *_dataTypeController;
    IBOutlet NSArrayController *_geneticCodeController;
    
    IBOutlet NSSearchField *_searchField;
    
    NSArray *_dataTypes;
    
    NSMutableArray *_colorSchemes;
    
    IBOutlet NSView     *_saveDialogCustomView;
    IBOutlet NSComboBox *_saveFileFormat;
    
    NSString *_nucleotideColoringDescription;
    NSString *_aaColoringDescription;
    
    NSFont *_font;
    CGFloat _rowSpacing;
    
    NSMutableDictionary *_geneticTable;
    NSArray  *_geneticCodes;
    
    NSInteger _searchSequence;
    NSUInteger _searchSite;
    NSInteger _currentSearchTag;
    
    NSSpeechSynthesizer *_speechSynthesizer;
    
    MFTreeBuilderController *_treeBuilderController;
    MFAlignerController *_alignerController;
    NSMapTable *_progressControllers;
    
    NSMutableArray *_windowControllers;
    
    NSString *_coloringFolder;
    
}

@property(nonatomic,assign) MFSequencesView *sequencesView;
@property(nonatomic,assign) MFNamesView *namesView;
@property(nonatomic,assign) MFRulerView *rulerView;

@property(nonatomic,assign) NSView *saveDialogCustomView;
@property(nonatomic,assign) NSComboBox   *saveFileFormat;

@property (retain,readwrite) NSArrayController *coloringController;
@property (retain,readwrite) NSArrayController *dataTypeController;

@property (retain, readonly) NSArray *dataTypes;

@property (retain, readwrite) NSMutableArray *colorSchemes;


@property (nonatomic,readwrite, retain) NSDictionary *foregroundColor;
@property (nonatomic,readwrite, retain) NSDictionary *backgroundColor;

@property (readwrite) CGFloat fontSize;
@property (readwrite) CGFloat rowSpacing;
@property (readwrite, retain) NSString *fontName;


@end
