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

#import "MFTreeWindowController.h"

#define kArrowsToolbarItemID @"Arrows"

@implementation MFTreeWindowController

@synthesize taxaShown, selectionMode;
@synthesize saveDialogCustomView = _saveDialogCustomView;
@synthesize saveFileFormat = _saveFileFormat;
@synthesize nodeAttributes = _nodeAttributes;


- (id)init{
    if (self = [super initWithWindowNibName:@"MFTreeWindow"]) {
        NSLog(@"MFTreeDocument initWithWindowNibName");
        taxaShown = YES;
        _searchNodes = [[NSMutableArray alloc]init];
        _nodeAttributes = [[NSMutableArray alloc]initWithObjects:@" - None - ",@"Branch Length", @"Name", nil];
        _fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultTreeFontSize"]floatValue];
        _fontName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultTreeFontName"]copy];
        _font = [NSFont fontWithName:_fontName size:_fontSize];
        _selectedNodes = [[NSArray alloc] init];
    }
    return self;
}

- (void)dealloc {
    NSLog(@"MFTreeWindowController dealloc");
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [_fontName release];
    [_searchNodes release];
    [_selectedNodes release];
    [_nodeAttributes release];
    [_treeView unbind:@"trees"];
    [_treeView unbind:@"selectionIndexes"];
    [_treeView unbind:@"taxaShown"];
    [_treeView unbind:@"selectionMode"];
    [_treeView release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSLog(@"MFTreeWindowController windowDidLoad");
    
    _treeView = [[MFTreeView alloc]initWithFrame:[[_scrollView contentView] frame]];
    
    //_treeView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [_scrollView setDocumentView:_treeView];
    
    [_treeView bind:@"trees" toObject:_treesController withKeyPath:@"arrangedObjects" options:nil];
    [_treeView bind:@"selectionIndexes" toObject:_treesController withKeyPath:@"selectionIndexes" options:nil];
    [_treeView bind:@"taxaShown" toObject:self withKeyPath:@"taxaShown" options:nil];
    [_treeView bind:@"selectionMode" toObject:self withKeyPath:@"selectionMode" options:nil];
    [_treeView bind:@"selectedNodes" toObject:self withKeyPath:@"selectedNodes" options:nil];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(selectionNotification:) name:@"MFGlobalNameSelection" object:nil];
    
    if( [[_treesController arrangedObjects] count]){
        NSArray *attributes = [self attributesFromSelectedTree];
        [self willChangeValueForKey:@"nodeAttributes"];
        [_nodeAttributes addObjectsFromArray:attributes];
        [self didChangeValueForKey:@"nodeAttributes"];
    }

}

#pragma mark *** Notification Methods ***

- (void)selectionNotification:(NSNotification *)notification {
    
    if( [[_treesController arrangedObjects] count]){
        if( [notification object] != self ){
            NSDictionary *info = [notification userInfo];
            NSArray *selectedNames = [info objectForKey:@"selection"];
            NSMutableArray *selectedNodes = [[NSMutableArray alloc]init];
            [[[_treesController selectedObjects]objectAtIndex:0] enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPreorder usingBlock:^(MFNode *node){
                if([node isLeaf] && [selectedNames indexOfObject:[node name]] != NSNotFound )[selectedNodes addObject:node];
            }];
            [self willChangeValueForKey:@"selectedNodes"];
            [_selectedNodes release];
            _selectedNodes = [selectedNodes retain];
            [self didChangeValueForKey:@"selectedNodes"];
            [selectedNodes release];
        }
    }
}

- (void)setSelectedNodes:(NSArray *)selectedNodes{

    if(_selectedNodes != selectedNodes){
        [self willChangeValueForKey:@"selectedNodes"];
        [_selectedNodes release];
        _selectedNodes = [selectedNodes retain];
        [self didChangeValueForKey:@"selectedNodes"];
        
        if( self.selectionMode == 0 ){
            NSMutableArray *arrayMut = [[NSMutableArray alloc]init];
            if( [selectedNodes count] ){
                [[[_treesController selectedObjects]objectAtIndex:0] enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPreorder usingBlock:^(MFNode *node){
                    if([node isLeaf] && [_selectedNodes indexOfObject:node] != NSNotFound )[arrayMut addObject: [node name]];
                }];
            }
            NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:arrayMut,@"selection", nil];
            [[NSNotificationCenter defaultCenter]postNotificationName:@"MFGlobalNameSelection" object:self userInfo:dict];
            [arrayMut release];
        }
    }
}

