//
//  MFProgressController.m
//  Seqotron
//
//  Created by Mathieu Fourment on 17/01/2015.
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

#import "MFProgressController.h"


@implementation MFProgressController

@synthesize progressIndicator ,primaryDescription, secondaryDescription;

-(id)initWithOperation:(NSOperation*)op{
    if(self = [super initWithWindowNibName:@"MFProgressWindow"]){
        _operations = [[NSArray alloc]initWithObjects:op, nil];
        primaryDescription = [[NSString alloc]init];
        secondaryDescription = [[NSString alloc]init];
    }
    return self;
}

-(id)initWithOperations:(NSArray*)operations{
    if(self = [super initWithWindowNibName:@"MFProgressWindow"]){
        _operations = [operations retain];
        primaryDescription = [[NSString alloc]init];
        secondaryDescription = [[NSString alloc]init];
    }
    return self;
}

-(void)dealloc{
    [_operations release];
    [progressIndicator release];
    [primaryDescription release];
    [secondaryDescription release];
    [super dealloc];
}

- (void)windowDidLoad {
    [super windowDidLoad];
    MFOperation *op = [_operations objectAtIndex:0];
    if( op.description ){
        self.window.title = op.description;
    }
}

- (IBAction)cancel:(id)sender{
    NSLog(@"Cancel operation");
    for ( NSOperation *op in _operations) {
        [op cancel];
    }
    [self close];
}

-(void)operation:(MFOperation*)operation setDescription:(NSString*)desc{
    self.primaryDescription = desc;
}

-(void)operation:(MFOperation*)operation setDescription2:(NSString*)desc{
    self.secondaryDescription = desc;
}

@end
