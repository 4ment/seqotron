//
//  MFPrefsWindowController.m
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

#import "MFPrefsWindowController.h"

#import "MFColorManager.h"
#import "MFString.h"
#import "MFSequence.h"

@interface MFPrefsWindowController ()

@end

@implementation MFPrefsWindowController

@synthesize schemes = _schemes;
@synthesize sequences = _sequences;

unsigned long row_index( unsigned long i, unsigned long M ){
    double m = M;
    double row = (-2*m - 1 + sqrt( (4*m*(m+1) - 8*(double)i - 7) )) / -2;
    if( row == (double)(long) row ) row -= 1;
    return (unsigned long) row;
}


unsigned long column_index( unsigned long i, unsigned long M ){
    unsigned long row = row_index( i, M);
    return  i - M * row + row*(row+1) / 2;
}

- (id)init {
    if (self = [super initWithWindowNibName:@"MFPrefs"]) {
        _schemes = [[NSMutableArray alloc]init];
        _colors  = [[NSMutableDictionary alloc]init];
        _selectedDatatypeSegment = 0;
        [_segmentedDataType setSelectedSegment:_selectedDatatypeSegment];
        _editingForeground = NO;
        _newScheme = NO;
        _newSchemeFilename = nil;
        _currentScheme = nil;
        _sequences = [[NSMutableArray alloc]init];
    }
    return self;
}

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_alignmentView unbind:@"sequences"];
    [_schemes release];
    [_colors release];
    [_sequences release];
    [_newSchemeFilename release];
    [_currentScheme release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    NSLog(@"MFPrefsWindowController windowDidLoad");

    NSString *type = [_segmentedDataType labelForSegment:[_segmentedDataType selectedSegment]];
    [self setUpSchemes:type];
    [self setUpColoring:type];
    [self setUpMatrix];
    
    //NSRect frame = [_alignmentView frame];
    //NSUInteger count = frame.size.height/_alignmentView.residueHeight;
    MFSequence *seq;
    seq = [[MFSequence alloc]initWithString:@"ATGACTGACTGTCTGCTTAAGCGAAU-GACGATCGTTATCCTGAATTCATGACTGACTGTCTGCTTAAGCGAACAGACGATTAA" name:@"1"]; [_sequences addObject:seq]; [seq release];
    seq = [[MFSequence alloc]initWithString:@"ATGA-TCACTGCGCTAGCTGTCATCU-AAGCTTCGTTATCCTGAATTCATGA-TCACTGCGCTAGCTGTCATCGAAAGCTTTAA" name:@"2"]; [_sequences addObject:seq]; [seq release];
    seq = [[MFSequence alloc]initWithString:@"ATGACTAAGTGCGTAGCTAGCCAGCU-AACGTTCGTTATCCTGAATTCATGACTAAGTGCGTAGCTAGCCAGCTAAACGTTTAA" name:@"3"]; [_sequences addObject:seq]; [seq release];
    seq = [[MFSequence alloc]initWithString:@"ATGA?TAAGTGGCTAGCAGCTCGCTU-CAGATTCGTTATCCTGAATTCATGA?TAAGTGGCTAGCAGCTCGCCAACAGATTTAA" name:@"4"]; [_sequences addObject:seq]; [seq release];
    seq = [[MFSequence alloc]initWithString:@"ATGACTAACTCACACACGTGCCGTCU-GATGCTCGTTATCCTGAATTCATGACTAACTCACACACGTGCCGTCGAGATGCTTAA" name:@"5"]; [_sequences addObject:seq]; [seq release];
    seq = [[MFSequence alloc]initWithString:@"ATGACTGACTGGTCGTGCTAGCTGAU-GAGCATCGTTATCCTGAATTCATGACTGACTGGTCGTGCTAGCTGATAGAGCATTAA" name:@"6"]; [_sequences addObject:seq]; [seq release];
    
    NSDictionary *geneticCode = [self geneticTable];
    for (MFSequence *sequence in _sequences) {
        [sequence setGeneticTable:geneticCode];
    }
    [_alignmentView bind:@"sequences" toObject:self withKeyPath:@"sequences" options:nil];
    [self setUpAlignment];
    
    
    _currentScheme = [[[[_schemeController selectedObjects] objectAtIndex:0] objectForKey:@"desc"]copy];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tableViewEditingDidEnd:)
                                                 name:NSControlTextDidEndEditingNotification object:nil];
}

