//
//  MFWindowController.m
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

#import "MFWindowController.h"

#import "MFSequencesView.h"
#import "MFDocument.h"
#import "MFSequenceReader.h"
#import "MFSequenceWriter.h"
#import "MFSequence.h"
#import "MFSequenceUtils.h"
#import "MFNucleotide.h"
#import "MFProtein.h"
#import "MFSequenceSet.h"

#import "MFRulerView.h"
#import "MFSyncronizedScrollView.h"

#import "MFString.h"

#import "MFDistanceMatrix.h"
#import "MFDistanceMatrixOperation.h"
#import "MFJukeCantorDistanceMatrix.h"
#import "MFNeighborJoining.h"

#import "MFTreeDocument.h"
#import "MFExternalOperation.h"
#import "MFAppDelegate.h"
#import "MFProgressController.h"
#import "MFDistanceWindowController.h"

#import "MFColorManager.h"

#define kgeneticToolbarItemID @"Genetic code"


@implementation MFWindowController

@synthesize sequencesView = _sequencesView;
@synthesize namesView = _namesView;
@synthesize rulerView = _rulerView;
@synthesize saveDialogCustomView = _saveDialogCustomView;
@synthesize saveFileFormat = _saveFileFormat;
@synthesize coloringController = _coloringController;
@synthesize dataTypeController = _dataTypeController;
@synthesize colorSchemes = _colorSchemes;
@synthesize dataTypes = _dataTypes;
@synthesize fontSize, fontName;
@synthesize foregroundColor, backgroundColor;

- (id)init {
    if ( self = [super initWithWindowNibName:@"MFDocument"] ) {
        NSLog(@"Init MFWindowController");
        
        // Colors
        _coloringFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"MFColoringDirectory"];
        
        foregroundColor = [[NSMutableDictionary alloc] init];
        backgroundColor = [[NSMutableDictionary alloc] init];
        
        _colorSchemes = [[self loadColorSchemes:@"Nucleotide"]retain];
        _nucleotideColoringDescription = [[_colorSchemes objectAtIndex:0] copy];
        
        NSArray *protSchemes = [self loadColorSchemes:@"Amino Acid"];
        _aaColoringDescription = [[protSchemes objectAtIndex:0]copy];
        
        
        // Genetic code
        _geneticTable = [[NSMutableDictionary alloc] init];
        _geneticCodes = [[self loadGeneticCodes]retain];
        
        _dataTypes = [NSArray arrayWithObjects:[[[MFNucleotide alloc]init]autorelease],[[[MFProtein alloc]init]autorelease], nil];
        
        // Variables for views
        fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontSize"]floatValue];
        fontName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontName"]copy];
        _font = [NSFont fontWithName:fontName size:fontSize];
        _rowSpacing = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceRowSpacing"]floatValue];
        
        // Search
        _searchSite = NSNotFound;
        _searchSequence = NSNotFound;
        _currentSearchTag = 1;
        
        //Speach
        _speechSynthesizer = [NSSpeechSynthesizer new];
        [_speechSynthesizer setDelegate:self];
        [_speechSynthesizer setVoice:@"com.apple.speech.synthesis.voice.Alex" ];
        NSLog(@"speech rate %f", [_speechSynthesizer rate]);
        NSLog(@"voice %@", [_speechSynthesizer voice]);
        [_speechSynthesizer setRate: [_speechSynthesizer rate]/2.5];
        //NSLog(@"%@",[NSSpeechSynthesizer availableVoices]);
        
        // Phylogenetics, Alignment, other operations
        _treeBuilderController = nil;
        _alignerController = nil;
        _progressControllers = [[NSMapTable alloc]initWithKeyOptions:NSMapTableStrongMemory valueOptions:NSMapTableStrongMemory capacity:5];
        
        _windowControllers = [[NSMutableArray alloc]init];
    }
    return self;
    
}


- (void)dealloc {
    NSLog(@"MFWindowController dealloc");
    [foregroundColor release];
    [backgroundColor release];
    
    [_colorSchemes release];
    [_nucleotideColoringDescription release];
    [_aaColoringDescription release];
    
    [_geneticTable release];
    [_geneticCodes release];
    
    [fontName release];
    
    [_speechSynthesizer release];
    
    [self removeObserver:self forKeyPath:@"dataTypeController.selectionIndex"];
    [self removeObserver:self forKeyPath:@"geneticCodeController.selectionIndex"];
    [self removeObserver:self forKeyPath:@"coloringController.selectionIndex"];
    [self removeObserver:_rulerView forKeyPath:@"residueWidth"];
    [_sequencesController removeObserver:self forKeyPath:@"selectionIndexes"];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [_rulerView stopSynchronizing];
    [_namesScrollView stopSynchronizing];
    [_sequencesScrollView stopSynchronizing];
    
    [_progressControllers release];
    [_treeBuilderController release];
    [_alignerController release];
    [_windowControllers release];
    [super dealloc];
}

- (void)windowDidLoad {
    
    [super windowDidLoad];
    NSLog(@"MFWindowController windowDidLoad");
    
    // Bind the graphic view's selection indexes to the controller's selection indexes. The graphics controller's content array is bound to the document's graphics in the nib, so it knows when graphics are added and remove, so it can keep the selection indexes consistent.
    [_sequencesView bind:MFSequenceViewSelectionIndexesBindingName toObject:_sequencesController withKeyPath:@"selectionIndexes" options:nil];
    [_sequencesView bind:MFSequenceViewSequencesBindingName toObject:self withKeyPath:[NSString stringWithFormat:@"%@.%@", @"document", MFDocumentSequencesKey] options:nil];
    [_sequencesView bind:MFSequenceViewForegroundColorBindingName toObject:self withKeyPath:@"foregroundColor" options:nil];
    [_sequencesView bind:MFSequenceViewBackgroundColorBindingName toObject:self withKeyPath:@"backgroundColor" options:nil];
    [_sequencesView bind:MFSequenceViewFontSizeBindingName toObject:self withKeyPath:@"fontSize" options:nil];
    
    // Name View
    [_namesView bind:@"selectionIndexes" toObject:_sequencesController withKeyPath:@"selectionIndexes" options:nil];
    [_namesView bind:@"sequences" toObject:_sequencesController withKeyPath:@"arrangedObjects.name" options:nil];
    [_namesView bind:@"fontSize" toObject:self withKeyPath:@"fontSize" options:nil];
    [_namesView bind:@"fontName" toObject:self withKeyPath:@"fontName" options:nil];
    [_namesView bind:@"rowSpacing" toObject:self withKeyPath:@"rowSpacing" options:nil];
    
    // Scroll Views
    [[_namesScrollView verticalScroller] setControlSize:1]; // cannot use setHidden:YES as it makes the view unscrollable
    [_namesScrollView setSynchronizedScrollView:_sequencesScrollView onVertical:YES];
    [_sequencesScrollView setSynchronizedScrollView:_namesScrollView onVertical:YES]; //_sequenceView listens to _namesView
    [_rulerView setSynchronizedScrollView:_sequencesScrollView];
    
    [self.window registerForDraggedTypes:[self acceptableDragTypes]];
    
    [self dataTypeDidChange];
    
    if( [[_sequencesController arrangedObjects]count] > 0 ){
        NSString *desc = [[[[_sequencesController arrangedObjects]objectAtIndex:0]dataType]description];
        [_dataTypeController setSelectionIndex:[_dataTypePopUp indexOfItemWithTitle:desc]];
    }
    else {
        [_dataTypeController setSelectionIndex:0];
    }
    
    [self addObserver:self forKeyPath:@"dataTypeController.selectionIndex" options:(NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:@"geneticCodeController.selectionIndex" options:(NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:self forKeyPath:@"coloringController.selectionIndex" options:(NSKeyValueObservingOptionNew) context:NULL];
    [self addObserver:_rulerView forKeyPath:@"residueWidth" options:NSKeyValueObservingOptionNew context:NULL];
    [_sequencesController addObserver:self forKeyPath:@"selectionIndexes" options:(NSKeyValueObservingOptionNew) context:NULL];
    
    // Notifications
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(coloringNotification:) name:@"MFColoringDidChange" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(selectionNotification:) name:@"MFGlobalNameSelection" object:nil];
    
//    MFAppDelegate *del = [NSApp delegate];
//    // Set up the color scheme menu
//    NSInteger tag = 0;
//    for (NSString *gc in _colorSchemes) {
//        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:gc action:@selector(colorSchemeAction:) keyEquivalent:@""];
//        [item setTarget:self];
//        [item setTag:tag];
//        [[del coloringMenu] addItem:item];
//        [item release];
//        tag++;
//    }
    
    [_geneticCodeController setSelectedObjects:[NSArray arrayWithObject:@"Standard"]];
    for (MFSequence *seq in [_sequencesController arrangedObjects]) {
        [seq setGeneticTable:_geneticTable];
    }
    
    [_rulerView setNeedsDisplay:YES];
}

// There is a bug in cocoa that prevent getting selectionIndex and selectionIndexes in the change NSDictionary
// http://www.cocoabuilder.com/archive/cocoa/231886-problem-observing-selectionindex-of-an-array-controller.html

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {

    if ([keyPath isEqual:@"coloringController.selectionIndex"]) {
        [self setUpColoring:[[_coloringController selectedObjects]objectAtIndex:0]];
        
    }
    else if ([keyPath isEqual:@"dataTypeController.selectionIndex"]) {
        [self setSequencesDataType:[[_dataTypeController selectedObjects]objectAtIndex:0]];
    }
    else if ([keyPath isEqual:@"geneticCodeController.selectionIndex"]) {

        [self setUpGeneticTable];
        for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
            [sequence setGeneticTable:_geneticTable];
        }
        [_sequencesView setNeedsDisplay:YES];

    }
    else if ([keyPath isEqual:@"selectionIndexes"]) {
        NSMutableArray *names = [[NSMutableArray alloc]init];
        for (MFSequence *sequence in [_sequencesController selectedObjects]) {
            [names addObject:[sequence name]];
        }
        
        NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:names, @"selection", nil];
        [[NSNotificationCenter defaultCenter]postNotificationName:@"MFGlobalNameSelection" object:self userInfo:dict];
        [names release];
    }
    else if( [keyPath isEqualToString:@"isFinished"]){
        if ( [object isKindOfClass:[MFDistanceMatrixOperation class]] ) {
            MFDistanceMatrixOperation *op = (MFDistanceMatrixOperation *) object;
            [self performSelectorOnMainThread:@selector(distanceMatrixOperationDone:) withObject:op waitUntilDone:NO];
        }
        else {
            MFExternalOperation *op = (MFExternalOperation *) object;
            [self performSelectorOnMainThread:@selector(operationDone:) withObject:op waitUntilDone:NO];
        }
    }
    else {
        [super observeValueForKeyPath: keyPath
                             ofObject: object
                               change: change
                               context: context];
    }
}


#pragma mark *** Overrides of NSWindowController Methods ***

