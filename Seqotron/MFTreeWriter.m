//
//  MFTreeWriter.m
//  Seqotron
//
//  Created by Mathieu Fourment on 10/03/2015.
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

#import "MFTreeWriter.h"

#import "MFNewickExporter.h"
#import "MFNexusExporter.h"

@implementation MFTreeWriter

+ (NSData *) data:(NSArray *) inTrees withFormat:(MFTreeFormat)format attributes:(NSDictionary*)attrs{
    NSData *data = nil;
    
    NSArray *formats = [[NSArray alloc] initWithObjects:MFTreeFormatArray];
    switch (format) {
        case MFTreeFormatNEWICK:
            data = [MFTreeWriter dataNewick:inTrees attributes:attrs];
            break;
        case MFTreeFormatNEXUS:
            data = [MFTreeWriter dataNexus:inTrees attributes:attrs];
            break;
        default:
            NSLog(@"Format not recognized");
            break;
    }
    
    [formats release];
    return data;
}

+ (NSString *) string:(NSArray *) inTrees withFormat:(MFTreeFormat)format attributes:(NSDictionary*)attrs{
    NSString *data = nil;
    
    NSArray *formats = [[NSArray alloc] initWithObjects:MFTreeFormatArray];
    switch (format) {
        case MFTreeFormatNEWICK:
            data = [MFTreeWriter stringNewick:inTrees attributes:attrs];
            break;
        case MFTreeFormatNEXUS:
            data = [MFTreeWriter stringNexus:inTrees attributes:attrs];
            break;
        default:
            NSLog(@"Format not recognized");
            break;
    }
    
    [formats release];
    return data;
}


#pragma mark Newick

+ (void)writeNewick:(NSArray *) inTrees toFile:(NSString *)file attributes:(NSDictionary*)attrs{
//    for (MFTree *tree in inTrees) {
//        NSString * t = [tree newick];
//    }
}

+ (NSString*) stringNewick:(NSArray *) inTrees attributes:(NSDictionary*)attrs{
    MFNewickExporter *exporter = [[MFNewickExporter alloc]initWithTrees:inTrees options:attrs];
    NSString *string = [exporter string];
    [exporter release];
    return string;
}

+ (NSData*) dataNewick:(NSArray *) inTrees attributes:(NSDictionary*)attrs{
    NSString *string = [MFTreeWriter stringNewick:inTrees attributes:attrs];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}


#pragma mark Nexus

+ (void)writeNexus:(NSArray *) inTrees toFile:(NSString *)file attributes:(NSDictionary*)attrs{
    
}

+ (NSString*) stringNexus:(NSArray *) inTrees attributes:(NSDictionary*)attrs{
    MFNexusExporter *exporter = [[MFNexusExporter alloc]initWithTrees:inTrees options:attrs];
    NSString *string = [exporter string];
    [exporter release];
    return string;
}

+ (NSData*) dataNexus:(NSArray *) inTrees attributes:(NSDictionary*)attrs{
    NSString *string = [MFTreeWriter stringNexus:inTrees attributes:attrs];
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return data;
}

@end
