//
//  MFTreeReader.m
//  Seqotron
//
//  Created by Mathieu Fourment on 15/12/2014.
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

#import "MFTreeReader.h"

#import "MFReaderCluster.h"
#import "MFString.h"
#import "MFNexusImporter.h"
#import "MFNewickImporter.h"
#import "MFTree.h"
#import "MFDefines.h"

NSString * const MFTreeFileFormat = @"tk.phylogenetics.tree.file.format";

@implementation MFTreeReader

+ (NSArray *)readTreesFromData:(NSData *)data{
    
    NSString *content = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    NSArray *trees = [MFTreeReader readTreesFromString:content];
    [content release];
    return trees;
}

+ (NSArray *)readTreesFromFile:(NSString *)filePath{
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithFile:filePath];
    NSString *line = nil;
    NSArray *trees = nil;
    id<MFTreeImporter> importer = nil;
    NSArray *formats = [[NSArray alloc] initWithObjects:MFTreeFormatArray];
    
    while ( (line = [reader readLine]) ) {
        if( [line isEmpty] ) continue;
        if( [[line uppercaseString] hasPrefix:@"#NEXUS"] ){
            importer = [[MFNexusImporter alloc]init];
            
            trees = [importer readTreesFromFile:filePath];
            for (MFTree *tree in trees) {
                [tree setAttribute:[formats objectAtIndex:MFTreeFormatNEXUS] forKey:MFTreeFileFormat];
            }
            
        }
        else if( [line hasPrefix:@"("] ){
            importer = [[MFNewickImporter alloc]init];
            
            trees = [importer readTreesFromFile:filePath];
            for (MFTree *tree in trees) {
                [tree setAttribute:[formats objectAtIndex:MFTreeFormatNEWICK] forKey:MFTreeFileFormat];
            }
        }
        break;
    }
    [importer release];
    [reader release];
    [formats release];
    return  trees;
}

+ (NSArray *)readTreesFromURL:(NSURL*)url{
    NSString *content = [ NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSArray *trees = [MFTreeReader readTreesFromString:content];
    return trees;
}

+ (NSArray *)readTreesFromString:(NSString *)content{
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithString:content];
    NSString *line = nil;
    NSArray *trees = nil;
    id<MFTreeImporter> importer = nil;
    NSArray *formats = [[NSArray alloc] initWithObjects:MFTreeFormatArray];
    
    while ( (line = [reader readLine]) ) {
        if( [line isEmpty] ) continue;
        if( [[line uppercaseString] hasPrefix:@"#NEXUS"] ){
            importer = [[MFNexusImporter alloc]init];
            
            trees = [importer readTreesFromString:content];
            for (MFTree *tree in trees) {
                [tree setAttribute:[formats objectAtIndex:MFTreeFormatNEXUS] forKey:MFTreeFileFormat];
            }
            
        }
        else if( [line hasPrefix:@"("] ){
            importer = [[MFNewickImporter alloc]init];
            
            trees = [importer readTreesFromString:content];
            for (MFTree *tree in trees) {
                [tree setAttribute:[formats objectAtIndex:MFTreeFormatNEWICK] forKey:MFTreeFileFormat];
            }
        }
        break;
    }
    [importer release];
    [reader release];
    [formats release];
    return  trees;
}

@end
