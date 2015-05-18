//
//  MFDocument.m
//  Seqotron
//
//  Created by Mathieu Fourment on 25/07/2014.
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

#import "MFDocument.h"

#import "MFSequenceReader.h"
#import "MFSequenceWriter.h"
#import "MFSequenceSet.h"
#import "MFSequence.h"
#import "MFSequenceUtils.h"
#import "MFNucleotide.h"
#import "MFProtein.h"
#import "MFWindowController.h"


NSString *MFDocumentSequencesKey = @"sequences";

@implementation MFDocument

@synthesize window,fileFormats;

- (id)init
{
    self = [super init];
    if (self) {
        _currentFileFormat = MFSequenceFormatFASTA; // default is FASTA
        _indexFormat = MFSequenceFormatFASTA;
        _sequences = nil;
        fileFormats = [[NSArray alloc] initWithObjects:MFSequenceFormatArray];
    }
    return self;
}


- (void)dealloc {
    NSLog(@"MFDocument dealloc");
    [_sequences release];
    [fileFormats release];
    [super dealloc];
}


+ (BOOL)autosavesInPlace{
    return NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError{
    NSData * data = nil;
    if( [_sequences count] > 0 ){
        MFSequenceSet *set = [[MFSequenceSet alloc] initWithSequences:_sequences];
        
        NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys: [NSNumber numberWithBool:YES], MFSequenceWriterIgnoreLeadingGaps, nil];
        data = [MFSequenceWriter data:set withFormat:_indexFormat attributes:attrs];
        [set release];
        _currentFileFormat = _indexFormat;
        NSLog(@"Writing to file %lu", _indexFormat);
    }
    return data;
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
    
    MFWindowController *windowController = [[self windowControllers] objectAtIndex:0];
    [inSavePanel setMessage:@"Save alignment as:"];
    [inSavePanel setAccessoryView: windowController.saveDialogCustomView];	// add our custom view
    //[inSavePanel setAllowedFileTypes:@[@"txt"]];            // save files with 'txt' extension only
    //[inSavePanel setNameFieldLabel:@"FILE NAME:"];			// override the file name label
    
    //_savePanel = inSavePanel;	// keep track of the save panel for later
    [windowController.saveFileFormat removeAllItems];
//    NSArray *formats = [[NSArray alloc] initWithObjects:MFSequenceFormatArray];
    [windowController.saveFileFormat addItemsWithObjectValues:fileFormats];
//    [formats release];
    
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

-(BOOL)readFromURL:(NSURL*) url ofType:(NSString*)type error:(NSError**) outError {
    BOOL readSuccessfully = NO;
    
    MFSequenceSet *sequenceSet = [MFSequenceReader readSequencesFromFile:url.path];
    NSArray *sequenceArray = [sequenceSet sequences];
    
    if( sequenceArray != nil ){
        [MFSequenceUtils deleteFrontEmptyColumns:sequenceArray];
        [MFSequenceUtils pad:sequenceArray];
        
        MFDataType *dataType = nil;
        for (MFSequence *sequence in sequenceArray) {
            if( [sequence dataType] != nil ){
                dataType = [sequence dataType];
                break;
            }
        }
        if( dataType == nil ){
            [sequenceSet guessDataType];
        }
        
        _currentFileFormat = [self formatTypeStringToEnum: [sequenceSet annotationForKey:MFSequenceFileFormat]];
        
        // without it when we close the alignment without editing it, undos will be generated
        [[self undoManager] disableUndoRegistration];
        
        [self removeSequencesAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [[self sequences] count])]];
        [self insertSequences:sequenceArray atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [sequenceArray count])]];
        
        [[self undoManager] enableUndoRegistration];
        
        readSuccessfully = YES;
    }
//    else {
//        NSArray *objArray = [NSArray arrayWithObjects:@"Description", @"FailureReason", @"RecoverySuggestion", nil];
//        NSArray *keyArray = [NSArray arrayWithObjects:NSLocalizedDescriptionKey, NSLocalizedFailureReasonErrorKey, NSLocalizedRecoverySuggestionErrorKey, nil];
//        NSDictionary *userInfo = [NSDictionary dictionaryWithObjects:objArray forKeys:keyArray];
//        
//        *outError = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileReadUnknownError userInfo:userInfo];
//    }
    NSLog(@"successful %@ %d",[url path], readSuccessfully);
    return readSuccessfully;
}

// A method to retrieve the int value from the NSArray of NSStrings
-(MFSequenceFormat) formatTypeStringToEnum:(NSString*)strVal{
    NSArray *typeArray = [[NSArray alloc] initWithObjects:MFSequenceFormatArray];
    NSUInteger n = [typeArray indexOfObject:strVal];
    [typeArray release];
    return (MFSequenceFormat) n;
}

- (void)makeWindowControllers {
    MFWindowController *windowController = [[MFWindowController alloc] init];
    [self addWindowController:windowController];
    [windowController release];
}

- (NSArray *)sequences {
    return _sequences ? _sequences : [NSArray array];
    
}

- (void)insertSequences:(NSArray *)sequences atIndexes:(NSIndexSet *)indexes{
    if (!_sequences) {
        _sequences = [[NSMutableArray alloc] init];
    }
    [_sequences insertObjects:sequences atIndexes:indexes];
    // Register an action that will undo the insertion.
    NSUndoManager *undoManager = [self undoManager];
    [undoManager registerUndoWithTarget:self selector:@selector(removeSequencesAtIndexes:) object:indexes];
}

- (void)removeSequencesAtIndexes:(NSIndexSet *)indexes {
    
    if (!_sequences) {
        _sequences = [[NSMutableArray alloc] init];
    }
    NSArray *sequences = [_sequences objectsAtIndexes:indexes];
    
    [[[self undoManager] prepareWithInvocationTarget:self] insertSequences:sequences atIndexes:indexes];
    
    [_sequences removeObjectsAtIndexes:indexes];
    
}

-(void)setFileFormat:(NSString *)format{
    _indexFormat = _currentFileFormat = [self formatTypeStringToEnum: format];
}

@end