- (void)setDocument:(NSDocument *)document {
    
    // Cocoa Bindings makes many things easier. Unfortunately, one of the things it makes easier is creation of reference counting cycles. In Mac OS 10.4 and later NSWindowController has a feature that keeps bindings to File's Owner, when File's Owner is a window controller, from retaining the window controller in a way that would prevent its deallocation. We're setting up bindings programmatically in -windowDidLoad though, so that feature doesn't kick in, and we have to explicitly unbind to make sure this window controller and everything in the nib it owns get deallocated. We do this here instead of in an override of -[NSWindowController close] because window controllers aren't sent -close messages for every kind of window closing. Fortunately, window controllers are sent -setDocument:nil messages during window closing.
    if (!document) {
        NSLog(@"setDocument");
        [_sequencesView unbind:MFSequenceViewSequencesBindingName];
        [_sequencesView unbind:MFSequenceViewForegroundColorBindingName];
        [_sequencesView unbind:MFSequenceViewBackgroundColorBindingName];
        [_sequencesView unbind:MFSequenceViewFontSizeBindingName];
        [_sequencesView unbind:MFSequenceViewSelectionIndexesBindingName];
        
        [_namesView unbind:@"selectionIndexes"];
        [_namesView unbind:@"sequences"];
        [_namesView unbind:@"fontSize"];
        [_namesView unbind:@"fontName"];
        [_namesView unbind:@"rowSpacing"];
        
        _speechSynthesizer.delegate = nil; // avoid circular references
    }
    
    [super setDocument:document];
}




#pragma mark *** Actions ***

// Conformance to the NSObject(NSMenuValidation) informal protocol.
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {

    BOOL enabled = NO;
    SEL action = [menuItem action];
    
    if (action == @selector(newDocumentWindow:)) {
        // Give the menu item that creates new sibling windows for this document a reasonably descriptive title. It's important to use the document's "display name" in places like this; it takes things like file name extension hiding into account. We could do a better job with the punctuation!
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"New window for '%@'", @"MenuItems", @"Formatter string for the new document window menu item. Argument is a the display name of the document."), [[self document] displayName]]];
        enabled = YES;
        
    }
    else if (action == @selector(increaseFont:) ) {
        enabled = YES;
    }
    else if ( action == @selector(decreaseFont:) ) {
        enabled = fontSize > 1;
    }
    else if (action == @selector(defaultFontSize:) ) {
        enabled = (fontSize != [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontSize"]floatValue]);
    }
    else if (action == @selector(complement:) || action==@selector(reverse:) ) {
        if( [[_sequencesController arrangedObjects] count] > 0 && [[_sequencesController selectedObjects]count] > 0  ){
            MFSequence *sequence = [[_sequencesController arrangedObjects]objectAtIndex:0];
            if( [[sequence dataType ]  isKindOfClass:[MFNucleotide class]] && ![sequence translated] ){
                enabled = YES;
            }
        }
    }
    else if (action == @selector(convertUT:) ) {
        if( [[_sequencesController arrangedObjects] count] > 0 ){
            MFSequence *sequence = [[_sequencesController arrangedObjects]objectAtIndex:0];
            if( [[sequence dataType] isKindOfClass:[MFNucleotide class]] && ![sequence translated] ){
                enabled = YES;
            }
        }
    }
    else if (action == @selector(translate:) ) {
        if( [[_sequencesController arrangedObjects] count] > 0 ){
            MFSequence *sequence = [[_sequencesController arrangedObjects]objectAtIndex:0];
            if( [[sequence dataType] isKindOfClass:[MFNucleotide class]] && ![sequence translated] ){
                enabled = YES;
            }
        }
    }
    else if (action == @selector(toggleTranslated:) ) {
        enabled = (([[_sequencesController arrangedObjects] count] > 0) && ([[[[_sequencesController arrangedObjects] objectAtIndex:0] dataType] isKindOfClass:[MFNucleotide class]] ));
    }
    else if (action == @selector(shiftRight:) ) {
        if( [[_sequencesController arrangedObjects] count] > 0 ){
            enabled = ![[[_sequencesController arrangedObjects]objectAtIndex:0]translated];
        }
    }
    else if (action == @selector(shiftLeft:) ) {
        if( [[_sequencesController arrangedObjects] count] > 0 ){
            enabled = ![[[_sequencesController arrangedObjects]objectAtIndex:0]translated];
        }
    }
    else if (action == @selector(selectAll:) ) {
        enabled = [[_sequencesController arrangedObjects] count] > 0;
    }
    else if (action == @selector(selectNone:) || action==@selector(invertSelection:) ) {
        enabled = [[_sequencesController selectionIndexes] count] > 0;
    }
    else if (action == @selector(startSpeaking:) ) {
        enabled =  (_sequencesView.rangeSelection.x.length != 0 && _sequencesView.rangeSelection.y.length == 1) || [[_sequencesController selectedObjects] count] == 1;
    }
    else if (action == @selector(stopSpeaking:) ) {
        enabled =  [_speechSynthesizer isSpeaking];
    }
    else if (action == @selector(rateSpeaking:) ) {
        enabled =  (_sequencesView.rangeSelection.x.length != 0 && _sequencesView.rangeSelection.y.length == 1) || [[_sequencesController selectedObjects] count] == 1;
    }
    else if (action == @selector(paste:) ) {
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        NSArray *objects = [pasteboard readObjectsForClasses:[NSArray arrayWithObject:[NSString class]] options:nil];
        enabled = [objects count] > 0;
    }
    else if (action == @selector(copy:) || action==@selector(cut:) || action==@selector(delete:) ) {
        enabled = [[_sequencesController selectedObjects] count] > 0 || !MFIsEmpty2DRange(_sequencesView.rangeSelection);
    }
    else if (action == @selector(deleteEmptyColumns:) ) {
        enabled = [[_sequencesController arrangedObjects] count] > 0;
    }
    else if (action == @selector(calculateDistanceMatrix:) ) {
        enabled = [[_sequencesController arrangedObjects] count] > 2 && !( [menuItem tag] > 0 && [self isAminoAcidFromFirstSequence]);
    }
    else if (action == @selector(neighborjoining:) ) {
        enabled = [[_sequencesController arrangedObjects] count] > 3;
    }
    else if (action == @selector(showBuildTreeSheet:) ) {
        enabled = [[_sequencesController arrangedObjects] count] > 3;
    }
    else if (action == @selector(showAlignerSheet:) ) {
        enabled = [[_sequencesController arrangedObjects] count] > 1;
    }
    else if (action == @selector(performFindPanelAction:) ){
        enabled = YES;
    }
    else if (action == @selector(find:) ){
        enabled = [[_searchField stringValue] length] > 0 && [[_sequencesController arrangedObjects] count] > 0;
        // deactivate Find All if we are in sequence mode
        if ( enabled && [menuItem tag] == 4 && _currentSearchTag == 1 ) {
            enabled = NO;
        }
    }
    else if (action == @selector(findFromSelection:) ){
        enabled = [[_searchField stringValue] length] > 0 && _currentSearchTag == 1 && [[_sequencesController arrangedObjects] count] > 0 && !MFIsEmpty2DRange(_sequencesView.rangeSelection) && _sequencesView.rangeSelection.y.length == 1;
    }
    else if (action == @selector(searchTypeMenuItem:) ) {
        [menuItem setState:([menuItem tag] == _currentSearchTag) ? NSOnState : NSOffState];
        enabled = [[_sequencesController arrangedObjects] count] > 0;
    }
    else if ([menuItem action] == @selector(datatypeAction:)){
        [menuItem setState:([menuItem tag] == [_dataTypeController selectionIndex]) ? NSOnState : NSOffState];
        if( [[_sequencesController arrangedObjects] count] > 0 ){
            MFSequence *sequence = [[_sequencesController arrangedObjects]objectAtIndex:0];
            enabled = !([[sequence dataType] isKindOfClass:[MFNucleotide class]] && [sequence translated]);
        }
    }
    else if ([menuItem action] == @selector(geneticCodeAction:)){
        [menuItem setState:([menuItem tag] == [_geneticCodeController selectionIndex]) ? NSOnState : NSOffState];
        enabled = YES;
    }
    else if ([menuItem action] == @selector(colorSchemeAction:)){
        if( [[_sequencesController arrangedObjects]count] > 0 ){
            [menuItem setState:([menuItem tag] == [_coloringController selectionIndex]) ? NSOnState : NSOffState];
            NSString *parentItemTitle = [[menuItem parentItem] title];
            NSString *currentDataType = [[[_dataTypeController selectedObjects]objectAtIndex:0]description];

            if([currentDataType isEqualToString:@"Nucleotide"] && [[[_sequencesController arrangedObjects]objectAtIndex:0]translated] && [parentItemTitle isEqualToString:@"Protein"]){
                enabled = YES;
            }
            else if([parentItemTitle isEqualToString:currentDataType] && !([currentDataType isEqualToString:@"Nucleotide"] && [[[_sequencesController arrangedObjects]objectAtIndex:0]translated])){
                enabled = YES;
            }
        }
        
    }
    else if (action == @selector(exportPDF:) ){
        enabled = [[_coloringController arrangedObjects] count] > 0;
    }
    else {
        enabled = [super validateMenuItem:menuItem];
    }
    return enabled;
    
}

- (IBAction)newDocumentWindow:(id)sender {
    
    // Do the same thing that a typical override of -[NSDocument makeWindowControllers] would do, but then also show the window.
    // This is here instead of in MFDocument, though it would work there too, with one small alteration, because it's really view-layer code.
    MFWindowController *windowController = [[MFWindowController alloc] init];
    [[self document] addWindowController:windowController];
    [windowController showWindow:self];
    [windowController release];
    
}

- (IBAction)increaseFont:(id)sender {
    self.fontSize = fontSize+1;
}

- (IBAction)decreaseFont:(id)sender {
    if(fontSize > 1){
        self.fontSize = fontSize-1;
    }
}

- (IBAction)defaultFontSize:(id)sender {
    self.fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontSize"]floatValue];

}

- (IBAction)selectAll:(id)sender {
    NSUInteger count = [[_sequencesController arrangedObjects] count];
    if( count > 0 ){
        [_sequencesController setSelectionIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, count)]];
    }
}

- (IBAction)selectNone:(id)sender {
    NSUInteger count = [[_sequencesController selectionIndexes] count];
    if( count > 0 ){
        [_sequencesController setSelectionIndexes:[NSIndexSet indexSet]];
    }
}

-(IBAction)invertSelection:(id)sender{
    if([[_sequencesController selectedObjects] count] > 0 ){
        NSIndexSet *indexes = [_sequencesController selectionIndexes];
        NSMutableIndexSet *newIndexes = [[NSMutableIndexSet alloc]init];
        
        for (NSUInteger i = 0; i < [[_sequencesController arrangedObjects]count]; i++) {
            if( ![indexes containsIndex:i] ){
                [newIndexes addIndex:i];
            }
        }
    
        [_sequencesController setSelectionIndexes:newIndexes];
        [newIndexes release];
    }
}

- (IBAction)deleteEmptyColumns:(id)sender {
    
    NSArray *sequences = [_sequencesController arrangedObjects];
    NSUInteger count = [sequences count];
    if( count > 0 ){
        
        NSMutableIndexSet *indexes = [[NSMutableIndexSet alloc] init];
        NSUInteger nSites = [MFSequenceUtils maxLength:sequences];
        for (NSUInteger i = 0; i < nSites; i++) {
            NSUInteger j = 0;
            for (MFSequence *sequence in sequences) {
                if( [sequence residueAt:i] != '-' ){
                    break;
                }
                j++;
            }
            if( j == [sequences count] ){
                [indexes addIndex:i];
            }
        }
        [self deleteGaps:[_sequencesController arrangedObjects] atIndexes:indexes];
        [indexes release];
        _sequencesView.rangeSelection = MFMakeEmpty2DRange();
    }
}

