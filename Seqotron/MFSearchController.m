//
//  MFSearchController.m
//  Seqotron
//
//  Created by Mathieu on 14/05/2015.
//  Copyright (c) 2015 University of Sydney. All rights reserved.
//

#import "MFSearchController.h"

@interface MFSearchController ()

@end

@implementation MFSearchController

@synthesize regex,wrapAround,caseSensitive,selectionMode;

- (id)init{
    if(self = [super initWithWindowNibName:@"MFSearchController"]){
        self.selectionMode = 0; // Name
        self.regex = NO;
        self.caseSensitive = NO;
        self.wrapAround = NO;
    }
    return self;
}

- (void)dealloc{
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (IBAction)findNext:(id)sender{
    
}

- (IBAction)findPrevious:(id)sender{
    
}

- (IBAction)findAll:(id)sender{
    
}

- (IBAction)replace:(id)sender{
    
}

- (IBAction)replaceAll:(id)sender{
    
}

- (IBAction)findAndReplace:(id)sender{
    
}

@end
