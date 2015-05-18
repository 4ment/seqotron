//
//  MFNewickImporter.m
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

#import "MFNewickImporter.h"
#import "MFReaderCluster.h"
#import "MFString.h"
#import "MFTree.h"

@implementation MFNewickImporter

-(NSArray*)readTreesFromFile:(NSString*)path{
    
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithFile:path];
    
    NSArray *trees = [self readTrees:reader];
    
    [reader release];
    
    return trees;
}

-(NSArray*)readTreesFromURL:(NSURL*)url{
    NSString *content = [ NSString stringWithContentsOfURL:url encoding:NSUTF8StringEncoding error:nil];
    NSArray *trees = [self readTreesFromString:content];
    return trees;
}

-(NSArray*)readTreesFromData:(NSData*)data{
    
    NSString *content = [[NSString alloc] initWithData: data encoding: NSASCIIStringEncoding];
    NSArray *trees = [self readTreesFromString:content];
    [content release];
    return trees;
}

-(NSArray*)readTreesFromString:(NSString*)content{
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithString:content];
    
    NSArray *trees = [self readTrees:reader];
    
    [reader release];
    
    return trees;
}

- (NSArray*)readTrees:(MFReaderCluster*)reader{
    NSString *line;
    NSMutableArray *trees = [[NSMutableArray alloc]init];
    NSMutableString *mutString = [[NSMutableString alloc]init];
    while ( (line = [reader readLine]) ) {
        line = [line stringByTrimmingPaddingWhitespace];
        if ( [line length] > 0 ) {
            if( [line hasSuffix:@";"] ){
                [mutString appendString:line];
                MFTree *tree = [[MFTree alloc]initWithNewick:mutString];
                [trees addObject:tree];
                [tree release];
                [mutString setString:@""];
            }
            else {
                [mutString appendString:line];
            }
        }
        
    }
    [mutString release];
    return [trees autorelease];
}

@end