-(NSDictionary*)geneticTable{
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"GeneticCodeTables"];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
    NSDictionary *geneticTable = nil;
    
    for ( NSString *file in dirFiles) {
        if ( [file hasSuffix:@"plist"] ) {
            NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
            if( [[dict objectForKey:@"Description"] isEqualToString:@"Standard"]){
                geneticTable = [[NSDictionary alloc]initWithDictionary:[dict objectForKey:@"Table"]];
                [dict release];
                break;
            }
            [dict release];
        }
    }
    return [geneticTable autorelease];
}

- (void)setupToolbar{
    [self addView:_colorView label:@"Coloring" image:[NSImage imageNamed:NSImageNameColorPanel]];
}

#pragma mark *** Action Methods ***

// NSMatrix action
-(IBAction)click:(id)sender{
    
    // If we try to edit a scheme from the bundle then create a copy of it
    if ( [_schemeController selectionIndex] < _firstUserIndex ) {
        NSString *type = [_segmentedDataType labelForSegment:[_segmentedDataType selectedSegment]];
        NSString *scheme = [[[_schemeController selectedObjects] objectAtIndex:0] objectForKey:@"desc"];
        NSString *path = [[MFColorManager applicationColorDirectory] stringByAppendingPathComponent:type];
        NSString *newScheme = [self duplicateScheme:scheme fromDirectory:path];

        [self setUpSchemes:type];
        
        NSArray *schemesDesc = [self schemesDescription];
        NSUInteger newIndex = [schemesDesc indexOfObject:newScheme];
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
    }
    
    NSButtonCell *cell = [sender selectedCell];
    NSColorPanel *cp = [NSColorPanel sharedColorPanel];
    
    // colorUpdate would be called wehn assigning the color to cp.color
    if( [cp isVisible] ){
        [cp setAction:nil];
    }
    
    NSAttributedString *attTitle = [cell attributedTitle];
    NSRange effectiveRange = NSMakeRange(0, 0);
    if (([[NSApp currentEvent] modifierFlags] & NSCommandKeyMask) != 0 ){
        cp.color = [attTitle attribute:NSBackgroundColorAttributeName atIndex:0 effectiveRange:&effectiveRange];
        _editingForeground = NO;
    }
    else{
        _editingForeground = YES;
        cp.color = [attTitle attribute:NSForegroundColorAttributeName atIndex:0 effectiveRange:&effectiveRange];
    }
    
    [cp setDelegate:self];
    [cp orderFront:nil];
    [cp setTarget:self];
    [cp setAction:@selector(colorUpdate:)];
    
}

-(IBAction)datatypeSelector:(id)sender{
    if( _selectedDatatypeSegment != [_segmentedDataType selectedSegment] ){
        NSString *type = [_segmentedDataType labelForSegment:[_segmentedDataType selectedSegment]];
        for (MFSequence *seq in _sequences) {
            [seq setTranslated:!seq.translated];
        }
        [self setUpSchemes:type];
        [self setUpColoring:type];
        [self setUpMatrix];
        [self setUpAlignment];
        
        _selectedDatatypeSegment = [_segmentedDataType selectedSegment];
    }
}