- (IBAction)reverse:(id)sender {
    if( [[_sequencesController arrangedObjects]count] > 0 && ![[[_sequencesController arrangedObjects]objectAtIndex:0]translated] ){
        NSUInteger count = [[_sequencesController selectionIndexes] count];
        if( count > 0 ){
            NSUndoManager *undoManager = [[self document]undoManager];
            NSIndexSet *indexes = [_sequencesController selectionIndexes];
            [self reverseSequencesAtIndexes: indexes];
            [[undoManager prepareWithInvocationTarget:self] reverseSequencesAtIndexes:indexes];
            [undoManager setActionName:@"Reverse"];
        }
    }
}

- (IBAction)complement:(id)sender {
    if( [[_sequencesController arrangedObjects]count] > 0 && ![[[_sequencesController arrangedObjects]objectAtIndex:0]translated] ){
        NSUInteger count = [[_sequencesController selectionIndexes] count];
        if( count > 0 ){
            NSUndoManager *undoManager = [[self document]undoManager];
            NSIndexSet *indexes = [_sequencesController selectionIndexes];
            [self complementSequencesAtIndexes: indexes];
            
            [[undoManager prepareWithInvocationTarget:self] complementSequencesAtIndexes:indexes];
            [undoManager setActionName:@"Complement"];
        }
    }
}

-(IBAction)convertUT:(id)sender{
    if( [[_sequencesController arrangedObjects]count] > 0 && ![[[_sequencesController arrangedObjects]objectAtIndex:0]translated] ){
        
        NSUndoManager *undoManager = [[self document]undoManager];
        // T -> U
        if( [sender tag] == 0 ){
            [self convertTtoU];
            [[undoManager prepareWithInvocationTarget:self]convertUtoT];
            [undoManager setActionName:@"Convert T -> U"];
        }
        // U -> T
        else {
            [self convertUtoT];
            [[undoManager prepareWithInvocationTarget:self]convertTtoU];
            [undoManager setActionName:@"Convert U -> T"];
            
        }
    }
}

- (IBAction)shiftRight:(id)sender {
    
    NSUInteger count = [[_sequencesController arrangedObjects] count];
    if( count > 0 ){
        NSUInteger numberOfEmpties = [MFSequenceUtils numberOfEmptyColumnsAtFront:[_sequencesController arrangedObjects]];
        if( numberOfEmpties < 2 ){
            [self sequencesView:_sequencesView insertGaps:1 inSequenceRange:NSMakeRange(0, count) atIndex:0];
        }
    }
}

- (IBAction)shiftLeft:(id)sender {
    
    NSUInteger count = [[_sequencesController arrangedObjects] count];
    if( count > 0 && [MFSequenceUtils isStartingWithOneGap:[_sequencesController arrangedObjects]] ){
        [self sequencesView:_sequencesView deleteGaps:NSMakeRange(0, 1) inSequenceRange:NSMakeRange(0, count)];
    }
}

-(IBAction)startSpeaking:(id)sender{
    if( [_speechSynthesizer isSpeaking] ){
        [_speechSynthesizer stopSpeaking];
    }
    else {
        if( _sequencesView.rangeSelection.x.length != 0 && _sequencesView.rangeSelection.y.length == 1 ){
            MFSequence *sequence = [[_sequencesController arrangedObjects] objectAtIndex:_sequencesView.rangeSelection.y.location];
            [_speechSynthesizer startSpeakingString: [sequence subSequenceWithRange:_sequencesView.rangeSelection.x]];
            //NSLog(@"%@",[sequence subSequenceWithRange:_sequencesView.rangeSelection.x]);
        }
        else if ( [[_sequencesController selectedObjects] count] == 1 ){
            MFSequence *sequence = [[_sequencesController arrangedObjects] objectAtIndex:[_sequencesController selectionIndex]];
            [_speechSynthesizer startSpeakingString: [sequence subSequenceWithRange:NSMakeRange(0, [sequence length])]];
            //NSLog(@"%@",[sequence subSequenceWithRange:NSMakeRange(0, [sequence length])]);
        }
    }
}


-(IBAction)stopSpeaking:(id)sender{
    [_speechSynthesizer stopSpeaking];
}

-(IBAction)rateSpeaking:(id)sender{
    // Slower
    if ( [sender tag] == 0) {
        [_speechSynthesizer setRate: [_speechSynthesizer rate]-10.0];
    }
    else{
        [_speechSynthesizer setRate: [_speechSynthesizer rate]+10.0];
    }
}

- (IBAction)searchTypeMenuItem:(id)sender{
    if( [sender tag] != _currentSearchTag ){
        _searchSite = NSNotFound;
        _searchSequence = NSNotFound;
        _currentSearchTag = [sender tag];
    }
}

-(IBAction)performFindPanelAction:(id)sender{
    
}

// Use selection for find
-(IBAction)findFromSelection:(id)sender{
    
}

- (IBAction)find:(id)sender {
    NSString *searchKey = [_searchField stringValue];
    
    // Find All
    if ( [sender tag] == 4 && _currentSearchTag == 0) {
        [self findKeyInAllNames:searchKey];
    }
    // Find
    else if( [sender tag] == 1 ){
        return;
    }
    // Find Next || Previous in sequence names
    else if( ([sender tag] == 2 || [sender tag] == 3 || [sender isKindOfClass:[NSSearchField class]]) && _currentSearchTag == 0 ){
        BOOL success;
        // Find Next
        if ( [sender tag] == 2 || [sender isKindOfClass:[NSSearchField class]] ) {
            success = [self findKeyInNames:searchKey];
        }
        // Find Previous
        else{
            success = [self findKeyInNamesBackwards:searchKey];
        }
        if( success ){
            [_sequencesController setSelectionIndex:_searchSequence];
        }
    }
    // Find Next || Previous in sequences
    else if( ([sender tag] == 2 || [sender tag] == 3 || [sender isKindOfClass:[NSSearchField class]]) && _currentSearchTag == 1 ){
        BOOL success;
        // Find Next
        if ( [sender tag] == 2 || [sender isKindOfClass:[NSSearchField class]] ) {
            success = [self findKeyInSequence:searchKey];
        }
        // Find Previous
        else{
            success = [self findKeyInSequencePrevious:searchKey];
        }
    
        if( success ){
            MF2DRange rangeSelection = MFMake2DRange(_searchSite, [searchKey length], _searchSequence, 1);
            _sequencesView.rangeSelection = rangeSelection;
            NSPoint point;
            point.x = _searchSite*_sequencesView.residueWidth;
            point.y = _searchSequence*(_sequencesView.residueHeight+_rowSpacing)+_rowSpacing;
            
            NSSize viewSize = [[_sequencesScrollView contentView] bounds].size;
            
            NSUInteger sizeWidth  = _sequencesView.residueWidth  * [MFSequenceUtils maxLength:[_sequencesController arrangedObjects]];
            NSUInteger sizeHeight = [[_sequencesController arrangedObjects]count]*(_sequencesView.residueHeight+_rowSpacing)+_rowSpacing;
            
            // there are not enough sequences to fill the contentView
            if(sizeHeight <= viewSize.height){
                point.y = 0;
            }
            // too close to the top to be centered
            else if( point.y < viewSize.height/2){
                point.y = 0;
            }
            // too close to the bottom to be centered
            else if( viewSize.height > sizeHeight - point.y ){
                point.y -= viewSize.height - sizeHeight + point.y;
            }
            // can be centered
            else {
                point.y -= viewSize.height/2;
            }
            
            // there are not enough sites to fill the contentView
            if(sizeWidth <= viewSize.width){
                point.x = 0;
            }
            // too close to the left side to be centered
            else if( point.x < viewSize.width/2){
                point.x = 0;
            }
            // too close to the end to be centered
            else if( viewSize.width > sizeWidth - point.x ){
                point.x -= viewSize.width - sizeWidth + point.x;
            }
            // can be centered
            else {
                point.x -= viewSize.width/2;
            }
            [_sequencesView setNeedsDisplay:YES];
            [[_sequencesScrollView contentView] scrollToPoint:point];
            // we have to tell the NSScrollView to update its scrollers
            [_sequencesScrollView reflectScrolledClipView:[_sequencesScrollView contentView]];
        }
    }
}

-(IBAction)copy:(id)sender{
    if( [[_sequencesController selectedObjects] count] > 0 ){
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        MFSequenceSet *set = [[MFSequenceSet alloc]initWithSequences:[_sequencesController selectedObjects]];
        NSString *str = [MFSequenceWriter string:set withFormat:MFSequenceFormatNEXUS attributes:nil];
        NSArray *array = [NSArray arrayWithObject:str];
        [pasteboard writeObjects:array];
        [set release];
    }
}

- (IBAction)cut:(id)sender {
    [self copy:sender];
    [self delete:sender];
    [[self undoManager] setActionName:NSLocalizedStringFromTable(@"Cut", @"UndoStrings", @"Action name for cut.")];
}

-(IBAction)paste:(id)sender{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSDictionary *options = [NSDictionary dictionary];
    
    NSArray *classArrayNSURL    = [NSArray arrayWithObject:[NSURL class]];
    NSArray *classArrayNSString = [NSArray arrayWithObject:[NSString class]];
    
    
    NSMutableArray *alignments = [[NSMutableArray alloc]init];
    
    // URL
    if( [pasteboard canReadObjectForClasses:classArrayNSURL options:options] ){
        NSArray *objects = [pasteboard readObjectsForClasses:classArrayNSURL options:options];
        
        for ( NSURL *url in objects) {
            MFSequenceSet *sequenceSet = [MFSequenceReader readSequencesFromURL:url];
            if( sequenceSet != nil ){
                [[self document] setFileFormat:[sequenceSet annotationForKey:MFSequenceFileFormat]];
                [alignments addObject:[sequenceSet sequences]];
            }
        }
    }
    // NSString
    else if( [pasteboard canReadObjectForClasses:classArrayNSString options:options] ){
        NSArray *objects = [pasteboard readObjectsForClasses:classArrayNSString options:options];
        
        for ( NSString *str in objects) {
            MFSequenceSet *sequenceSet = [MFSequenceReader readSequencesFromString:str];
            if( sequenceSet != nil ){
                [[self document] setFileFormat:[sequenceSet annotationForKey:MFSequenceFileFormat]];
                [alignments addObject:[sequenceSet sequences]];
            }
        }
    }
    if( [alignments count] > 0 ){
        [self loadAlignments:alignments];
    }
    
    [alignments release];
}

- (IBAction)delete:(id)sender {
    if( [[_sequencesController selectedObjects] count] != 0 ){
        [_sequencesController removeObjectsAtArrangedObjectIndexes:[_sequencesController selectionIndexes]];
        //[[self document]removeSequencesAtIndexes:[_sequencesController selectionIndexes]];
        [[[self document] undoManager] setActionName:NSLocalizedStringFromTable(@"Delete", @"UndoStrings", @"Action name for deletions.")];
    }
    //    else if( [_siteSelectionIndexes count] != 0 ){
    //
    //    }
    else if( !MFIsEmpty2DRange(_sequencesView.rangeSelection) ){
        MF2DRange rangeSelection = _sequencesView.rangeSelection;
        // the whole sequence is selected
        if(rangeSelection.x.length == [self numberOfSites] ){
            [_sequencesController removeObjectsAtArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(rangeSelection.y.location, rangeSelection.y.length)]];
            [[[self document] undoManager] setActionName:NSLocalizedStringFromTable(@"Delete", @"UndoStrings", @"Action name for deletions.")];
        }
        else{
            [self sequencesView:_sequencesView removeSitesInRange:rangeSelection.x inSequenceRange:rangeSelection.y];
            [_sequencesView updateFrameSize];
        }
        _sequencesView.rangeSelection = MFMakeEmpty2DRange();
    }
}

