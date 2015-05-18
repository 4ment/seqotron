//
//  MFTreeDocument.m
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

#import "MFTreeDocument.h"

#import "MFTreeWindowController.h"
#import "MFTreeReader.h"
#import "MFTreeWriter.h"

@implementation MFTreeDocument

- (id)init {
    self = [super init];
    if (self) {
        _trees = [[NSMutableArray alloc]init];
        _currentFileFormat = MFTreeFormatNEWICK;
        _indexFormat = MFTreeFormatNEWICK;
    }
    return self;
}

- (id)initWithTrees:(NSArray*)trees{
    
    self = [super init];
    if (self) {
        _trees = [trees mutableCopy];
        _currentFileFormat = MFTreeFormatNEWICK;
        _indexFormat = MFTreeFormatNEWICK;
    }
    return self;
}

-(void)dealloc{
    NSLog(@"MFTreeDocument dealloc");
    [_trees release];
    [super dealloc];
}

- (void)makeWindowControllers {
    // Start off with one document window.
    MFTreeWindowController *windowController = [[MFTreeWindowController alloc] init];
    [self addWindowController:windowController];
    [windowController release];
}

- (void)windowControllerDidLoadNib:(NSWindowController *)aController {
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
    
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError {
    // Insert code here to write your document to data of the specified type. If outError != NULL, ensure that you create and set an appropriate error when returning nil.
    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
    if (outError) {
        *outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
    NSData *data = [MFTreeWriter data:_trees withFormat:_indexFormat attributes:nil];
    _currentFileFormat = _indexFormat;
    NSLog(@"Writing to file %lu", _indexFormat);
    return data;
}


- (BOOL)readFromURL:(NSURL*) url ofType:(NSString*)type error:(NSError**) outError {
    BOOL readSuccessfully = NO;

    NSArray *trees = [MFTreeReader readTreesFromFile:url.path];
    NSLog(@"succesful %@", trees);
    if( trees != nil ){
        MFTree *tree = [trees objectAtIndex:0];
        _currentFileFormat = [self formatTypeStringToEnum: [tree attributeForKey:MFTreeFileFormat]];
        NSLog(@"File Format %@", [tree attributeForKey:MFTreeFileFormat]);
        // without it when we close the alignment without editing it, undos will be generated
        [[self undoManager] disableUndoRegistration];
        
        [self removeTreesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self trees] count])]];
        [self insertTrees:trees atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [trees count])]];
        
        [[self undoManager] enableUndoRegistration];
        
        readSuccessfully = YES;
        
    }
    return readSuccessfully;
}

+ (BOOL)autosavesInPlace {
    return NO;
}


- (NSArray *)trees {
    return _trees;
}

- (void)insertTrees:(NSArray *)trees atIndexes:(NSIndexSet *)indexes{
    [_trees insertObjects:trees atIndexes:indexes];
    NSLog(@"insertTrees %lu",[trees count]);
    NSUndoManager *undoManager = [self undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(removeTreesAtIndexes:) object:indexes];
}

- (void)removeTreesAtIndexes:(NSIndexSet *)indexes {
    NSArray *trees = [_trees objectsAtIndexes:indexes];
    [[[self undoManager] prepareWithInvocationTarget:self] insertTrees:trees atIndexes:indexes];
    [_trees removeObjectsAtIndexes:indexes];    
}

// A method to retrieve the int value from the NSArray of NSStrings
-(MFTreeFormat) formatTypeStringToEnum:(NSString*)strVal{
    NSArray *typeArray = [[NSArray alloc] initWithObjects:MFTreeFormatArray];
    NSUInteger n = [typeArray indexOfObject:strVal];
    [typeArray release];
    return (MFTreeFormat) n;
}

#pragma mark - Save panel

// https://developer.apple.com/library/mac/samplecode/CustomSave/Introduction/Intro.html#//apple_ref/doc/uid/DTS10004201

// -------------------------------------------------------------------------------
// prepareSavePanel:inSavePanel:
// -------------------------------------------------------------------------------
// Invoked by runModalSavePanel to do any customization of the Save panel savePanel.
//
- (BOOL)prepareSavePanel:(NSSavePanel *)inSavePanel {
    [inSavePanel setDelegate:self];	// allows us to be notified of save panel events
    
    MFTreeWindowController *windowController = [[self windowControllers] objectAtIndex:0];
    [inSavePanel setMessage:@"Save Tree as:"];
    [inSavePanel setAccessoryView: windowController.saveDialogCustomView];	// add our custom view
    //[inSavePanel setAllowedFileTypes:@[@"txt"]];            // save files with 'txt' extension only
    //[inSavePanel setNameFieldLabel:@"FILE NAME:"];			// override the file name label
    
    //_savePanel = inSavePanel;	// keep track of the save panel for later
    [windowController.saveFileFormat removeAllItems];
    NSArray *formats = [[NSArray alloc] initWithObjects:MFTreeFormatArray];
    [windowController.saveFileFormat addItemsWithObjectValues:formats];
    [formats release];
    
    [windowController.saveFileFormat setAction:@selector(formatComboBoxChanged:)];
    [windowController.saveFileFormat setTarget:self];
    [windowController.saveFileFormat setEditable:NO];
    [windowController.saveFileFormat selectItemAtIndex: _currentFileFormat];
    
    _indexFormat = _currentFileFormat;
    
    return YES;
}

- (void)formatComboBoxChanged:(NSComboBox *)comboBox {
    _indexFormat = [comboBox indexOfSelectedItem];
}


@end