-(IBAction)createOrDeleteAction:(id)sender{
    if( [_tableView selectedRow] == -1 )return;
    
    NSSegmentedControl *control = sender;
    NSString *type = [_segmentedDataType labelForSegment:[_segmentedDataType selectedSegment]];
    
    // Duplicate
    if( [control selectedSegment] == 0 ){
        
        NSString *path;
        NSString *scheme =[[[_schemeController selectedObjects] objectAtIndex:0] objectForKey:@"desc"];
        
        if( [_schemeController selectionIndex] < _firstUserIndex){
            path = [MFColorManager applicationColorDirectory];
        }
        else {
            path = [MFColorManager userColorDirectory];
        }
        
        [path stringByAppendingPathComponent:type];
        
        
        NSString *newScheme = [self duplicateScheme:scheme fromDirectory:path];
        
        [self setUpSchemes:type];
        
        NSArray *schemesDesc = [self schemesDescription];
        NSUInteger newIndex = [schemesDesc indexOfObject:newScheme];
        [_tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
        
        NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:type, @"datatype",@"add",@"type",newScheme,@"file", nil];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MFColoringDidChange" object:self userInfo:info];
    }
    // Remove
    else {
        NSAlert *alert = [[[NSAlert alloc] init]autorelease];
        NSString *scheme = [[[_schemeController selectedObjects] objectAtIndex:0] objectForKey:@"desc"];
        [alert setInformativeText:[NSString stringWithFormat:@"Do you want to delete %@ color scheme", scheme]];
        [alert setMessageText:@"Delete scheme"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Delete"];
        
        
        [alert beginSheetModalForWindow:[NSApp mainWindow] completionHandler:^(NSInteger result) {
            
            // Cancel
            if (result == NSAlertFirstButtonReturn) {
                
            }
            // Delete
            else if (result == NSAlertSecondButtonReturn) {
                NSString *path = [[MFColorManager userColorDirectory] stringByAppendingPathComponent:type];
                
                [self removeScheme: scheme fromDirectory:path];
                
                [self setUpSchemes:type];
                [self setUpColoring:type];
                [self setUpMatrix];
                [self setUpAlignment];
                
                NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:type,@"datatype", @"delete",@"type", scheme,@"file", nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"MFColoringDidChange" object:self userInfo:info];
            }
        }];
        
    }
}

#pragma mark *** Methods ***

-(void)setUpAlignment{
    [_alignmentView setForegroundColor:[_colors objectForKey:NSForegroundColorAttributeName]];
    if ( [_colors objectForKey:NSBackgroundColorAttributeName] ) {
        [_alignmentView setBackgroundColor:[_colors objectForKey:NSBackgroundColorAttributeName]];
    }
    else{
        [_alignmentView setBackgroundColor:[NSMutableDictionary dictionary]];
    }
    [_alignmentView setNeedsDisplay:YES];
}

-(void)setUpMatrix{
    NSUInteger i = 0;
    NSUInteger row = 0;
    NSUInteger col = 0;

    NSDictionary *foregroundColor = [_colors objectForKey:NSForegroundColorAttributeName];
    NSDictionary *backgroundColor = nil;
    //NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Courier" size:12], NSFontAttributeName, nil];
    if( [_colors objectForKey:NSBackgroundColorAttributeName] ){
        backgroundColor = [_colors objectForKey:NSBackgroundColorAttributeName];
    }
    
    for ( NSString *residue in foregroundColor ) {
        row = row_index(i, [_matrix numberOfColumns]*[_matrix numberOfRows]);
        col = column_index(i, [_matrix numberOfColumns]*[_matrix numberOfRows]);

        NSButtonCell *cell = [_matrix cellAtRow:row column:col];
        
        // Foreground
        NSColor *color = [foregroundColor objectForKey:residue];
        //NSString *r = [NSString stringWithFormat:@" %@  ",residue];
        //NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithString:r attributes:attrs];
        NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithString:residue];
        
        NSRange titleRange = NSMakeRange(0, [colorTitle length]);
        
        [colorTitle addAttribute:NSForegroundColorAttributeName value:color range:titleRange];
        
        
        // Background
        if ( backgroundColor != nil && [backgroundColor objectForKey:residue] ) {
            color = [backgroundColor objectForKey:residue];
        }
        else {
            color = [NSColor whiteColor];
        }
        [colorTitle addAttribute:NSBackgroundColorAttributeName value:color range:titleRange];
        //[cell setBackgroundColor:color];
        [cell setAttributedTitle:colorTitle];
        [colorTitle release];
        
        [cell setTransparent:NO];
        [cell setEnabled:YES];
        
        i++;
    }
    
    for ( ; i < [_matrix numberOfColumns]*[_matrix numberOfRows]; i++ ) {
        row = row_index(i, [_matrix numberOfColumns]*[_matrix numberOfRows]);
        col = column_index(i, [_matrix numberOfColumns]*[_matrix numberOfRows]);
        
        NSButtonCell *cell = [_matrix cellAtRow:row column:col];
        [cell setTransparent:YES];
        [cell setEnabled:NO];
    }
}