// translate the alignment (not reversible)
- (IBAction)translate:(id)sender {
    if( [[_sequencesController arrangedObjects]count] > 0 && [[[[_sequencesController arrangedObjects]objectAtIndex:0]dataType] isKindOfClass:[MFNucleotide class]]  ){
        for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
            sequence.dataType = [_dataTypes objectAtIndex:1];
            [sequence setGeneticTable:_geneticTable];
            [sequence setTranslated:NO ];
            [sequence translateFinal];
        }
        [_dataTypeController setSelectionIndex:1];
        
        NSMutableArray *newSchemes = [self loadColorSchemes:@"Amino acid"];
        [self setUpColoring:_aaColoringDescription datatype:@"Amino acid"];
        
        [self willChangeValueForKey:@"colorSchemes"];
        [_colorSchemes replaceObjectsInRange:NSMakeRange(0, [_colorSchemes count]) withObjectsFromArray:newSchemes];
        [self didChangeValueForKey:@"colorSchemes"];
        
        [_coloringController setSelectionIndex:[_colorSchemes indexOfObject:_aaColoringDescription]];
        
        [[[self document]undoManager] removeAllActions];
        [[self document] updateChangeCount:NSChangeDone];
    }
}


- (IBAction)toggleTranslated:(id)sender {
    // new value
    BOOL isTranslated = ![[[_sequencesController arrangedObjects]objectAtIndex:0]translated];
    [self setTranslated:isTranslated];
}

- (IBAction)datatypeAction:(id)sender{
    [_dataTypeController setSelectionIndex:[sender tag]];
}

- (IBAction)geneticCodeAction:(id)sender{
    [_geneticCodeController setSelectionIndex:[sender tag]];
}

- (IBAction)colorSchemeAction:(id)sender{
    [_coloringController setSelectionIndex:[sender tag]];
}


- (IBAction)exportPDF:(id)sender{
    
    NSString *name = [self.document fileURL].lastPathComponent;
    NSString* newName = @"Untitled.pdf";
    if ( name ) {
        newName = [[name stringByDeletingPathExtension] stringByAppendingPathExtension:@"pdf"];
    }
    
    // Set the default name for the file and show the panel.
    NSSavePanel*    panel = [NSSavePanel savePanel];
    [panel setNameFieldStringValue:newName];
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton){
            NSURL*  theFile = [panel URL];
            NSRect r = [_sequencesView bounds];
            NSData *data = [_sequencesView dataWithPDFInsideRect:r];
            
            [data writeToURL:theFile atomically:YES];
        }
    }];
}

- (IBAction)showGeneticCode:(id)sender{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSInformationalAlertStyle];
    [alert setMessageText:@"Select a genetic code"];
    [alert addButtonWithTitle:@"Close"];
    
    NSPopUpButton * tmpPopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    
    [tmpPopup bind:@"selectedIndex" toObject:_geneticCodeController withKeyPath:@"selectionIndex" options:nil];
    [tmpPopup bind:@"content" toObject:_geneticCodeController withKeyPath:@"arrangedObjects" options:nil];
    
    [alert setAccessoryView:tmpPopup];
    [tmpPopup release];

    [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
        if (result == NSAlertFirstButtonReturn) {
            [tmpPopup unbind:@"selectedIndex"];
            [tmpPopup unbind:@"content"];
        }
    }];
    [alert release];

}

#pragma mark *** Private Methods ***

-(void)deleteGaps:(NSArray*)sequences atIndexes:(NSIndexSet*)indexes{
    NSUndoManager *undoManager = [[self document]undoManager];
    
    for (MFSequence *sequence in sequences ) {
        [sequence deleteResiduesAtIndexes:indexes];
    }
    [[undoManager prepareWithInvocationTarget:self] insertGaps:sequences atIndexes:indexes];
    [undoManager setActionName:@"Deletion"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}

-(void)insertGaps:(NSArray*)sequences atIndexes:(NSIndexSet*)indexes{
    NSUndoManager *undoManager = [[self document]undoManager];
    
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        for (MFSequence *sequence in sequences ) {
            [sequence insertGaps:1 AtIndex:idx];
        }
    }];
    [[undoManager prepareWithInvocationTarget:self] deleteGaps:sequences atIndexes:indexes];
    [undoManager setActionName:@"Insertion"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}

-(void)reverseSequencesAtIndexes:(NSIndexSet*) indexes{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [[[_sequencesController arrangedObjects] objectAtIndex:idx] reverse];
    }];
    [_sequencesView setNeedsDisplay:YES];
}

-(void)complementSequencesAtIndexes:(NSIndexSet*) indexes{
    [indexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
        [[[_sequencesController arrangedObjects] objectAtIndex:idx] complement];
    }];
    [_sequencesView setNeedsDisplay:YES];
}

-(void)convertTtoU{
    if( [[_sequencesController arrangedObjects]count] > 0 ){
        NSRange range = NSMakeRange(0, [[[_sequencesController arrangedObjects]objectAtIndex:0]length]);
        [[_sequencesController arrangedObjects]enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            MFSequence *seq = obj;
            [seq replaceOccurencesOfString:@"T" withString:@"U" options:NSCaseInsensitiveSearch range:range];
        }];
        [_sequencesView setNeedsDisplay:YES];
    }
}

-(void)convertUtoT{
    if( [[_sequencesController arrangedObjects]count] > 0 ){
        NSRange range = NSMakeRange(0, [[[_sequencesController arrangedObjects]objectAtIndex:0]length]);
        [[_sequencesController arrangedObjects]enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            MFSequence *seq = obj;
            [seq replaceOccurencesOfString:@"U" withString:@"T" options:NSCaseInsensitiveSearch range:range];
        }];
        [_sequencesView setNeedsDisplay:YES];
    }
}

-(void)loadAlignments:(NSArray*)alignments{
    
    MFDataType *dataType = nil;
    if( [[_sequencesController arrangedObjects]count] > 0 ){
        dataType = [[[_sequencesController arrangedObjects]objectAtIndex:0]dataType];
    }
    //empty window
    else {
        MFSequenceSet *set = [[MFSequenceSet alloc]initWithSequences:[alignments objectAtIndex:0]];
        
        for (MFSequence *sequence in [set sequences]) {
            if( [sequence dataType] != nil ){
                dataType = [sequence dataType];
                break;
            }
        }
        if( dataType == nil ){
            dataType = [set guessDataType];
        }
        [set release];
    }
    
    if( ([alignments count]  >= 1 && [[_sequencesController arrangedObjects]count] >  0)
       || ([alignments count] > 1 && [[_sequencesController arrangedObjects]count] == 0) ){
        
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setInformativeText:[NSString stringWithFormat:@"Do you want to append or concatenate these %tu files?", [alignments count]]];
        [alert setMessageText:@"Reading multiple files"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Append"];
        if ( [self isConcatenable:alignments])[alert addButtonWithTitle:@"Concatenate"];
        
        
        [alert beginSheetModalForWindow:[self window] completionHandler:^(NSInteger result) {
            // Cancel
            if (result == NSAlertFirstButtonReturn) {
                //NSLog(@"Cancel");
            }
            // Append
            else if (result == NSAlertSecondButtonReturn) {
                
                for (NSArray *sequences in alignments) {
                    NSUInteger count = [[_sequencesController arrangedObjects]count];
                    [_sequencesController insertObjects:sequences atArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(count, [sequences count])]];
                }
                [MFSequenceUtils pad:[_sequencesController arrangedObjects]];
            
                //[self setSequencesDataTypeByIndex:[[dataType index]intValue]];
                [self setSequencesDataType:dataType];
            }
            else if (result == NSAlertThirdButtonReturn) {
                [self concatenate:alignments];
                [MFSequenceUtils pad:[_sequencesController arrangedObjects]];
            
                //[self setSequencesDataTypeByIndex:[[dataType index]intValue]];
                [self setSequencesDataType:dataType];
            }
        }];
        
        [alert release];
    }
    else {
        NSUInteger count = [[_sequencesController arrangedObjects]count];
        NSArray *sequences = [alignments objectAtIndex:0];
        [MFSequenceUtils pad:sequences];
        [_sequencesController insertObjects:sequences atArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(count, [sequences count])]];
        
        
        //[self setSequencesDataTypeByIndex:[[dataType index]intValue]];
        [self setSequencesDataType:dataType];
    }
}

-(BOOL)isConcatenable:(NSArray*)alignments{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    NSUInteger i = 0;
    if( [[_sequencesController arrangedObjects]count] > 0 ){
        for (MFSequence *sequence in [_sequencesController arrangedObjects]) {
            [dict setObject:sequence forKey:[sequence name]];
        }
        
    }
    else {
        for (MFSequence *sequence in [alignments objectAtIndex:0]) {
            [dict setObject:sequence forKey:[sequence name]];
        }
        i = 1;
    }
    
    for ( ; i < [alignments count]; i++ ) {
        for (MFSequence *sequence in [alignments objectAtIndex:i]) {
            if( ![dict objectForKey:[sequence name]] ){
                [dict release];
                return NO;
            }
        }
    }

    [dict release];
    return YES;
}

// concatenate sequence sets in alignment
-(void)concatenate:(NSArray*)alignments{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    
    if( [[_sequencesController arrangedObjects]count] == 0 ){
        NSArray *sequences = [alignments  objectAtIndex:0];
        
        for (MFSequence *sequence in sequences) {
            [dict setObject:sequence forKey:[sequence name]];
        }
        
        for ( NSUInteger i = 1; i < [alignments count]; i++ ) {
            for ( MFSequence *sequence in [alignments objectAtIndex:i] ) {
                MFSequence *seq = [dict objectForKey:[sequence name]];
                [seq concatenateString:[sequence sequenceString]];
            }
        }
        
        [_sequencesController insertObjects:sequences atArrangedObjectIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [sequences count])]];
        [[[self document] undoManager] setActionName:NSLocalizedStringFromTable(@"Paste", @"UndoStrings", @"Action name for paste.")];
    }
    else {
        
        for (MFSequence *sequence in [_sequencesController arrangedObjects]) {
            [dict setObject:sequence forKey:[sequence name]];
        }
        NSUInteger len = [[[_sequencesController arrangedObjects] objectAtIndex:0]length];
        NSUInteger len2 = 0;
        for ( NSUInteger i = 0; i < [alignments count]; i++ ) {
            len2 += [[[alignments objectAtIndex:0]objectAtIndex:0]length];
            for ( MFSequence *sequence in [alignments objectAtIndex:i] ) {
                MFSequence *seq = [dict objectForKey:[sequence name]];
                [seq concatenateString:[sequence sequenceString]];
            }
        }
        [[[[self document] undoManager] prepareWithInvocationTarget:self] sequencesView:nil removeSitesInRange: NSMakeRange(len, len2) inSequenceRange: NSMakeRange(0, [[_sequencesController arrangedObjects] count])];
        [[[self document] undoManager] setActionName:@"Remove concatenated sequences"];
        // need update of the views
    }
    
    [dict release];
}

// Overrides of the NSResponder(NSStandardKeyBindingMethods) methods.
- (void)deleteBackward:(id)sender {
    [self delete:sender];
}

- (void)deleteForward:(id)sender {
    [self delete:sender];
}

-(NSUInteger)numberOfSites{
    NSUInteger maxLength = 0;
    for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
        if( [sequence length] > maxLength ){
            maxLength = [sequence length];
        }
    }
    return maxLength;
}

