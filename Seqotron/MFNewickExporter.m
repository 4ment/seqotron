//
//  MFNewickExporter.m
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

#import "MFNewickExporter.h"

#import "MFTree.h"

@implementation MFNewickExporter


-(NSString*)string{
    NSMutableString *str = [[NSMutableString alloc]init];
    
    for (MFTree *tree in _trees) {
        [str appendString:[self newick:tree options:_options]];
        [str appendString:@"\r"];
    }
    return [str autorelease];
}


-(NSString*)newick:(MFTree*)tree options:(NSDictionary*)options {
    NSMutableString *newick = [[NSMutableString alloc]init];
    [self newickFromNode:[tree root] inString:newick options:options];
    [newick appendString:@";"];
    return [newick autorelease];
}


-(void)newickFromNode:(MFNode*)node inString:(NSMutableString*)newick options:(NSDictionary*)options{
    if( ![node isLeaf] ){
        [newick appendString:@"("];
        for ( NSUInteger i = 0; i < [node childCount]; i++ ) {
            [self newickFromNode:[node childAtIndex:i] inString:newick options:options];
            if(i < [node childCount]-1) [newick appendString:@","];
        }
        [newick appendString:@")"];
        if( [options objectForKey:MFTreeExporterShowInternalNodeNameKey] && [[options objectForKey:MFTreeExporterShowInternalNodeNameKey]boolValue] ){
            if( node.parent != nil) [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
        }
        else if( [options objectForKey:MFTreeExporterShowBootstrapNodeNameKey] && [[options objectForKey:MFTreeExporterShowBootstrapNodeNameKey]boolValue] ){
            if( node.parent != nil) [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
        }
        else {
            if( node.parent != nil) [newick appendFormat:@":%f", [node branchLength] ];
        }
    }
    else {
        [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
    }
}

#pragma mark -- old --

-(NSString*)string2{
    NSMutableString *str = [[NSMutableString alloc]init];
    
    BOOL showInternal = ( [_options objectForKey:MFTreeExporterShowInternalNodeNameKey] && [[_options objectForKey:MFTreeExporterShowInternalNodeNameKey]boolValue]);
    
    for ( NSUInteger i = 0; i < [_trees count]; i++ ) {
        MFTree *tree = [_trees objectAtIndex:i];
        [str appendString:[self newick:tree internalNodeName:showInternal]];
        [str appendString:@"\r"];
    }
    return [str autorelease];
}


-(NSString*)newick:(MFTree*)tree internalNodeName:(BOOL)internal {
    NSMutableString *newick = [[NSMutableString alloc]init];
    [self newickFromNode:[tree root]internalNodeName:internal inString:newick];
    [newick appendString:@";"];
    return [newick autorelease];
}

-(void)newickFromNode:(MFNode*)node internalNodeName:(BOOL)internal inString:(NSMutableString*)newick {
    if( ![node isLeaf] ){
        [newick appendString:@"("];
        for ( NSUInteger i = 0; i < [node childCount]; i++ ) {
            [self newickFromNode:[node childAtIndex:i] internalNodeName:internal inString:newick];
            if(i < [node childCount]-1) [newick appendString:@","];
        }
        [newick appendString:@")"];
        if( internal){
            if( node.parent != nil) [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
        }
        else {
            if( node.parent != nil) [newick appendFormat:@":%f", [node branchLength] ];
        }
    }
    else {
        [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
    }
}

-(void)newickFromNode2:(MFNode*)node inString:(NSMutableString*)newick options:(NSDictionary*)options{
    if( ![node isLeaf] ){
        [newick appendString:@"("];
        for ( NSUInteger i = 0; i < [node childCount]; i++ ) {
            [self newickFromNode:[node childAtIndex:i] inString:newick options:options];
            if(i < [node childCount]-1) [newick appendString:@","];
        }
        [newick appendString:@")"];
        if( [options objectForKey:MFTreeExporterShowInternalNodeNameKey] && [[options objectForKey:MFTreeExporterShowInternalNodeNameKey]boolValue] ){
            if( node.parent != nil) [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
        }
        else if( [options objectForKey:MFTreeExporterShowBootstrapNodeNameKey] && [[options objectForKey:MFTreeExporterShowBootstrapNodeNameKey]boolValue] ){
            if( node.parent != nil) [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
        }
        else {
            if( node.parent != nil) [newick appendFormat:@":%f", [node branchLength] ];
        }
    }
    else {
        [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
    }
}


@end