-(void)setUpSchemes:(NSString*)type{
    
    _firstUserIndex = 0;
    
    [self willChangeValueForKey:@"schemes"];
    [self.schemes removeAllObjects];
      
    NSString *path = [[MFColorManager applicationColorDirectory]stringByAppendingPathComponent:type];
    NSArray *scs = [MFColorManager colorSchemesWithInfoAtPath:path];
    [self.schemes addObjectsFromArray:scs];
    
    if( scs != nil && [scs count] > 0 ){
        _firstUserIndex = [scs count];
    }
    
    path = [[MFColorManager userColorDirectory]stringByAppendingPathComponent:type];
    scs = [MFColorManager colorSchemesWithInfoAtPath:path];
    [self.schemes addObjectsFromArray:scs];

    [self didChangeValueForKey:@"schemes"];
    
}

-(void)setUpColoring:(NSString*)type{
    [_colors removeAllObjects];
    
    NSString *scheme = [[[_schemeController selectedObjects] objectAtIndex:0] objectForKey:@"desc"];
    
    NSString *path = [[MFColorManager applicationColorDirectory]stringByAppendingPathComponent:type];
    
    if( _firstUserIndex > 0 ){
        NSDictionary *dict = [MFColorManager coloring:scheme fromPath:path];
        [_colors addEntriesFromDictionary:dict];
    }
    
    path = [[MFColorManager userColorDirectory]stringByAppendingPathComponent:type];
    NSDictionary *dict = [MFColorManager coloring:scheme fromPath:path];
    if( dict != nil){
        [_colors addEntriesFromDictionary:dict];
    }
}

-(void)removeScheme:(NSString*)scheme fromDirectory:(NSString*)dirPath{
    
    NSError *error = nil;
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dirPath error:&error];
    if( !error ){
        for ( NSString *file in dirFiles) {
            if ( [file hasSuffix:@"plist"] ) {
                NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[dirPath stringByAppendingPathComponent:file]];
                
                if( [[dict objectForKey:@"Description"] isEqualToString:scheme] ){
                    error = nil;
                    
                    [[NSFileManager defaultManager] removeItemAtPath:[dirPath stringByAppendingPathComponent:file] error:&error];
                    if ( !error ) {
                        [self willChangeValueForKey:@"schemes"];
                        [self.schemes removeObject: scheme];
                        [self didChangeValueForKey:@"schemes"];
                    }
                    [dict release];
                    return;
                }
                
                [dict release];
            }
        }
    }
    
}