-(BOOL)isNucleotideFromFirstSequence{
    return [[[[_sequencesController arrangedObjects]objectAtIndex:0]dataType] isKindOfClass:[MFNucleotide class]];
}

-(BOOL)isAminoAcidFromFirstSequence{
    return [[[[_sequencesController arrangedObjects]objectAtIndex:0]dataType] isKindOfClass:[MFProtein class]];
}

#pragma mark Search

-(BOOL)findKeyInSequence:(NSString*)searchKey{
    if( [searchKey length] > 0 ){
        if( _searchSequence == [[_sequencesController arrangedObjects] count] || (_searchSite == NSNotFound && _searchSequence == NSNotFound) ){
            _searchSequence = 0;
            _searchSite = 0;
        }
        else {
            if ( _sequencesView.rangeSelection.x.length != 0 ) {
                _searchSite = _sequencesView.rangeSelection.x.location;
                _searchSequence = _sequencesView.rangeSelection.y.location;
            }
            _searchSite++;
        }
        
        NSArray *sequences = [_sequencesController arrangedObjects];
        for ( ; _searchSequence < [sequences count]; _searchSequence++ ) {
            MFSequence *sequence = [sequences objectAtIndex:_searchSequence];
            
            NSRange match = [[sequence sequenceString] rangeOfString:searchKey options:NSCaseInsensitiveSearch range:NSMakeRange(_searchSite, [sequence length] -_searchSite)];
            if(match.location != NSNotFound){
                _searchSite = match.location;
                return YES;
            }
            _searchSite = 0;
        }
    }
    _searchSite = NSNotFound;
    _searchSequence = NSNotFound;
    return NO;
}

-(BOOL)findKeyInSequencePrevious:(NSString*)searchKey{
    if( [searchKey length] > 0 ){
        NSArray *sequences = [_sequencesController arrangedObjects];
        
        if( _searchSequence == -1 || (_searchSite == NSNotFound && _searchSequence == NSNotFound) ){
            _searchSequence = [sequences count]-1;
            _searchSite = [self numberOfSites];
        }
        else {
            if ( _sequencesView.rangeSelection.x.length != 0 ) {
                _searchSite = _sequencesView.rangeSelection.x.location;
                _searchSequence = _sequencesView.rangeSelection.y.location;
            }
            _searchSite--;
        }
        
        for ( ; _searchSequence >= 0; _searchSequence-- ) {
            MFSequence *sequence = [sequences objectAtIndex:_searchSequence];
            
            NSRange match = [[sequence sequenceString] rangeOfString:searchKey options:(NSBackwardsSearch|NSCaseInsensitiveSearch) range:NSMakeRange(0, _searchSite)];
            if(match.location != NSNotFound){
                _searchSite = match.location;
                return YES;
            }
            _searchSite = 0;
        }
    }
    _searchSite = NSNotFound;
    _searchSequence = NSNotFound;
    
    return NO;
}

-(BOOL)findKeyInNames:(NSString*)searchKey{
    if( [searchKey length] > 0 ){
        if( _searchSequence == NSNotFound ){
            // we reach the end, restart from the beginning
            if( _searchSequence == [[_sequencesController arrangedObjects] count] ){
                _searchSequence = 0;
            }
            // initial selection
            else if( [[_sequencesController selectedObjects] count] == 1 ){
                _searchSequence = [_sequencesController selectionIndex];
            }
            // no initial selection
            else {
                _searchSequence = 0;
            }
        }
        else {
            _searchSequence++;
        }
        
        NSArray *sequences = [_sequencesController arrangedObjects];
        for ( ; _searchSequence < [sequences count]; _searchSequence++ ) {
            MFSequence *sequence = [sequences objectAtIndex:_searchSequence];
            NSRange match = [[sequence name] rangeOfString:searchKey options:NSCaseInsensitiveSearch range:NSMakeRange(0, [[sequence name]length])];
            if(match.location != NSNotFound){
                return YES;
            }
        }
    }
    // empty selection
    [_sequencesController setSelectionIndexes:[NSIndexSet indexSet]];
    _searchSite = NSNotFound;
    _searchSequence = NSNotFound;
    return NO;
}

-(BOOL)findKeyInNamesBackwards:(NSString*)searchKey{
    if( [searchKey length] > 0 ){
        NSArray *sequences = [_sequencesController arrangedObjects];
        if( _searchSequence == NSNotFound ){
            // we reach the beginning, restart from the beginningend
            if( _searchSequence == -1 ){
                _searchSequence = [sequences count]-1;
            }
            // initial selection
            else if( [[_sequencesController selectedObjects] count] == 1 ){
                _searchSequence = [_sequencesController selectionIndex];
            }
            // no initial selection
            else {
                _searchSequence = [sequences count]-1;
            }
        }
        else {
            _searchSequence--;
        }
        
        for ( ; _searchSequence >= 0; _searchSequence-- ) {
            MFSequence *sequence = [sequences objectAtIndex:_searchSequence];
            NSRange match = [[sequence name] rangeOfString:searchKey options:NSCaseInsensitiveSearch range:NSMakeRange(0, [[sequence name]length])];
            if(match.location != NSNotFound){
                return YES;
            }
        }
    }
    // empty selection
    [_sequencesController setSelectionIndexes:[NSIndexSet indexSet]];
    _searchSite = NSNotFound;
    _searchSequence = NSNotFound;
    return NO;
}

-(void)findKeyInAllNames:(NSString*)searchKey{
    
    if( [searchKey length] > 0 ){
        NSMutableIndexSet *indexes = [NSMutableIndexSet indexSet];
        NSArray *sequences = [_sequencesController arrangedObjects];
        for ( NSUInteger i =0 ; i < [sequences count]; i++ ) {
            MFSequence *sequence = [sequences objectAtIndex:i];
            NSRange match = [[sequence name] rangeOfString:searchKey options:NSCaseInsensitiveSearch range:NSMakeRange(0, [[sequence name]length])];
            if(match.location != NSNotFound){
                [indexes addIndex:i];
            }
        }
        [_sequencesController setSelectionIndexes:indexes];
    }
    _searchSite     = NSNotFound;
    _searchSequence = NSNotFound;
}

- (void)controlTextDidChange:(NSNotification *)notification {
    //NSSearchField *searchField = [notification object];
    //NSLog(@"%@", [searchField stringValue] );
    _searchSequence = NSNotFound;
    _searchSite =  NSNotFound;
}

#pragma mark Translation

// lazyly translate the alignment (reversible)
-(void)setTranslated:(BOOL)isTranslated{
    
    // group undo
    for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
        [sequence setTranslated:isTranslated];
        [sequence setGeneticTable:_geneticTable]; // it might be not needed every time but it does not hurt
    }
    
    if(!isTranslated) [MFSequenceUtils pad:[_sequencesController arrangedObjects] ];
    
    
    for (NSMenuItem *item in [_dataTypePopUp itemArray]) {
        [item setEnabled:!isTranslated];
    }

    NSMutableArray *newSchemes;
    NSString *scheme;
    if( isTranslated ){
        newSchemes = [self loadColorSchemes:@"Amino acid"];
        scheme = _aaColoringDescription;
        [self setUpColoring:_aaColoringDescription datatype:@"Amino acid"];
    }
    else {
        newSchemes = [self loadColorSchemes:@"Nucleotide"];
        scheme = _nucleotideColoringDescription;
        [self setUpColoring:_nucleotideColoringDescription datatype:@"Nucleotide"];
    }
    
    [self willChangeValueForKey:@"colorSchemes"];
    [_colorSchemes replaceObjectsInRange:NSMakeRange(0, [_colorSchemes count]) withObjectsFromArray:newSchemes];
    [self didChangeValueForKey:@"colorSchemes"];
    
    
    [_coloringController setSelectionIndex:[_colorSchemes indexOfObject:scheme]];
    
    // we want to be able to see the selection
    
    NSUInteger maximumNumberOfSites =  [MFSequenceUtils maxLength:[_sequencesController arrangedObjects]];
    NSUInteger numberOfSequences = [[_sequencesController arrangedObjects] count];
    NSSize size;
    size.width  = _sequencesView.residueWidth  * maximumNumberOfSites;
    size.height = (_sequencesView.residueHeight+_rowSpacing) * numberOfSequences + _rowSpacing;
    
    [_sequencesView setFrameSize:size];
    
    NSPoint point   = [[_sequencesScrollView contentView] bounds].origin;
    // From dna to amino acid
    if( isTranslated ){
        point.x /= 3;
    }
    else{
        point.x *= 3;
    }
    
    [[_sequencesScrollView contentView] scrollToPoint:point];
    // we have to tell the NSScrollView to update its scrollers
    [_sequencesScrollView reflectScrolledClipView:[_sequencesScrollView contentView]];
    
    
    [[[[self document]undoManager] prepareWithInvocationTarget:self] setTranslated:!isTranslated];
    [[[self document]undoManager] setActionName:@"Translate"];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:MFTranslationDidChangeNotification object:self];
}

#pragma mark Genetic code

// Called once when MFWindowController is init
-(NSArray*)loadGeneticCodes{
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"GeneticCodeTables"];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSMutableArray *mutableArray = [[NSMutableArray alloc]init];
    
    for ( NSString *file in dirFiles) {
        if ( [file hasSuffix:@"plist"] ) {
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
            [mutableArray addObject:[dict objectForKey:@"Description"]];
            [dict release];
        }
    }
    return [mutableArray autorelease];
}

// Called every time we change the genetic code
-(void)setUpGeneticTable{
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"GeneticCodeTables"];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSString *geneticCode = [[_geneticCodeController selectedObjects]objectAtIndex:0];
    for ( NSString *file in dirFiles) {
        if ( [file hasSuffix:@"plist"] ) {
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
            if( [[dict objectForKey:@"Description"] isEqualToString:geneticCode]){
                [_geneticTable setDictionary:[dict objectForKey:@"Table"]];
                
                // genetic codes in plists are only set with ACTG and do not contain U
                // add codons with Us to the _geneticTable dictionary
                for (NSString *code in [_geneticTable allKeys]) {
                    if( [code rangeOfString:@"T" options:NSCaseInsensitiveSearch].location != NSNotFound ){
                        NSString *ucode =[code stringByReplacingOccurrencesOfString:@"T" withString:@"U"];
                        [_geneticTable setObject:[_geneticTable objectForKey:code] forKey:ucode];
                    }
                }
                [dict release];
                break;
            }
            [dict release];
        }
    }
}


#pragma mark Coloring

-(NSMutableArray*)loadColorSchemes:(NSString*)type{
    NSMutableArray *colorSchemes = [[NSMutableArray alloc]init];
    NSString *userPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:_coloringFolder]stringByAppendingPathComponent:type];
    NSArray *schemes = [MFColorManager colorSchemesAtPath:userPath];
    [colorSchemes addObjectsFromArray:schemes];
    
    NSError *error = nil;
    NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if(!error){
        NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
        NSString *appPath = [[[appSupportDir path] stringByAppendingPathComponent:[executableName stringByAppendingPathComponent:_coloringFolder]]stringByAppendingPathComponent:type];
        NSArray *schemes = [MFColorManager colorSchemesAtPath:appPath];
        [colorSchemes addObjectsFromArray:schemes];
    }
    return [colorSchemes autorelease];
}

-(void)setUpColoring:(NSString *)scheme{
    
    if( [[_sequencesController arrangedObjects] count] == 0
       || ( [[[[_sequencesController arrangedObjects]objectAtIndex:0]dataType ] isKindOfClass:[MFNucleotide class]] && ![[[_sequencesController arrangedObjects]objectAtIndex:0]translated]) ){
        [self setUpColoring:scheme datatype:@"Nucleotide"];
    }
    else {
        [self setUpColoring:scheme datatype:@"Amino acid"];
    }
}