-(NSArray*)selectedNodes{
    return _selectedNodes;
}


#pragma mark *** Action Methods ***

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    
    BOOL enabled = NO;
    SEL action = [menuItem action];
    
    if (action==@selector(zoomIn:)) {
        enabled = ([[_treesController arrangedObjects]count] > 0);
    }
    else if (action==@selector(zoomOut:)) {
        enabled = ([[_treesController arrangedObjects]count] > 0);
        
    }
    else if (action==@selector(zoomInWidth:)) {
        enabled = ([[_treesController arrangedObjects]count] > 0);
    }
    else if (action==@selector(zoomOutWidth:)) {
        enabled = ([[_treesController arrangedObjects]count] > 0);
        
    }
    else if (action==@selector(zoomImageToActualSize:)) {
        enabled = ([[_treesController arrangedObjects]count] > 0);
        
    }
    else if ( action==@selector(increaseFont:) || action==@selector(defaultFontSize:)) {
        enabled = ([[_treesController arrangedObjects]count] > 0);
        
    }
    else if (action==@selector(decreaseFont:)) {
        enabled = ([[_treesController arrangedObjects]count] > 0 && _fontSize > 1);
        
    }
    else if ( action == @selector(selectAll:)){
        if( [[_treesController arrangedObjects] count] > 0 ){
            MFTree *tree = [[_treesController selectedObjects]objectAtIndex:0];
            enabled = [tree nodeCount] != [[_treeView selectedNodes]count];
        }
    }
    else if ( action == @selector(selectNone:)){
        if( [[_treesController arrangedObjects] count] > 0 ){
            enabled = [[_treeView selectedNodes]count] != 0;
        }
    }
    else if ( action == @selector(invertSelection:)){
        enabled = ([[_treesController arrangedObjects]count] > 0);
    }
    else if ( action == @selector(rotateNodeAction:)){
        enabled = ([[_treesController arrangedObjects]count] > 0 && self.selectionMode > 0 && [_selectedNodes count]==1 );
    }
    else if ( action == @selector(rerootAction:)){
        enabled = ([[_treesController arrangedObjects]count] > 0 && self.selectionMode > 0 && [_selectedNodes count]==1 );
    }
    else if ( action == @selector(ladderize:)){
        enabled = [[_treesController arrangedObjects]count] > 0;
    }
    else if (action == @selector(find:) ){
        enabled = [[_searchField stringValue] length] > 0 && [[_treesController arrangedObjects] count] > 0;
    }
    else if (action == @selector(popUpButtonInternalNodesAction:) ){
        enabled = YES;
    }
    else if (action == @selector(copy:) ){
        enabled = [[_treesController arrangedObjects] count] > 0;
    }
    else if (action == @selector(printDocument:) ){
        enabled = [[_treesController arrangedObjects] count] > 0;
    }
    else if (action == @selector(exportPDF:) ){
        enabled = [[_treesController arrangedObjects] count] > 0;
    }
    else if (action==@selector(newDocumentWindow:)) {
        // Give the menu item that creates new sibling windows for this document a reasonably descriptive title. It's important to use the document's "display name" in places like this; it takes things like file name extension hiding into account. We could do a better job with the punctuation!
        [menuItem setTitle:[NSString stringWithFormat:NSLocalizedStringFromTable(@"New window for '%@'", @"MenuItems", @"Formatter string for the new document window menu item. Argument is a the display name of the document."), [[self document] displayName]]];
        enabled = YES;
        
    }
    else {
        enabled = [super validateMenuItem:menuItem];
    }
    return enabled;
    
}