- (NSString*)duplicateScheme:(NSString*)scheme fromDirectory:(NSString*)dir{
    NSError *error = nil;
    NSString *dirPath = [MFColorManager userColorDirectory];
    
    NSUInteger counter = 0;
    NSArray *schemesDesc = [self schemesDescription];
    while([schemesDesc indexOfObject:[scheme stringByAppendingFormat:@" %lu", counter] ] != NSNotFound ){
        counter++;
    }
    NSString *newScheme = nil;
    
    [[NSFileManager defaultManager]createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    if(!error){
        newScheme = [scheme stringByAppendingFormat:@" %lu", counter];
        NSString *path = [MFColorManager userColorDirectory];
        NSString *type = [_segmentedDataType labelForSegment:[_segmentedDataType selectedSegment]];
        path = [path stringByAppendingPathComponent:type];
        
        NSString *saveFileName = [NSString stringRandomWithLength:10];
        NSString *saveFileFullPath = [path stringByAppendingPathComponent:saveFileName];
        while ( [[NSFileManager defaultManager]fileExistsAtPath:saveFileFullPath] ) {
            saveFileName = [NSString stringRandomWithLength:10];
            saveFileFullPath = [path stringByAppendingPathComponent:saveFileName];
        }
        [self saveCurrentScheme: newScheme toDirectory:path fileName:saveFileName];
        
        _newSchemeFilename = [saveFileName copy];
    }
    return newScheme;
}

-(void)saveCurrentScheme:(NSString*)schemeDesc toDirectory:(NSString*)dirPath fileName:(NSString*)fileName{
    NSError *error = nil;
    [[NSFileManager defaultManager]createDirectoryAtPath:dirPath withIntermediateDirectories:YES attributes:nil error:&error];
    
    if( !error ){
        NSString *file = [NSString stringWithFormat:@"%@.plist",fileName];
        NSString *plistPath = [dirPath stringByAppendingPathComponent:file];
        
        NSMutableDictionary *plistDict = [[NSMutableDictionary alloc]init];
        [plistDict setObject:schemeDesc forKey:@"Description"];
        
        NSMutableDictionary *fg = [[NSMutableDictionary alloc]init];
        NSDictionary *colors = [_colors objectForKey:NSForegroundColorAttributeName];
        for (NSString *residue in colors) {
            NSColor *col = [colors objectForKey:residue];
            // https://developer.apple.com/library/mac/documentation/cocoa/Conceptual/DrawColor/Tasks/UsingColorSpaces.html#//apple_ref/doc/uid/TP40001807-97360-BCIHDDFF
            NSColor *rgbColor = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
            CGFloat red;
            CGFloat green;
            CGFloat blue;
            CGFloat alpha;
            [rgbColor getRed:&red green:&green blue:&blue alpha:&alpha];
            
            [fg setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:red], [NSNumber numberWithFloat:green], [NSNumber numberWithFloat:blue], [NSNumber numberWithFloat:alpha], nil] forKey:residue];
        }
        [plistDict setObject:fg forKey:@"Foreground"];
        [fg release];
        
        if( [_colors objectForKey:NSBackgroundColorAttributeName] != nil ){
            NSDictionary *colors = [_colors objectForKey:NSBackgroundColorAttributeName];
            NSMutableDictionary *bg = [[NSMutableDictionary alloc]init];
            for (NSString *residue in colors) {
                NSColor *col = [colors objectForKey:residue];
                NSColor *rgbColor = [col colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
                CGFloat red;
                CGFloat green;
                CGFloat blue;
                CGFloat alpha;
                [rgbColor getRed:&red green:&green blue:&blue alpha:&alpha];
                
                [bg setObject:[NSArray arrayWithObjects:[NSNumber numberWithFloat:red], [NSNumber numberWithFloat:green], [NSNumber numberWithFloat:blue], [NSNumber numberWithFloat:alpha], nil] forKey:residue];
            }
            [plistDict setObject:bg forKey:@"Background"];
            [bg release];
        }
        
        NSError *err = nil;
        NSData *plistData = [NSPropertyListSerialization dataWithPropertyList:plistDict format:NSPropertyListXMLFormat_v1_0 options:0 error:&err];
        
        [plistData writeToFile:plistPath atomically:YES];
        [plistDict release];
    }
}

-(void)colorUpdate:(NSColorPanel*)colorPanel{
    NSColor* theColor = colorPanel.color;
    NSButtonCell * cell = [_matrix selectedCell];
    NSMutableAttributedString *colorTitle = [[NSMutableAttributedString alloc] initWithAttributedString:[cell attributedTitle]];
    NSString *title = [cell title];
    
    if ( !_editingForeground ){
        
        if( [_colors objectForKey:NSBackgroundColorAttributeName] == nil ){
            NSMutableDictionary *bg = [[NSMutableDictionary alloc]init];
            
            NSUInteger i = 0;
            NSUInteger row = 0;
            NSUInteger col = 0;
            
            for ( NSString *residue in [_colors objectForKey:NSForegroundColorAttributeName] ) {
                
                row = row_index(i, [_matrix numberOfColumns]*[_matrix numberOfRows]);
                col = column_index(i, [_matrix numberOfColumns]*[_matrix numberOfRows]);
                
                cell = [_matrix cellAtRow:row column:col];
                
                NSColor *color;
                if( [residue isEqualToString:title] ){
                    color = theColor;
                }
                else {
                    color = [NSColor whiteColor];
                }
                [[colorTitle mutableString]setString:residue];
                [colorTitle addAttribute:NSBackgroundColorAttributeName value:color range:NSMakeRange(0, [colorTitle length])];
                [colorTitle addAttribute:NSForegroundColorAttributeName value:[[_colors objectForKey:NSForegroundColorAttributeName]objectForKey:residue] range:NSMakeRange(0, [colorTitle length])];
                [cell setAttributedTitle:colorTitle];
                
                [bg setObject:color forKey:residue];
                
                i++;
            }
            [_colors setObject:bg forKey:NSBackgroundColorAttributeName];
            [bg release];
        }
        else {
            [colorTitle addAttribute:NSBackgroundColorAttributeName value:theColor range:NSMakeRange(0, [colorTitle length])];
            [cell setAttributedTitle:colorTitle];
            
            [[_colors objectForKey:NSBackgroundColorAttributeName]setObject:theColor forKey:[cell title]];
        }
    }
    else{
        [colorTitle addAttribute:NSForegroundColorAttributeName value:theColor range:NSMakeRange(0, [colorTitle length])];
        [cell setAttributedTitle:colorTitle];
        
        [[_colors objectForKey:NSForegroundColorAttributeName]setObject:theColor forKey:[cell title]];
    }
    [self setUpAlignment];
    [colorTitle release];
    _newScheme = YES;
    
}