-(void)setUpColoring:(NSString*)scheme datatype:(NSString*)type{
    NSString *userPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:_coloringFolder]stringByAppendingPathComponent:type];
    
    NSError *error;
    NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSString *appPath = [[[appSupportDir path] stringByAppendingPathComponent:[executableName stringByAppendingPathComponent:_coloringFolder]]stringByAppendingPathComponent:type];
    
    BOOL found = [self setUpColoring:scheme fromPath:userPath];
    if (!found) {
        [self setUpColoring:scheme fromPath:appPath];
    }
}

-(BOOL)setUpColoring:(NSString*)type fromPath:(NSString*)path{
    NSError *error = nil;
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    if(!error){
        for ( NSString *file in dirFiles) {
            if ( [file hasSuffix:@"plist"] ) {
                NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
                if ( [[dict objectForKey:@"Description"] isEqualToString:type] ) {
                    
                    NSDictionary *temp = [dict objectForKey:@"Foreground"];
                    if ( temp != nil ) {
                        NSMutableDictionary *foreground = [[NSMutableDictionary alloc]init];
                        for (NSString *key in [temp keyEnumerator]) {
                            NSArray *colors = [temp valueForKey:key];
                            CGFloat red   = [[colors objectAtIndex:0] floatValue];
                            CGFloat green = [[colors objectAtIndex:1] floatValue];
                            CGFloat blue  = [[colors objectAtIndex:2] floatValue];
                            CGFloat alpha = 1;
                            if( [colors count] == 4 ) [[colors objectAtIndex:3] floatValue];
                            
                            NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
                            [foreground setValue: color forKey:key];
                        }
                        [self setForegroundColor: foreground];
                        [foreground release];
                    }
                    
                    temp = [dict objectForKey:@"Background"];
                    if ( temp != nil ) {
                        NSMutableDictionary *background = [[NSMutableDictionary alloc]init];
                        for (NSString *key in [temp keyEnumerator]) {
                            NSArray *colors = [temp valueForKey:key];
                            CGFloat red   = [[colors objectAtIndex:0] floatValue];
                            CGFloat green = [[colors objectAtIndex:1] floatValue];
                            CGFloat blue  = [[colors objectAtIndex:2] floatValue];
                            CGFloat alpha = 1;
                            if( [colors count] == 4 ) [[colors objectAtIndex:3] floatValue];
                            
                            NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
                            //[_backgroundColor setValue: color forKey:key];
                            [background setValue: color forKey:key];
                        }
                        [self setBackgroundColor: background];
                        [background release];
                    }
                    // Background is optional but we need to clear the background dictionary otherwise it will keep the previous colors
                    else {
                        [self setBackgroundColor: [NSMutableDictionary dictionary]];
                    }
                    [dict release];
                    return true;
                }
                [dict release];
            }
        }
    }
    return false;
}

#pragma mark Data Type

-(void)dataTypeDidChange{
    
    if( [[_sequencesController arrangedObjects] count] > 0 ){
        
        NSMutableArray *newSchemes;
        NSString *scheme;
        if( [[[[_sequencesController arrangedObjects]objectAtIndex:0]dataType ] isKindOfClass:[MFNucleotide class]] ){
            newSchemes = [self loadColorSchemes:@"Nucleotide"];
            scheme = _nucleotideColoringDescription;
            //[self setUpColoring:_nucleotideColoringDescription];
            [self setUpColoring:scheme datatype:@"Nucleotide"];
            for (NSMenuItem *item in [_geneticCodePopUp itemArray]) {
                [item setEnabled:YES];
            }
        }
        else {
            newSchemes = [self loadColorSchemes:@"Amino acid"];
            scheme = _aaColoringDescription;
            [self setUpColoring:scheme datatype:@"Amino acid"];
            for (NSMenuItem *item in [_geneticCodePopUp itemArray]) {
                [item setEnabled:NO];
            }
        }
        [self willChangeValueForKey:@"colorSchemes"];
        [_colorSchemes replaceObjectsInRange:NSMakeRange(0, [_colorSchemes count]) withObjectsFromArray:newSchemes];
        [self didChangeValueForKey:@"colorSchemes"];
        
        [_coloringController setSelectionIndex:[_colorSchemes indexOfObject:scheme]];
    }
    
}

-(void)setSequencesDataType:(MFDataType*)dataType{
    for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
        sequence.dataType = dataType;
    }
    [self dataTypeDidChange];
}



#pragma mark *** Dragging ***

- (NSArray *)acceptableDragTypes{
    return [NSArray arrayWithObjects:NSFilenamesPboardType,nil];
}

- (void)registerTypesForView:(NSView *)view{
    [view registerForDraggedTypes:[self acceptableDragTypes]];
}

- (NSDragOperation)draggingEntered:(id )sender {
    if ((NSDragOperationGeneric & [sender draggingSourceOperationMask])
        == NSDragOperationGeneric) {
        
        return NSDragOperationGeneric;
        
    }
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id )sender {
    return YES;
}


- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    NSString *type = [pboard availableTypeFromArray:[self acceptableDragTypes]];
    BOOL loaded = NO;
    
    if (type) {
        if ([type isEqualToString:NSFilenamesPboardType]) {
            NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
            if( [files count] > 0 ){
                
                NSMutableArray *alignments = [[NSMutableArray alloc]init];
                for (NSString *file in files) {
                    MFSequenceSet *sequenceSet = [MFSequenceReader readSequencesFromFile:file];
                    
                    if ( sequenceSet != nil) {
                        [[self document] setFileFormat:[sequenceSet annotationForKey:MFSequenceFileFormat]];
                        [alignments addObject:[sequenceSet sequences]];
                    }
                }
                
                [self loadAlignments:alignments];
                loaded = YES;
                [alignments release];
            }
        }
    }
    return loaded;
}

#pragma mark *** Binding Methods ***

+ (NSSet *)keyPathsForValuesAffectingResidueWidth {
    return [NSSet setWithObjects:@"fontSize", @"fontName", nil];
}

-(CGFloat)residueWidth{
    NSMutableDictionary *attsDict = [[NSMutableDictionary alloc] init];
    NSFont *font = [NSFont fontWithName:fontName size:fontSize];
    [attsDict setObject:font forKey:NSFontAttributeName];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"A" attributes:attsDict];
    CGFloat resWidth  = [string size].width;
    [string release];
    [attsDict release];
    return resWidth;
}



#pragma mark *** MFSequencesView Delegate Methods ***

- (void)sequencesView:(MFSequencesView *)inSequenceView insertGaps:(NSUInteger)nGaps inSequenceRange:(NSRange)sequenceRange atIndex:(NSUInteger)index{
    NSUndoManager *undoManager = [[self document]undoManager];
    [undoManager beginUndoGrouping];
    
    NSArray *sequences = [[_sequencesController arrangedObjects] subarrayWithRange:sequenceRange];
    NSRange range = NSMakeRange(index, nGaps);
    for (MFSequence *sequence in sequences ) {
        [sequence insertGaps:nGaps AtIndex:index];
    }
    
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView deleteGaps: NSMakeRange(index, nGaps) inSequenceRange: sequenceRange];
    
    // We don't allow alignment with more than 2 empty columns at the fromt
    NSUInteger numberOfEmpties = [MFSequenceUtils numberOfEmptyColumnsAtFront:[_sequencesController arrangedObjects]];
    //NSUInteger numberOfSequences = [[_sequencesController arrangedObjects] count];
    
    if ( numberOfEmpties > 2 ) {
        for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
            [sequence deleteResiduesInRange:NSMakeRange(0, numberOfEmpties)];
            [[undoManager prepareWithInvocationTarget:sequence] insertGaps:numberOfEmpties AtIndex:0];
        }
        //[[undoManager prepareWithInvocationTarget:self]sequencesView:inSequenceView insertGaps:numberOfEmpties inSequenceRange:NSMakeRange(0, numberOfSequences) atIndex:0];
    }
    
    NSUInteger maxLength = [MFSequenceUtils maxLength:[_sequencesController arrangedObjects]];
    
    for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
        // should be the block that we moved right if it was shorter than others
        if( [sequence length] >  maxLength ){
            range.location = maxLength;
            range.length   = [sequence length] - maxLength;
            [sequence deleteResiduesInRange:range];
            [[undoManager prepareWithInvocationTarget:sequence] appendGaps:range.length];
        }
        // should be the other sequences
        else if( [sequence length] <  maxLength ){
            NSUInteger nGaps = maxLength - [sequence length];
            [sequence appendGaps:nGaps];
            range.location = maxLength-nGaps;
            range.length   = nGaps;
            [[undoManager prepareWithInvocationTarget:sequence] deleteResiduesInRange: range];
        }
    }
    [undoManager endUndoGrouping];
    [undoManager setActionName:@"Insertion"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}

// UNDO only
- (void)sequencesView:(MFSequencesView *)inSequenceView deleteGaps:(NSRange)gapRange inSequenceRange:(NSRange)sequenceRange{
    NSUndoManager *undoManager = [[self document]undoManager];
    [undoManager beginUndoGrouping];
    
    MF2DRange rangeSelection = _sequencesView.rangeSelection;
    rangeSelection.x.location -= gapRange.length;
    [_sequencesView setRangeSelection:rangeSelection];
    
    NSArray *sequences = [[_sequencesController arrangedObjects] subarrayWithRange:sequenceRange];
    for (MFSequence *sequence in sequences ) {
        [sequence deleteResiduesInRange:gapRange];
    }
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView insertGaps: gapRange.length inSequenceRange: sequenceRange atIndex:gapRange.location];
    
    NSUInteger maxLength = [MFSequenceUtils maxLength:[_sequencesController arrangedObjects]];
    
    NSRange range;
    for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
        // should be the block that we moved right if it was shorter than others
        if( [sequence length] >  maxLength ){
            range.location = maxLength;
            range.length   = [sequence length] - maxLength;
            [sequence deleteResiduesInRange:range];
            [[undoManager prepareWithInvocationTarget:sequence] appendGaps:range.length];
        }
        // should be the other sequences
        else if( [sequence length] <  maxLength ){
            NSUInteger nGaps = maxLength - [sequence length];
            [sequence appendGaps:nGaps];
            range.location = maxLength-nGaps;
            range.length   = nGaps;
            [[undoManager prepareWithInvocationTarget:sequence] deleteResiduesInRange: range];
        }
    }
    
    //[[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView insertGaps: gapRange.length inSequenceRange: sequenceRange atIndex:gapRange.location];
    
    [undoManager endUndoGrouping];
    [undoManager setActionName:@"Deletion"];

    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}


// UNDO only
- (void)sequencesView:(MFSequencesView *)inSequenceView insertSites:(NSArray*)sites atIndex:(NSUInteger)index inSequenceRange:(NSRange)sequenceRange{
    NSUndoManager *undoManager = [[self document]undoManager];
    
    NSArray *sequences = [[_sequencesController arrangedObjects] subarrayWithRange:sequenceRange];
    NSEnumerator *arrayEnum = [sites objectEnumerator];
    for (MFSequence *sequence in sequences ) {
        NSString *insertSite = [arrayEnum nextObject];
        [sequence insertResidues:insertSite AtIndex:index];
    }
    
    MF2DRange rangeSelection = MFMake2DRange(index, [[sites objectAtIndex:0]length], sequenceRange.location, sequenceRange.length);
    [_sequencesView setRangeSelection:rangeSelection];
    
    NSRange range;
    range.location = index;
    range.length = [[sites objectAtIndex:0] length];
    
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView removeSitesInRange: range inSequenceRange: sequenceRange];
    [undoManager setActionName:@"Delete"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}