- (IBAction)newDocumentWindow:(id)sender {
    
    // Do the same thing that a typical override of -[NSDocument makeWindowControllers] would do, but then also show the window.
    // This is here instead of in MFDocument, though it would work there too, with one small alteration, because it's really view-layer code.
    MFTreeWindowController *windowController = [[MFTreeWindowController alloc] init];
    [[self document] addWindowController:windowController];
    [windowController showWindow:self];
    [windowController release];
    
}


- (IBAction)selectAll:(id)sender {
    NSMutableArray *array = [[NSMutableArray alloc]init];
    if( self.selectionMode == 0 ){
        [[[_treesController selectedObjects]objectAtIndex:0] enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPreorder usingBlock:^(MFNode *node){
            if([node isLeaf]) [array addObject:node];
        }];
    }
    else {
        [[[_treesController selectedObjects]objectAtIndex:0] enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPreorder usingBlock:^(MFNode *node){
            [array addObject:node];
        }];
    }
    [self setSelectedNodes: array];
    [array release];
}

- (IBAction)selectNone:(id)sender {
    [self setSelectedNodes: [NSArray array]];
}

-(IBAction)invertSelection:(id)sender{
    NSArray *selection = [_treeView selectedNodes];
    NSMutableArray *array = [[NSMutableArray alloc]init];
    if( self.selectionMode == 0 ){
        [[[_treesController selectedObjects]objectAtIndex:0] enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPreorder usingBlock:^(MFNode *node){
            if( [node isLeaf] && [selection indexOfObject:node] == NSNotFound )[array addObject:node];
        }];
    }
    else{
        [[[_treesController selectedObjects]objectAtIndex:0] enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPreorder usingBlock:^(MFNode *node){
            if( [selection indexOfObject:node] == NSNotFound )[array addObject:node];
        }];
    }
    [self setSelectedNodes:array];
    [array release];
}

- (IBAction)zoomIn:(id)sender {
    [_treeView incrementTaxonSpacing:1];
}

- (IBAction)zoomOut:(id)sender {
    [_treeView incrementTaxonSpacing:-1];
}

- (IBAction)zoomInWidth:(id)sender {
    [_treeView incrementWidth:5];
}

- (IBAction)zoomOutWidth:(id)sender {
    [_treeView incrementWidth:-5];
}

- (IBAction)zoomImageToActualSize:(id)sender {
    //[_treeView defaultTaxonSpacing];
    [_treeView setDefaultSize];
}

-(IBAction)toggleSowTaxa:(id)sender{
    
}

-(IBAction)popUpButtonInternalNodesAction:(id)sender{
    if([sender indexOfSelectedItem] == 0 ){
        [_treeView showBranchAttribute:@""];
    }
    else {
        [_treeView showBranchAttribute:[sender titleOfSelectedItem]];
    }
}

- (IBAction)rotateNodeAction:(id)sender{
    [_treeView rotateSelectedBranch];
}

- (IBAction)rerootAction:(id)sender{
    [_treeView rootAtSelectedBranch];
}

- (IBAction)find:(id)sender {
    NSString *searchKey = [_searchField stringValue];
    if( [searchKey length] > 0 ){
        MFTree *tree = [[_treesController selectedObjects]objectAtIndex:0];
        NSMutableArray *selection = [self findNodes:tree withString:searchKey];
        [self setSelectedNodes:selection];
    }
    else {
        [_searchNodes removeAllObjects];
    }
    
    // _searchField gives up focus so we can change attributes of nodes (e.g. background color...)
    dispatch_async(dispatch_get_main_queue(), ^{[_searchField.window makeFirstResponder:nil];});
}

-(void)findNodes:(MFNode*)node nodes:(NSMutableArray*)nodes withString:(NSString*)str{
    if( ![node isLeaf]){
        for ( NSUInteger i = 0; i < [node childCount]; i++ ) {
            [self findNodes:[node childAtIndex:i] nodes:nodes withString:str];
        }
    }
    else {
        NSRange match = [[node name] rangeOfString:str options:NSCaseInsensitiveSearch range:NSMakeRange(0, [[node name] length])];
        if(match.location != NSNotFound){
            [nodes addObject:node];
        }
    }
}

