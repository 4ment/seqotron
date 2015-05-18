//
//  MFTreeExporter.m
//  Seqotron
//
//  Created by Mathieu Fourment on 21/01/2015.
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

#import "MFTreeExporter.h"

#import "MFTree.h"

NSString *MFTreeExporterShowInternalNodeNameKey = @"tk.phylogenetics.seqotron.exporter.tree.show.internal.node";
NSString *MFTreeExporterShowBootstrapNodeNameKey = @"tk.phylogenetics.seqotron.exporter.tree.show.bootstrap";

@implementation MFTreeExporter


-(id)initWithTrees:(NSArray*)trees{
    if( self = [super init]){
        _trees = [trees retain];
        _options = nil;
        _map = nil;
    }
    return self;
}


-(id)initWithTrees:(NSArray*)trees options:(NSDictionary*)options{
    if( self = [super init]){
        _trees = [trees retain];
        _options = [options retain];
        _map = nil;
    }
    return self;
}

-(id)initWithTree:(MFTree*)tree{
    if( self = [super init]){
        _trees = [[NSArray alloc]initWithObjects:tree, nil];
        _options = nil;
        _map = nil;
    }
    return self;
}

-(void)dealloc{
    [_options release];
    [_map release];
    [_trees release];
    [super dealloc];
}

-(void)writeToFile:(NSString*)path error:(NSError**)error{
    if (error) {
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
}

-(void)writeToURL:(NSURL*)url error:(NSError**)error{
    if (error) {
        *error = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:nil];
    }
}

-(NSString*)string{
    NSLog( @"NSOperation is an abstract class, implement -[%@ %@]", [self class], NSStringFromSelector( _cmd ) );
    return nil;
}

-(NSData*)data{
    NSString *string = [self string];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

@end