- (void)sequencesView:(MFSequencesView *)inSequenceView removeSitesInRange:(NSRange)siteRange inSequenceRange:(NSRange)sequenceRange{
    NSUndoManager *undoManager = [[self document]undoManager];
    [undoManager beginUndoGrouping];
    NSMutableArray *sites = [[NSMutableArray alloc] initWithCapacity:sequenceRange.length];
    NSUInteger numberOfSequences = [[_sequencesController arrangedObjects] count];
    
    NSArray *sequences = [[_sequencesController arrangedObjects] subarrayWithRange:sequenceRange];
    if( [[sequences objectAtIndex:0]translated] ){
        for (MFSequence *sequence in sequences ) {
            [sites addObject: [sequence subCodonSequenceWithRange:siteRange]];
            [sequence deleteResiduesInRange:siteRange];
        }
    }
    else{
        for (MFSequence *sequence in sequences ) {
            [sites addObject: [sequence subSequenceWithRange:siteRange]];
            [sequence deleteResiduesInRange:siteRange];
        }
    }
    
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView insertSites: sites atIndex:siteRange.location inSequenceRange: sequenceRange];
    [sites release];
    
    // We don't allow alignment with more than 2 empty columns at the fromt
    NSUInteger numberOfEmpties = [MFSequenceUtils numberOfEmptyColumnsAtFront:[_sequencesController arrangedObjects]];
    
    if ( numberOfEmpties > 2 ) {
        for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
            [sequence deleteResiduesInRange:NSMakeRange(0, numberOfEmpties)];
        }
        [[undoManager prepareWithInvocationTarget:self]sequencesView:inSequenceView insertGaps:numberOfEmpties inSequenceRange:NSMakeRange(0, numberOfSequences) atIndex:0];
    }
    
    NSUInteger maxLength = [MFSequenceUtils maxLength:[_sequencesController arrangedObjects]];
    NSRange range;
    for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
        // the alignment can be shorter if other sequences around selction are gaps
        if( [sequence length] >  maxLength ){
            range.location = maxLength;
            range.length   = [sequence length] - maxLength;
            [sequence deleteResiduesInRange:range];
            [[undoManager prepareWithInvocationTarget:sequence] appendGaps:range.length];
        }
        // Classic case
        else if( [sequence length] <  maxLength ){
            NSUInteger nGaps = maxLength - [sequence length];
            [sequence appendGaps:nGaps];
            range.location = maxLength-nGaps;
            range.length   = nGaps;
            [[undoManager prepareWithInvocationTarget:sequence] deleteResiduesInRange: range];
        }
    }
    
    [undoManager endUndoGrouping];
    [undoManager setActionName:@"Insert"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}

// only left, remove gaps only
- (void)sequencesView:(MFSequencesView *)inSequenceView slideSitesLeftInRange:(NSRange)siteRange inSequenceRange:(NSRange)sequenceRange by:(NSUInteger)amount{
    NSUndoManager *undoManager = [[self document]undoManager];
    
    NSArray *sequences = [[_sequencesController arrangedObjects] subarrayWithRange:sequenceRange];
    for (MFSequence *sequence in sequences ) {
        [sequence deleteResiduesInRange:NSMakeRange(siteRange.location, siteRange.length)];
        [sequence insertGaps:siteRange.length AtIndex:siteRange.location+amount];
    }
    
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView slideSitesRightInRange: siteRange inSequenceRange:sequenceRange by: amount];
    [undoManager setActionName:@"Shift"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}

// UNDO only
- (void)sequencesView:(MFSequencesView *)inSequenceView slideSitesRightInRange:(NSRange)siteRange inSequenceRange:(NSRange)sequenceRange by:(NSUInteger)amount{
    NSUndoManager *undoManager = [[self document]undoManager];
    
    NSArray *sequences = [[_sequencesController arrangedObjects] subarrayWithRange:sequenceRange];
    for (MFSequence *sequence in sequences ) {
        [sequence deleteResiduesInRange:NSMakeRange(siteRange.location+amount, siteRange.length)];
        [sequence insertGaps:siteRange.length AtIndex:siteRange.location];
    }
    MF2DRange rangeSelection = _sequencesView.rangeSelection;
    rangeSelection.x.location += siteRange.length;
    [_sequencesView setRangeSelection:rangeSelection];
    
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView slideSitesLeftInRange: siteRange inSequenceRange:sequenceRange by: amount];
    [undoManager setActionName:@"Shift"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}


// replace
- (void)sequencesView:(MFSequencesView *)inSequenceView replaceResiduesInRange:(NSRange)range atSequenceIndex:(NSUInteger)sequenceIndex withString:(NSString*)string{
    NSUndoManager *undoManager = [[self document]undoManager];
    
    MFSequence *sequence = [[_sequencesController arrangedObjects]objectAtIndex:sequenceIndex];
    NSString *replacedString = [sequence subSequenceWithRange:range];
    [sequence replaceCharactersInRange:range withString:string];
    
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView replaceResiduesInRange: range atSequenceIndex:sequenceIndex withString: replacedString];
    [undoManager setActionName:@"Edit"];
    
    [_sequencesView setNeedsDisplay:YES];
}

// UNDO only
// not tested
- (void)sequencesView:(MFSequencesView *)inSequenceView insertSites:(NSArray*)sites atIndexes:(NSIndexSet*)indexes inSequenceRange:(NSRange)sequenceRange{
    NSUndoManager *undoManager = [[self document]undoManager];
    
    NSArray *sequences = [[_sequencesController arrangedObjects] subarrayWithRange:sequenceRange];
    NSEnumerator *arrayEnum = [sites objectEnumerator];
    for (MFSequence *sequence in sequences ) {
        NSArray *insertResidues = [arrayEnum nextObject];
        NSUInteger index = [indexes firstIndex];
        for (NSString *res in insertResidues) {
            [sequence insertResidues:res AtIndex:index];
            index = [indexes indexGreaterThanIndex: index];
        }
    }
    
    //    MF2DRange rangeSelection = MFMake2DRange(index, [[sites objectAtIndex:0]length], sequenceRange.location, sequenceRange.length);
    //    [_sequencesView setRangeSelection:rangeSelection];
    //
    //    NSRange range;
    //    range.location = index;
    //    range.length = [[sites objectAtIndex:0] length];
    
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView removeSitesAtIndexes: indexes inSequenceRange: sequenceRange];
    [undoManager setActionName:@"Delete"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}

// not tested
- (void)sequencesView:(MFSequencesView *)inSequenceView removeSitesAtIndexes:(NSIndexSet*)siteIndexes inSequenceRange:(NSRange)sequenceRange{
    NSUndoManager *undoManager = [[self document]undoManager];
    [undoManager beginUndoGrouping];
    NSMutableArray *sites = [NSMutableArray arrayWithCapacity:sequenceRange.length];
    
    NSArray *sequences = [[_sequencesController arrangedObjects] subarrayWithRange:sequenceRange];
    if( [[sequences objectAtIndex:0]translated] ){
        for (MFSequence *sequence in sequences ) {
            NSMutableArray *s = [NSMutableArray arrayWithCapacity:[siteIndexes count]];
            [siteIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [s addObject: [sequence subCodonSequenceWithRange:NSMakeRange(idx, 1)]];
            }];
            [sites addObject:s];
            
            [sequence deleteResiduesAtIndexes:siteIndexes];
        }
    }
    else{
        for (MFSequence *sequence in sequences ) {
            NSMutableArray *s = [NSMutableArray arrayWithCapacity:[siteIndexes count]];
            [siteIndexes enumerateIndexesUsingBlock:^(NSUInteger idx, BOOL *stop) {
                [s addObject: [sequence subSequenceWithRange:NSMakeRange(idx, 1)]];
            }];
            [sites addObject:s];
            
            [sequence deleteResiduesAtIndexes:siteIndexes];
        }
    }
    
    [[undoManager prepareWithInvocationTarget:self] sequencesView:inSequenceView insertSites: sites atIndexes:siteIndexes inSequenceRange: sequenceRange];
    
    
    NSUInteger maxLength = [MFSequenceUtils maxLength:[_sequencesController arrangedObjects]];
    NSRange range;
    for (MFSequence *sequence in [_sequencesController arrangedObjects] ) {
        // the alignment can be shorter if other sequences around selction are gaps
        if( [sequence length] >  maxLength ){
            range.location = maxLength;
            range.length   = [sequence length] - maxLength;
            [sequence deleteResiduesInRange:range];
            [[undoManager prepareWithInvocationTarget:sequence] appendGaps:range.length];
        }
        // Classic case
        else if( [sequence length] <  maxLength ){
            NSUInteger nGaps = maxLength - [sequence length];
            [sequence appendGaps:nGaps];
            range.location = maxLength-nGaps;
            range.length   = nGaps;
            [[undoManager prepareWithInvocationTarget:sequence] deleteResiduesInRange: range];
        }
    }
    
    [undoManager endUndoGrouping];
    [undoManager setActionName:@"Insert"];
    
    [_sequencesView updateFrameSize];
    [_sequencesView setNeedsDisplay:YES];
}

#pragma mark *** NSSplitView Delegate Methods ***

- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)dividerIndex{
    
    if ( dividerIndex == 0 ) {
        return [_namesView frame].size.width+20;
    }
    return proposedMax;
}

#pragma mark *** Notification methods ***

- (void)selectionNotification:(NSNotification *)notification {

    if( [notification object] != self ){
        NSDictionary *info = [notification userInfo];
        NSArray *selection = [info objectForKey:@"selection"];
    
        NSMutableArray *objects  = [[NSMutableArray alloc]init];
        for (MFSequence *sequence in [_sequencesController arrangedObjects]) {
            if( [selection indexOfObject:[sequence name]] != NSNotFound ){
                [objects addObject:sequence];
            }
        }
        [_sequencesController setSelectedObjects:objects];
        [objects release];
    }
}