-(NSMutableArray*)findNodes:(MFTree*)tree withString:(NSString*)str{
    NSMutableArray *selection = [[NSMutableArray alloc]init];
    [self findNodes:[tree root] nodes:selection withString:str];
    return [selection autorelease];
}

- (void)controlTextDidChange:(NSNotification *) notification {
    self.selectionMode = 0;
}


- (NSArray*)attributesFromSelectedTree{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    MFTree *tree = [[_treesController selectedObjects] objectAtIndex:0];
    
    [tree enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPostorder usingBlock:^(MFNode *node){
        for (NSString *key in [[node attributes]allKeys]) {
            if ( ![key hasPrefix:@"?"]) {
                [dict setObject:@"" forKey:key];
            }
        }
    }];
    return [dict allKeys];
}


// Conformance to the NSObject(NSColorPanelResponderMethod) informal protocol.
- (void)changeColor:(id)sender {
    // Change the color of every selected graphic.
    [_treeView setColorForSelected:[sender color]];

}

- (IBAction)defaultFontSize:(id)sender{
    [_treeView setFontSize:[[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultTreeFontSize"]floatValue]];
}

- (IBAction)increaseFont:(id)sender{
    _fontSize++;
    [_treeView setFontSize:_fontSize];
}


- (IBAction)decreaseFont:(id)sender{
    if(_fontSize > 1){
        _fontSize--;
        [_treeView setFontSize:_fontSize];
    }
}

// do not use selectedFont with changeFont:
// https://developer.apple.com/library/mac/documentation/Cocoa/Reference/ApplicationKit/Classes/NSFontManager_Class/Reference/Reference.html#//apple_ref/occ/instm/NSObject/changeFont%3a
- (void)changeFont:(id)sender {
    _font = [sender convertFont:_font];
    // Change the color of every selected graphic.
    //[[self selectedGraphics] makeObjectsPerformSelector:@selector(setColor:) withObject:[sender color]];
    
}

//- (void)changeAttributes:(id)sender {
//    //NSFontEffectsBox *box = sender;
//    NSDictionary *dict;
//    NSDictionary* newAttrs = [sender convertAttributes:dict];
//    NSLog(@"attributes %@", newAttrs);
//}


-(IBAction)copy:(id)sender{
    if( [[_treesController selectedObjects] count] > 0 ){
        NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
        [pasteboard clearContents];
        MFTree *tree = [[_treesController selectedObjects]objectAtIndex:0];
        NSArray *array = [NSArray arrayWithObject: [tree newick]];
        [pasteboard writeObjects:array];
    }
}

- (IBAction)ladderize:(id)sender{
    if( [[_treesController selectedObjects] count] > 0 ){
        MFTree *tree = [[_treesController selectedObjects]objectAtIndex:0];
        [tree ladderize];
        [_treeView reloadData];
    }
}

- (IBAction)printDocument:(id)sender{
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:_treeView];
    if (op){
        [op runOperation];
    }
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
            NSRect r = [_treeView bounds];
            NSData *data = [_treeView dataWithPDFInsideRect:r];
            
            [data writeToURL:theFile atomically:YES];
        }
    }];
}

#pragma mark *** Toolbar ***


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
    if ([itemIdentifier isEqualToString:kArrowsToolbarItemID])
    {
        // 1) Navigation toolbar item
        toolbarItem = [self toolbarItemWithIdentifier:kArrowsToolbarItemID
                                                label:@"Previous/Next"
                                          paleteLabel:@"Navigation"
                                              toolTip:@"Tree selection"
                                               target:self
                                          itemContent:_arrowsView
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
    return [NSArray arrayWithObjects:   kArrowsToolbarItemID,
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
    return [NSArray arrayWithObjects: kArrowsToolbarItemID,
            nil];
    // note:
    // that since our toolbar is defined from Interface Builder, an additional separator and customize
    // toolbar items will be automatically added to the "default" list of items.
}


@end
