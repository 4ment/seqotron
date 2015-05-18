//
//  MFNexusExporter.m
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

#import "MFNexusExporter.h"

NSString *MFNexusExporterTranslateTaxaKey = @"tk.phylogenetics.seqotron.exporter.tree.nexus.translate";

@implementation MFNexusExporter

-(NSString*)string{
    NSMutableString *str = [[NSMutableString alloc]init];
    
    [str appendString:@"#NEXUS\r"];
    
    [str appendString:@"BEGIN TREES;\r"];
    
    if( ![_options objectForKey:MFNexusExporterTranslateTaxaKey] || [[_options objectForKey:MFNexusExporterTranslateTaxaKey]boolValue]){
        NSString *translate = [self setUpMap];
        [str appendString:translate];
    }
    
    for ( NSUInteger i = 0; i < [_trees count]; i++ ) {
        MFTree *tree = [_trees objectAtIndex:i];
        [str appendFormat:@"tree TREE%lu = ",i];
        [str appendString:[self newick:tree]];
        [str appendString:@"\r"];
    }
    
    [str appendString:@"END;\r"];
    return [str autorelease];
}

-(NSString*)newick:(MFTree*)tree {
    NSMutableString *newick = [[NSMutableString alloc]init];
    [self newickFromNode:[tree root] inString:newick];
    [newick appendString:@";"];
    return [newick autorelease];
}

-(void)newickFromNode:(MFNode*)node inString:(NSMutableString*)newick {
    if( ![node isLeaf] ){
        [newick appendString:@"("];
        for ( NSUInteger i = 0; i < [node childCount]; i++ ) {
            [self newickFromNode:[node childAtIndex:i] inString:newick];
            if(i < [node childCount]-1) [newick appendString:@","];
        }
        [newick appendString:@")"];
        if( node.parent != nil){
            [newick appendFormat:@":%f", [node branchLength] ];
        }
    }
    else {
        NSString *desc = [node name];
        if( _map ){
            desc = [_map objectForKey:desc];
        }
        [newick appendFormat:@"%@:%f", desc, [node branchLength] ];
    }
    
    if( [[node attributes]count] > 0 ){
        NSMutableString *comment = [[NSMutableString alloc]init];
        for (NSString *key in [[node attributes]allKeys]) {
            //if( [_options objectForKey:key] && [[_options objectForKey:key]boolValue] ){
            // do not print Seqotron private tags
            if( ![key hasPrefix:@"?"] ){
                [comment appendFormat:@"%@=%@,",key, [node.attributes objectForKey:key] ];
            }
        }
        if( [comment length] > 0 ){
            [comment deleteCharactersInRange:NSMakeRange([comment length]-1, 1)];
            [newick appendFormat:@"[&%@]", comment];
        }
        [comment release];
    }
}


-(NSString*) setUpMap{
    if( !_map )_map = [[NSMutableDictionary alloc]init];
    NSMutableString *translate = [[NSMutableString alloc]init];
    [translate appendString:@"\tTranslate\r"];
    MFTree *tree = [_trees objectAtIndex:0];
    __block NSUInteger i = 1;
    [tree enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPostorder usingBlock:^(MFNode *node){
        if( [node isLeaf]){
            NSString *alias = [NSString stringWithFormat:@"%lu",i];
            [_map setObject: alias forKey:[node name]];
            [translate appendFormat:@"\t\t%@ %@,\r", alias, [node name]];
            i++;
        }
    }];
    [translate deleteCharactersInRange:NSMakeRange([translate length]-2, 1)]; // remove the last comma
    [translate appendString:@";\r"];
    return [translate autorelease];
}

@end
