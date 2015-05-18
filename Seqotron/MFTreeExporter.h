//
//  MFTreeExporter.h
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

#import <Foundation/Foundation.h>

#import "MFTree.h"

extern NSString *MFTreeExporterShowInternalNodeNameKey; // default: NO
extern NSString *MFTreeExporterShowBootstrapNodeNameKey; // default: NO

@interface MFTreeExporter : NSObject{
    NSArray *_trees;
    NSDictionary *_options;
    NSMutableDictionary *_map;
}


-(id)initWithTrees:(NSArray*)trees options:(NSDictionary*)options;

-(id)initWithTrees:(NSArray*)trees;

-(id)initWithTree:(MFTree*)tree;

-(void)writeToFile:(NSString*)path error:(NSError**)error;

-(void)writeToURL:(NSURL*)url error:(NSError**)error;

-(NSString*)string;

-(NSData*)data;

@end


//@protocol MFTreeExporter <NSObject>
//
//-(void)writeToFile:(NSString*)path error:(NSError**)error;
//
//-(void)writeToURL:(NSURL*)url error:(NSError**)error;
//
//-(NSData*)data;
//
//-(NSString*)string;
//
//@end