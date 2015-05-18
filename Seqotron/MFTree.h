//
//  MFTree.h
//  Seqotron
//
//  Created by Mathieu Fourment on 7/11/2014.
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

#import <Foundation/Foundation.h>

#import "MFNode.h"

typedef enum {
    MFTreeTraverseAlgorithmInorder,
    MFTreeTraverseAlgorithmPreorder,
    MFTreeTraverseAlgorithmPostorder,
    MFTreeTraverseAlgorithmBreadthFirst,
    
} MFTreeTraverseAlgorithm;

//typedef bool (^NSTreeTraverseBlock)(NSTreeNode *node, id data, id extra);

@interface MFTree : NSObject{
    MFNode *_root;
    NSUInteger _nodeCount;
    NSUInteger _taxonCount;
    NSMutableDictionary *_attributes;
}

-(id)initWithRoot:(MFNode*)root;

-(id)initWithNewick:(NSString*)newick;

- (NSUInteger)nodeCount;

- (NSUInteger)taxonCount;

-(MFNode*)root;

- (void)setRootAtNode:(MFNode*)theNode;

- (void)ladderize;

-(NSString*)newick;

- (void)enumerateNodesWithAlgorithm:(MFTreeTraverseAlgorithm)algorithm usingBlock:(void (^)(MFNode *node))block;

- (void)enumeratePostorderNode:(MFNode*)node usingBlock:(void (^)(MFNode *node))block;

- (void)enumeratePreorderNode:(MFNode*)node usingBlock:(void (^)(MFNode *node))block;

- (void)enumerateInorderNode:(MFNode*)node usingBlock:(void (^)(MFNode *node))block;

- (void)setAttribute:(id)object forKey:(NSString*)key;

- (id)attributeForKey:(NSString*)key;

@end