//TODO: undos
- (void)coloringNotification:(NSNotification *)notification {
                    
    NSArray *sequences = [_sequencesController arrangedObjects];
    if ( [sequences count] == 0 ) return;
    
    NSDictionary *info = [notification userInfo];
    
    MFDataType *datatype = [[_dataTypeController selectedObjects]objectAtIndex:0];
    
    
    
    if( ([[info objectForKey:@"datatype"] isEqualToString:@"Amino acid"] && [datatype isKindOfClass:[MFNucleotide class]] && ![[sequences objectAtIndex:0]translated])
       || ([[info objectForKey:@"datatype"] isEqualToString:@"Nucleotide"] && [datatype isKindOfClass:[MFNucleotide class]] && [[sequences objectAtIndex:0]translated]) ){
        return;
    }
    
    NSString *file = [info objectForKey:@"file"];
    
    if( [[info objectForKey:@"type"] isEqualTo:@"add"] ){
        [self willChangeValueForKey:@"colorSchemes"];
        [_colorSchemes addObject:file];
        [self didChangeValueForKey:@"colorSchemes"];
    }
    else if( [[info objectForKey:@"type"] isEqualTo:@"delete"] ){
        // remove the scheme from the list and check that it is the scheme in use
        [self willChangeValueForKey:@"colorSchemes"];
        [_colorSchemes removeObject:file];
        [self didChangeValueForKey:@"colorSchemes"];
        
        NSString *selectedColorScheme = [[_coloringController selectedObjects]objectAtIndex:0];
        if([file isEqualToString:selectedColorScheme] ){
            [self setUpColoring:[_colorSchemes objectAtIndex:0]];
            for (NSMenuItem *item in [_geneticCodePopUp itemArray]) {
                [item setEnabled:YES];
            }
            [_coloringController setSelectionIndex:0];
        }
    }
    else if( [[info objectForKey:@"type"] isEqualTo:@"modify"] ){
        // update the colors
        if( [datatype isKindOfClass:[MFNucleotide class]] && ![[sequences objectAtIndex:0]translated] ){
            [self setUpColoring:_nucleotideColoringDescription datatype:@"Nucleotide"];
        }
        else {
            [self setUpColoring:_aaColoringDescription datatype:@"Amino acid"];
        }
    }
    else if( [[info objectForKey:@"type"] isEqualTo:@"rename"] ){
        // update the list but not the colors
        
        if( [datatype isKindOfClass:[MFNucleotide class]] && ![[sequences objectAtIndex:0]translated] ){
            NSMutableArray *schemes = [self loadColorSchemes:@"Nucleotide"];
            [self willChangeValueForKey:@"colorSchemes"];
            [_colorSchemes replaceObjectsInRange:NSMakeRange(0, [_colorSchemes count]) withObjectsFromArray:schemes];
            [self didChangeValueForKey:@"colorSchemes"];
        
            if ( [_colorSchemes indexOfObject:_nucleotideColoringDescription] == NSNotFound) {
                [_nucleotideColoringDescription release];
                _nucleotideColoringDescription = [file copy];
                [_coloringController setSelectionIndex:[_colorSchemes indexOfObject:_nucleotideColoringDescription]];
            }
        }
        else {
            NSMutableArray *schemes = [self loadColorSchemes:@"Amino acid"];
            [self willChangeValueForKey:@"colorSchemes"];
            [_colorSchemes replaceObjectsInRange:NSMakeRange(0, [_colorSchemes count]) withObjectsFromArray:schemes];
            [self didChangeValueForKey:@"colorSchemes"];
            
            if ( [schemes indexOfObject:_aaColoringDescription] == NSNotFound) {
                [_aaColoringDescription release];
                _aaColoringDescription = [file copy];
                [_coloringController setSelectionIndex:[_colorSchemes indexOfObject:_aaColoringDescription]];
            }
        }
        
    }

}

- (void) windowWillClose:(NSNotification *) notification {
    NSLog(@"windowWillClose %@", notification);
    
    if ( self.window != [notification object] ) {
        NSWindowController *controller = [[notification object] windowController];
        [[controller retain] autorelease];
        [_windowControllers removeObject: controller];
    }
    // if we close the window we need to cancel any nsoperation
    else {
        [self performSelectorOnMainThread:@selector(cancelAllOperations:) withObject:nil waitUntilDone:YES];
    }
}

-(void)cancelAllOperations:(NSObject*)object{
    NSLog(@"cancelAllOperations");
    NSEnumerator *enumerator = [_progressControllers keyEnumerator];
    NSOperation *op;
    while ( op = [enumerator nextObject]) {
        [op removeObserver:self forKeyPath:@"isFinished"];
        [op cancel];
        [[_progressControllers objectForKey:op] close];
    }
    [_progressControllers removeAllObjects];
}

#pragma mark *** Phylogenetics ***

- (IBAction)calculateDistanceMatrix:(id)sender{
    
//    if( [[self document]isDocumentEdited] || [[self document]fileURL] == nil ){
//        NSAlert *alert = [[NSAlert alloc]init];
//        [alert setMessageText:@"You need to save the alignment"];
//        [alert addButtonWithTitle:@"Close"];
//        //[alert addButtonWithTitle:@"Save As"];
//        //[alert addButtonWithTitle:@"Save"];
//        
//        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
//            if (result == NSAlertFirstButtonReturn) {
//                
//            }
//        }];
//        [alert release];
//    }
//    else {
        MFDistanceMatrixOperation *op = [[MFDistanceMatrixOperation alloc]initWithSequenceArray:[_sequencesController arrangedObjects] model:[sender tag]];
        MFProgressController *progress = [[MFProgressController alloc]initWithOperation:op];
        //progress.primaryDescription = [operation.options objectForKey:MFExternalOperationDescriptionKey];
        progress.window.title = op.description;
        [[progress window] center];
        [progress showWindow: self];
        [progress.progressIndicator startAnimation:nil];
        
        MFAppDelegate *del = [[NSApplication sharedApplication]delegate];
        [[del sharedOperationQueue] addOperation:op];
        
        [op addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
        
        [_progressControllers setObject:progress forKey:op];
        [progress release];
        [op release];
//    }
}

- (void)distanceMatrixDidFinish:(MFDistanceMatrixOperation *)operation{
    MFDistanceWindowController *controller = [[MFDistanceWindowController alloc]initWithDistanceMatrix:operation.matrix];
    controller.window.delegate = self;
    [_windowControllers addObject:controller];
    
    //[[controller window] center];
    [controller showWindow: self];
    [controller release];
}

- (IBAction)neighborjoining:(id)sender{
    MFDistanceMatrix *dm = [[MFDistanceMatrix alloc]initWithSequencesFromArray: [_sequencesController arrangedObjects]];
    [dm calculateDistances];
    MFNeighborJoining *nj = [[MFNeighborJoining alloc]initWithDistanceMatrix:dm];
    MFTree *tree = [nj inferTree];
    [dm release];
    [nj release];
    
    MFTreeDocument *doc = [[MFTreeDocument alloc]initWithTrees:[NSArray arrayWithObject:tree]];
    
    [[NSDocumentController sharedDocumentController] addDocument:doc];
    [doc makeWindowControllers];
    [doc showWindows];
    
    [doc release];
    /*MFTreeController *controller = [[MFTreeController alloc] initWithTree:tree];
    
    [[controller window] center];
    [controller showWindow: self];*/

}


- (IBAction)showBuildTreeSheet:(id)sender{

//    if( [[self document]isDocumentEdited] || [[self document]fileURL] == nil ){
//        NSAlert *alert = [[NSAlert alloc]init];
//        [alert setMessageText:@"You need to save the alignment"];
//        [alert addButtonWithTitle:@"Close"];
//        //[alert addButtonWithTitle:@"Save As"];
//        //[alert addButtonWithTitle:@"Save"];
//        
//        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
//            if (result == NSAlertFirstButtonReturn) {
//                
//            }
//        }];
//        [alert release];
//    }
//    else {
        if( [[_sequencesController arrangedObjects] count] > 3 ){
            if( !_treeBuilderController ){
                _treeBuilderController = [[MFTreeBuilderController alloc]initWithSequences:[_sequencesController arrangedObjects] withName:[[[self document]fileURL]lastPathComponent]];
            }
            [_treeBuilderController initType];
            [NSApp beginSheet: _treeBuilderController.window
               modalForWindow: [NSApp mainWindow]
                modalDelegate: self
               didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
                  contextInfo: _treeBuilderController];
        }
//    }
    
}

#pragma mark *** Alignment ***

- (IBAction)showAlignerSheet:(id)sender{
    
//    if( [[self document]isDocumentEdited] ){
//        NSAlert *alert = [[NSAlert alloc]init];
//        [alert setMessageText:@"You need to save the alignment"];
//        [alert addButtonWithTitle:@"Close"];
//        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
//            if (result == NSAlertFirstButtonReturn) {
//                
//            }
//        }];
//        [alert release];
//    }
//    else {
        if( [[_sequencesController arrangedObjects] count] > 1 ){
            if( !_alignerController ){
                _alignerController = [[MFAlignerController alloc]initWithSequences:[_sequencesController arrangedObjects] withName:[[[self document]fileURL]lastPathComponent]];
            }
            _alignerController.transalignEnabled = [[[[_sequencesController arrangedObjects] objectAtIndex:0] dataType ]  isKindOfClass:[MFNucleotide class]] && ![[[_sequencesController arrangedObjects] objectAtIndex:0] translated];
            //[_alignerController setSelection: _sequencesView.rangeSelection];
            [NSApp beginSheet: _alignerController.window
               modalForWindow: [NSApp mainWindow]
                modalDelegate: self
               didEndSelector: @selector(didEndSheet:returnCode:contextInfo:)
                  contextInfo: _alignerController];
        }
//    }
    
}


- (void)didEndSheet: (NSWindow*)sheet returnCode: (int)returnCode contextInfo: (void*)contextInfo {
    if (returnCode != NSOKButton) return;
    
    id<MFOperationBuilder>controller = contextInfo;
    
    NSArray *operations = [controller operations];
    
    MFProgressController *progress = [[MFProgressController alloc]initWithOperations:operations];
    [[progress window] center];
    [progress showWindow: self];
    [progress.progressIndicator startAnimation:nil];
    
    NSMapTable *map = [[NSMapTable alloc]init];
    for ( MFOperation *op in operations ) {
        op.delegate = progress;
        
        for ( MFOperation *dep in [op dependencies] ) {
            if( [map objectForKey:dep]){
                [map setObject:[NSNumber numberWithInt:[[map objectForKey:dep] intValue] + 1] forKey:dep];
            }
            else {
                [map setObject:[NSNumber numberWithInt:1] forKey:dep];
            }
        }
    }
    NSOperation *operation = [operations objectAtIndex:0];
    for ( NSOperation *op in operations ) {
        if( ![map objectForKey:op]){
            operation = op;
            break;
        }
    }
    [map release];
    [operation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew context:nil];
    
    MFAppDelegate *del = [[NSApplication sharedApplication]delegate];
    [[del sharedOperationQueue] addOperations:operations waitUntilFinished:NO];
    
    [_progressControllers setObject:progress forKey:operation];
    [progress release];
}

- (void)operationDone:(MFOperation *)op {
    NSLog(@"operationDone (%@) URL %@", (op.isCancelled?@"Cancelled":@"Success"), op.outputURL);
    
    [op removeObserver:self forKeyPath:@"isFinished"];
    
    if( !op.isCancelled ){
        NSError *err;
        if( [op.outputURL checkResourceIsReachableAndReturnError:&err] ){
            NSString *class = op.classType;
            NSDocument *doc = [[NSClassFromString(class) alloc]init];
            
            NSError *error = nil;
            BOOL ok = [doc readFromURL:op.outputURL ofType:nil error:&error];
            
            if(ok){
                [[NSDocumentController sharedDocumentController] addDocument:doc];
                [doc makeWindowControllers];
                [doc showWindows];
            }
            [doc release];
        }
        
    }
    
    if( [_progressControllers objectForKey:op]){
        [_progressControllers removeObjectForKey:op];
    }
}

- (void)distanceMatrixOperationDone:(MFDistanceMatrixOperation *)op {
    NSLog(@"distanceMatrixOperationDone (%@)", (op.isCancelled?@"Cancelled":@"Success"));
    
    [op removeObserver:self forKeyPath:@"isFinished"];
    
    if( !op.isCancelled ){
        MFDistanceWindowController *controller = [[MFDistanceWindowController alloc]initWithDistanceMatrix:op.matrix];
        controller.window.delegate = self;
        [_windowControllers addObject:controller];
        
        //[[controller window] center];
        [controller showWindow: self];
        [controller release];
        
    }
    
    if( [_progressControllers objectForKey:op]){
        [_progressControllers removeObjectForKey:op];
    }
}


@end