-(NSArray*)schemesDescription{
    NSMutableArray *schemesDesc = [[NSMutableArray alloc]init];
    for (NSDictionary *dict in self.schemes) {
        [schemesDesc addObject:[dict objectForKey:@"desc"]];
    }
    return [schemesDesc autorelease];
}

#pragma mark *** NSWindowDelegate Delegate Methods ***

- (void)windowWillClose:(NSNotification *)notification {
    
    [[NSColorPanel sharedColorPanel] setAction:nil];
    
    if ([notification.object isEqual:[NSColorPanel sharedColorPanel]]) {
        if(_newScheme){
            NSString *scheme = [[[_schemeController selectedObjects] objectAtIndex:0] objectForKey:@"desc"];
            NSString *type = [_segmentedDataType labelForSegment:[_segmentedDataType selectedSegment]];
            NSString *path = [[MFColorManager userColorDirectory] stringByAppendingPathComponent:type];
            [self saveCurrentScheme:scheme toDirectory:path fileName:_newSchemeFilename];
            _newScheme = NO;
            NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:type,@"datatype", @"modify",@"type", scheme,@"file", nil];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"MFColoringDidChange" object:self userInfo:info];
        }
    }
    else {
        [[NSColorPanel sharedColorPanel] close];
    }
}

#pragma mark *** NSTableView Delegate Methods ***

- (void)tableViewSelectionDidChange:(NSNotification *)notification{
    NSInteger index = [_tableView selectedRow];
    
    if( index >= 0){
        NSString *type = [_segmentedDataType labelForSegment:[_segmentedDataType selectedSegment]];
        [self setUpSchemes:type];
        [self setUpColoring:type];
        [self setUpMatrix];
        [self setUpAlignment];
        
        if ( index < _firstUserIndex ) {
            [_segmented setEnabled:NO forSegment:1];
        }
        else {
            [_segmented setEnabled:YES forSegment:1];
        }
        NSString *scheme = [[[_schemeController selectedObjects] objectAtIndex:0] objectForKey:@"desc"];
        [_currentScheme release];
        _currentScheme = [scheme copy];
    }
    
}

// Does not allow row selection to be modified if the color panel is visible
- (BOOL)selectionShouldChangeInTableView:(NSTableView *)aTableView{
    return ![[NSColorPanel sharedColorPanel]isVisible];
}


- (BOOL)tableView:(NSTableView *)aTableView shouldEditTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex{
    return (rowIndex >=  _firstUserIndex);
}


- (void)tableViewEditingDidEnd:(NSNotification *)notification {
    NSString *type = [_segmentedDataType labelForSegment:[_segmentedDataType selectedSegment]];
    NSString *path = [[MFColorManager userColorDirectory] stringByAppendingPathComponent:type];
    NSDictionary *scheme = [[_schemeController selectedObjects] objectAtIndex:0];
    [self saveCurrentScheme:[scheme  objectForKey:@"desc"] toDirectory:path fileName:[scheme  objectForKey:@"file"]];
    
    NSDictionary *info = [NSDictionary dictionaryWithObjectsAndKeys:type,@"datatype", @"rename",@"type", [scheme  objectForKey:@"desc"],@"file", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"MFColoringDidChange" object:self userInfo:info];
}

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor{
    return [[fieldEditor string]length] != 0;
}

@end
