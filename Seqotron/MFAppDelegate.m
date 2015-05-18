//
//  MFAppDelegate.m
//  Seqotron
//
//  Created by Mathieu Fourment on 25/01/14.
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

#import "MFAppDelegate.h"


#import "MFColorManager.h"
#import "MFDocument.h"
#import "MFTreeWindowController.h"

#pragma mark *** NSWindowController Conveniences ***


@interface NSWindowController(MFConvenience)
- (BOOL)isWindowShown;
- (void)showOrHideWindow;
@end

@implementation NSWindowController(MFConvenience)


- (BOOL)isWindowShown {
    
    // Simple.
    return [[self window] isVisible];
    
}


- (void)showOrHideWindow {
    
    // Simple.
    NSWindow *window = [self window];
    if ([window isVisible]) {
        [window orderOut:self];
    } else {
        [self showWindow:self];
    }
    
}


@end

@implementation MFAppDelegate

@synthesize sharedOperationQueue;
@synthesize coloringMenu,geneticCodeMenu;

- (id) init {
    if ( self = [super init] ) {
        sharedOperationQueue = [[NSOperationQueue alloc] init];
        preferenceController = nil;
    }
    return self;
}

+ (void)initialize {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
    // Sequences
    [defaults setObject:[NSNumber numberWithFloat:15] forKey:@"MFDefaultSequenceFontSize"];
    [defaults setObject:@"Courier" forKey:@"MFDefaultSequenceFontName"];
    [defaults setObject:[NSNumber numberWithFloat:4] forKey:@"MFDefaultSequenceColumnSpacing"];
    [defaults setObject:[NSNumber numberWithFloat:2] forKey:@"MFDefaultSequenceRowSpacing"];
    
    // Trees
    [defaults setObject:[NSNumber numberWithFloat:12] forKey:@"MFDefaultTreeFontSize"];
    [defaults setObject:@"Courier" forKey:@"MFDefaultTreeFontName"];
    
    [defaults setObject:@"Coloring" forKey:@"MFColoringDirectory"];
    
    // Not used
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"NSDisabledDictationMenuItem"];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"NSDisabledCharacterPaletteMenuItem"];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaults];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    NSLog(@"applicationDidFinishLaunching");
    NSError *error = nil;
    NSURL *cacheDir = [[NSFileManager defaultManager] URLForDirectory:NSCachesDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    
    NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
    NSString *tempPath = [[[cacheDir path] stringByAppendingPathComponent:executableName]stringByAppendingPathComponent:@"temp"];
    [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    NSLog(@"Color user directory %@", [MFColorManager userColorDirectory]);
    
    [[NSColorPanel sharedColorPanel]setRestorable:NO];
    [[NSFontPanel sharedFontPanel]setRestorable:NO];

    [self setUpColoringMenu];
    [self setUpGeneticCodeMenu];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(coloringNotification:) name:@"MFColoringDidChange" object:nil];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter]removeObserver:self];
    [sharedOperationQueue release];
    [preferenceController release];
    [super dealloc];
}

// Conformance to the NSObject(NSMenuValidation) informal protocol.
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    
    BOOL enabled = NO;
    SEL action = [menuItem action];
    
    if (action==@selector(showPreferencePanel:) ) {
        enabled = YES;
    }
    else {
        enabled = [super validateMenuItem:menuItem];
    }
    return enabled;
    
}

- (IBAction)showPreferencePanel:(id)sender{
    if ( !preferenceController ){
        preferenceController = [[MFPrefsWindowController alloc]init];
    }
    [preferenceController showOrHideWindow];
}

- (void)setUpGeneticCodeMenu{
    // Set up the genetic code menu
    NSArray *geneticCodes = [self loadGeneticCodes];
    NSInteger tag = 0;
    for (NSString *gc in geneticCodes) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:gc action:@selector(geneticCodeAction:) keyEquivalent:@""];
        [item setTarget:nil];
        [item setTag:tag];
        [geneticCodeMenu addItem:item];
        [item release];
        tag++;
    }
}

- (void)setUpColoringMenu{
    // Set up the color scheme menu
    NSInteger tag = 0;
    NSMenu *nucMenu = [[coloringMenu itemAtIndex:0]submenu];
    for (NSString *scheme in [self loadColorSchemes:@"Nucleotide"]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:scheme action:@selector(colorSchemeAction:) keyEquivalent:@""];
        [item setTarget:nil];
        [item setTag:tag];
        [nucMenu addItem:item];
        [item release];
        tag++;
    }
    tag = 0;
    
    NSMenu *protMenu = [[coloringMenu itemAtIndex:1]submenu];
    for (NSString *scheme in [self loadColorSchemes:@"Amino acid"]) {
        NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:scheme action:@selector(colorSchemeAction:) keyEquivalent:@""];
        [item setTarget:nil];
        [item setTag:tag];
        [protMenu addItem:item];
        [item release];
        tag++;
    }
}

- (void)coloringNotification:(NSNotification *)notification {
    [[[coloringMenu itemAtIndex:0]submenu]removeAllItems];
    [[[coloringMenu itemAtIndex:1]submenu]removeAllItems];
    [self setUpColoringMenu];
}

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

-(NSMutableArray*)loadColorSchemes:(NSString*)type{
    NSMutableArray *colorSchemes = [[NSMutableArray alloc]init];
    NSString *coloringFolder = [[NSUserDefaults standardUserDefaults] objectForKey:@"MFColoringDirectory"];
    NSString *userPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:coloringFolder]stringByAppendingPathComponent:type];
    NSArray *schemes = [MFColorManager colorSchemesAtPath:userPath];
    [colorSchemes addObjectsFromArray:schemes];
    
    NSError *error = nil;
    NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&error];
    if(!error){
        NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
        NSString *appPath = [[[appSupportDir path] stringByAppendingPathComponent:[executableName stringByAppendingPathComponent:coloringFolder]]stringByAppendingPathComponent:type];
        NSArray *schemes = [MFColorManager colorSchemesAtPath:appPath];
        [colorSchemes addObjectsFromArray:schemes];
    }
    return [colorSchemes autorelease];
}

@end
