//
//  MFDistanceWindow.m
//  Seqotron
//
//  Created by Mathieu Fourment on 18/12/2014.
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

#import "MFDistanceWindowController.h"

#define kSigDigitsToolbarItemID @"Sig. Digits"

@implementation MFDistanceWindowController

@synthesize sigDigits;

- (id)initWithDistanceMatrix:(MFDistanceMatrix*)distanceMatrix{
    if (self = [super initWithWindowNibName:@"MFDistanceMatrixWindow"]) {
        NSLog(@"MFDistanceWindowController initWithWindowNibName");
        _distanceMatrix = [distanceMatrix retain];
        _columnMap = [[NSMutableDictionary alloc]init];
        sigDigits = 3;
        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [_numberFormatter setMaximumSignificantDigits:sigDigits];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"MFDistanceWindowController dealloc");
    [_columnScrollView stopSynchronizing];
    [_matrixScrollView stopSynchronizing];
    [_distanceMatrix release];
    [_columnMap release];
    [_numberFormatter release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    [[_columnScrollView verticalScroller] setControlSize:1];
    
    [_columnScrollView setSynchronizedScrollView:_matrixScrollView onVertical:YES];
    [_matrixScrollView setSynchronizedScrollView:_columnScrollView onVertical:YES]; //_sequenceView listens to _namesView
    
    for ( NSUInteger i = 0; i < [_distanceMatrix dimension]; i++ ) {
        [_columnMap setObject:[NSNumber numberWithUnsignedInteger:i] forKey:[_distanceMatrix nameAtIndex:i]];
        NSTableColumn * column = [[NSTableColumn alloc] initWithIdentifier:[_distanceMatrix nameAtIndex:i]];
        [[column headerCell]setStringValue:[_distanceMatrix nameAtIndex:i]];
        [column setHeaderToolTip:[_distanceMatrix nameAtIndex:i]];
        [_matrixTable addTableColumn:column];
        [column setWidth:80];
        [column release];
    }
    [_matrixTable reloadData];
}

// NSStepper
-(IBAction)stepperAction:(id)sender{
    [_numberFormatter setMaximumSignificantDigits:self.sigDigits];
    [_matrixTable reloadData];
}

- (IBAction)showSavePanel:(id)sender{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    // Restrict the file type to whatever you like
    [savePanel setAllowedFileTypes:@[@"csv"]];
    // Set the starting directory
    //[savePanel setDirectoryURL:someURL];
    // Perform other setup
    // Use a completion handler -- this is a block which takes one argument
    // which corresponds to the button that was clicked
    [savePanel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
            // Close panel before handling errors
            [savePanel orderOut:self];
            
            NSMutableString *string = [[NSMutableString alloc]init];
            for ( NSUInteger i = 0; i < _distanceMatrix.dimension ; i++ ) {
                [string appendFormat:@",%@",[ _distanceMatrix nameAtIndex:i]];
            }
            [string appendString:@"\r"];
            
            for ( NSUInteger i = 0; i < _distanceMatrix.dimension ; i++ ) {
                [string appendFormat:@"%@",[ _distanceMatrix nameAtIndex:i]];
                for ( NSUInteger j = 0; j < _distanceMatrix.dimension ; j++ ) {
                    [string appendFormat:@",%@", [_numberFormatter stringFromNumber:[NSNumber numberWithDouble:[_distanceMatrix valueForRow:i column: j]]]];
                }
                [string appendString:@"\r"];
            }
            NSString *path = [savePanel.URL path];
            [string writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
            [string release];
        }
    }];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_distanceMatrix dimension];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    if ( aTableView == _columnTable ) {
        return [_distanceMatrix nameAtIndex:rowIndex];
    }
    
    NSUInteger index = [[_columnMap objectForKey: [aTableColumn identifier]] unsignedIntegerValue];
    //return  [NSString stringWithFormat:@"%f", [_distanceMatrix valueForRow:rowIndex column: index]];
    return [_numberFormatter stringFromNumber:[NSNumber numberWithDouble:[_distanceMatrix valueForRow:rowIndex column: index]]];
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    NSTableView *table = [aNotification object];
    NSUInteger row = [table selectedRow];
    
    if( [_matrixTable selectedRow] != row ){
        [_matrixTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
    if( [_columnTable selectedRow] != row ){
        [_columnTable selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
    }
}



//--------------------------------------------------------------------------------------------------
// Factory method to create autoreleased NSToolbarItems.
//
// All NSToolbarItems have a unique identifer associated with them, used to tell your delegate/controller
// what toolbar items to initialize and return at various points.  Typically, for a given identifier,
// you need to generate a copy of your "master" toolbar item, and return it autoreleased.  The function
// creates an NSToolbarItem with a bunch of NSToolbarItem paramenters.
//
// It's easy to call this function repeatedly to generate lots of NSToolbarItems for your toolbar.
//
// The label, palettelabel, toolTip, action, and menu can all be nil, depending upon what you want
// the item to do.
//--------------------------------------------------------------------------------------------------
- (NSToolbarItem *)toolbarItemWithIdentifier:(NSString *)identifier
                                       label:(NSString *)label
                                 paleteLabel:(NSString *)paletteLabel
                                     toolTip:(NSString *)toolTip
                                      target:(id)target
                                 itemContent:(id)imageOrView
                                      action:(SEL)action
                                        menu:(NSMenu *)menu
{
    // here we create the NSToolbarItem and setup its attributes in line with the parameters
    NSToolbarItem *item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
    
    [item setLabel:label];
    [item setPaletteLabel:paletteLabel];
    [item setToolTip:toolTip];
    [item setTarget:target];
    [item setAction:action];
    
    // Set the right attribute, depending on if we were given an image or a view
    if([imageOrView isKindOfClass:[NSImage class]]){
        [item setImage:imageOrView];
    } else if ([imageOrView isKindOfClass:[NSView class]]){
        [item setView:imageOrView];
    }else {
        assert(!"Invalid itemContent: object");
    }
    
    
    // If this NSToolbarItem is supposed to have a menu "form representation" associated with it
    // (for text-only mode), we set it up here.  Actually, you have to hand an NSMenuItem
    // (not a complete NSMenu) to the toolbar item, so we create a dummy NSMenuItem that has our real
    // menu as a submenu.
    //
    if (menu != nil)
    {
        // we actually need an NSMenuItem here, so we construct one
        NSMenuItem *mItem = [[[NSMenuItem alloc] init] autorelease];
        [mItem setSubmenu:menu];
        [mItem setTitle:label];
        [item setMenuFormRepresentation:mItem];
    }
    
    return item;
}

#pragma mark -
#pragma mark NSToolbarDelegate

//--------------------------------------------------------------------------------------------------
// This is an optional delegate method, called when a new item is about to be added to the toolbar.
// This is a good spot to set up initial state information for toolbar items, particularly ones
// that you don't directly control yourself (like with NSToolbarPrintItemIdentifier here).
// The notification's object is the toolbar, and the @"item" key in the userInfo is the toolbar item
// being added.
//--------------------------------------------------------------------------------------------------
- (void)toolbarWillAddItem:(NSNotification *)notif {
    NSToolbarItem *addedItem = [[notif userInfo] objectForKey:@"item"];
    
    // Is this the printing toolbar item?  If so, then we want to redirect it's action to ourselves
    // so we can handle the printing properly; hence, we give it a new target.
    //
    if ([[addedItem itemIdentifier] isEqual: NSToolbarPrintItemIdentifier]) {
        [addedItem setToolTip:@"Print your document"];
        [addedItem setTarget:self];
    }
}

//--------------------------------------------------------------------------------------------------
// This method is required of NSToolbar delegates.
// It takes an identifier, and returns the matching NSToolbarItem. It also takes a parameter telling
// whether this toolbar item is going into an actual toolbar, or whether it's going to be displayed
// in a customization palette.
//--------------------------------------------------------------------------------------------------
- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag {
    NSToolbarItem *toolbarItem = nil;
    
    // We create and autorelease a new NSToolbarItem, and then go through the process of setting up its
    // attributes from the master toolbar item matching that identifier in our dictionary of items.
    if ([itemIdentifier isEqualToString:kSigDigitsToolbarItemID])
    {
        // 1) Navigation toolbar item
        toolbarItem = [self toolbarItemWithIdentifier:kSigDigitsToolbarItemID
                                                label:kSigDigitsToolbarItemID
                                          paleteLabel:kSigDigitsToolbarItemID
                                              toolTip:@"Significant digits"
                                               target:self
                                          itemContent:_sigDigitsView
                                               action:nil
                                                 menu:nil];
    }
    
    
    return toolbarItem;
}

//--------------------------------------------------------------------------------------------------
// This method is required of NSToolbar delegates.  It returns an array holding identifiers for the default
// set of toolbar items.  It can also be called by the customization palette to display the default toolbar.
//--------------------------------------------------------------------------------------------------
- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar {
    return [NSArray arrayWithObjects:   kSigDigitsToolbarItemID,
            nil];
    // note:
    // that since our toolbar is defined from Interface Builder, an additional separator and customize
    // toolbar items will be automatically added to the "default" list of items.
}

//--------------------------------------------------------------------------------------------------
// This method is required of NSToolbar delegates.  It returns an array holding identifiers for all allowed
// toolbar items in this toolbar.  Any not listed here will not be available in the customization palette.
//--------------------------------------------------------------------------------------------------
- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    return [NSArray arrayWithObjects: kSigDigitsToolbarItemID,
            nil];
    // note:
    // that since our toolbar is defined from Interface Builder, an additional separator and customize
    // toolbar items will be automatically added to the "default" list of items.
}



@end
