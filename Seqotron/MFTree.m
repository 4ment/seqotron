//
//  MFTree.m
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

#import "MFTree.h"

@implementation MFTree

-(id)initWithRoot:(MFNode*)root{
    if( self = [super init] ){
        _attributes = nil;
        _root = [root retain];
        [self updateNodeCounts];
    }
    return self;
}

-(id)initWithNewick:(NSString*)newick{
    if( self = [super init] ){
        _attributes = nil;
        [self buildTree:newick];
        [self updateNodeCounts];
    }
    return self;
}

-(void)dealloc{
    NSLog(@"MFTree dealloc");
    [_root release];
    [_attributes release];
    [super dealloc];
}

-(MFNode*)root{
    return _root;
}

- (void)updateNodeCounts{
    _nodeCount = 0;
    _taxonCount = 0;
    [self enumeratePostorderNode:_root usingBlock:^(MFNode* node){
        if( [node isLeaf] ){
            _taxonCount++;
        }
        _nodeCount++;
    }];
}

- (NSUInteger)nodeCount{
    return _nodeCount;
}

- (NSUInteger)taxonCount{
    return _taxonCount;
}

-(NSString*)newick{
    NSMutableString *newick = [[NSMutableString alloc]init];
    [self newickFromNode:_root inString:newick];
    [newick appendString:@";"];
    return [newick autorelease];
}

-(void)newickFromNode:(MFNode*)node inString:(NSMutableString*)newick {
    if( [node childCount] > 0 ){
        [newick appendString:@"("];
        for ( NSUInteger i = 0; i < [node childCount]; i++ ) {
            [self newickFromNode:[node childAtIndex:i] inString:newick];
            if(i < [node childCount]-1) [newick appendString:@","];
        }
        [newick appendString:@")"];
        if( node.parent != nil) [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
    }
    else {
        [newick appendFormat:@"%@:%f", [node name], [node branchLength] ];
    }
}

- (void)enumerateNodesWithAlgorithm:(MFTreeTraverseAlgorithm)algorithm usingBlock:(void (^)(MFNode *node))block{
    switch ( algorithm) {
        case MFTreeTraverseAlgorithmPostorder:
            [self enumeratePostorderNode:_root usingBlock:block];
            break;
        case MFTreeTraverseAlgorithmPreorder:
            [self enumeratePreorderNode:_root usingBlock:block];
            break;
        case MFTreeTraverseAlgorithmInorder:
            [self enumerateInorderNode:_root usingBlock:block];
            break;
        default:
            break;
    }
}

- (void)enumeratePostorderNode:(MFNode*)node usingBlock:(void (^)(MFNode *node))block{
    for (int i = 0; i < [node childCount]; i++) {
        [self enumeratePostorderNode:[node childAtIndex:i] usingBlock:block];
    }
    block(node);
}

- (void)enumeratePreorderNode:(MFNode*)node usingBlock:(void (^)(MFNode *node))block{
    block(node);
    for (int i = 0; i < [node childCount]; i++) {
        [self enumeratePreorderNode:[node childAtIndex:i] usingBlock:block];
    }
}

- (void)enumerateInorderNode:(MFNode*)node usingBlock:(void (^)(MFNode *node))block{
    for (int i = 0; i < [node childCount]; i++) {
        [self enumerateInorderNode:[node childAtIndex:i] usingBlock:block];
        block(node);
    }
}

// return desc without the comment
-(NSString*)extractAttributes:(NSString*)desc node:(MFNode*)node{
    NSMutableString *mutString = [[NSMutableString alloc]init];
    NSUInteger start = [desc rangeOfString:@"["].location;
    if( start != 0 ){
        [mutString appendString:[desc substringToIndex:start]];
    }
    NSUInteger end = [desc rangeOfString:@"]"].location;
    if(end < [desc length]){
        [mutString appendString:[desc substringFromIndex:end+1]];
    }
    
    NSString *comment = [desc substringWithRange:NSMakeRange(start+1, end-start-1)];
    NSMutableString *attr = [[NSMutableString alloc]init];
    
    NSUInteger j = 0;
    while ( j < [comment length]) {
        if( [comment characterAtIndex:j] == ',' || j == [comment length]-1 ){
            if (j == [comment length]-1) {
                [attr appendFormat:@"%c",[comment characterAtIndex:j]];
            }
            
            NSUInteger loc = [attr rangeOfString:@"="].location;
            NSString *key   = [attr substringToIndex:loc];
            if ([key hasPrefix:@"&"]) {
                key = [key substringFromIndex:1];
            }
            NSString *value = [attr substringFromIndex:loc+1];
            
            [node setAttribute:value forKey:key];
            [attr setString:@""];
        }
        else if( [comment characterAtIndex:j] == '{' ){
            while ( [comment characterAtIndex:j] == '}' ) {
                [attr appendFormat:@"%c",[comment characterAtIndex:j]];
                j++;
            }
            [attr appendFormat:@"%c",[comment characterAtIndex:j]];
            
        }
        else {
            [attr appendFormat:@"%c",[comment characterAtIndex:j]];
        }
        j++;
    }
    [attr release];
    return [mutString autorelease];
}

-(void)buildTree:(NSString*)newick{

    MFNode *current = [[MFNode alloc]initWithName:@"node0"]; // the root
    _root = current;
    NSUInteger count = 1;
    
    NSCharacterSet *aSet = [NSCharacterSet characterSetWithCharactersInString:@":,)["];
    
    for ( NSUInteger i = 1; i < [newick length]; i++ ) {
        unichar c = [newick characterAtIndex:i];
        
        if( c == ';' ) break;
        
        if( c == '(' ){
            MFNode *node = [[MFNode alloc]initWithName:[NSString stringWithFormat:@"node%lu",count]];
            [current addChild:node];
            
            current = node;
            [node release];
            
            count++;
            
        }
        else if( c == ')' ){
            
            NSUInteger p = ++i;
            while ( [newick characterAtIndex:p] != ',' && [newick characterAtIndex:p] != ')' && [newick characterAtIndex:p] != ';' ) {
                if( [newick characterAtIndex:p] == '['){
                    while ([newick characterAtIndex:p] != ']') p++;
                }
                p++;
            }
            
            
            if ( p != i ) {
                NSRange range = NSMakeRange(i, p-i);
                NSString *desc = [newick substringWithRange:range];

                // extract comment
                if( [desc rangeOfString:@"["].location != NSNotFound ){
                    desc = [self extractAttributes:desc node:current];
                }
            
                if( [desc rangeOfString:@":"].location != NSNotFound ){
                    NSUInteger idx = [desc rangeOfString:@":"].location;
                    if( idx == 0 ){
                        CGFloat branchLength = [[desc substringFromIndex:1] floatValue];
                        [current setBranchLength:branchLength];
                    }
                    else {
                        // could be a name or a bootstrap
                        NSString *temp = [desc substringToIndex:idx];
                        NSNumberFormatter *numberFormatter = [[NSNumberFormatter alloc]init];
                        if( [numberFormatter numberFromString:temp] ){
                            [current setAttribute:temp forKey:MFNodeDefaultInternalKey];
                        }
                        else {
                            [current setName:temp];
                        }
                        [numberFormatter release];
                        
                        CGFloat branchLength = [[desc substringFromIndex:idx+1] floatValue];
                        [current setBranchLength:branchLength];
                    }
                    
                }
                i = p-1;
            }
            current = current.parent;
            
        }
        // leaf node
        else if( c != ',' ){
            NSUInteger p = [newick rangeOfCharacterFromSet:aSet options:0 range:NSMakeRange(i, [newick length]-i)].location;
            NSRange range = NSMakeRange(i, p-i);
            NSString *taxon = [newick substringWithRange:range];
            taxon = [taxon stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"'\""]];
            
            MFNode *n = [[MFNode alloc]initWithName:taxon];
            [current addChild:n];
            
            i = p;
            
            while ( [newick characterAtIndex:p] != ',' && [newick characterAtIndex:p] != ')' ) {
                if( [newick characterAtIndex:p] == '['){
                    while ([newick characterAtIndex:p] != ']') p++;
                }
                p++;
            }
            
            if( p != i ){
                range = NSMakeRange(i, p-i);
                NSString *desc = [newick substringWithRange:range];
                
                // extract comment
                if( [desc rangeOfString:@"["].location != NSNotFound ){
                    desc = [self extractAttributes:desc node:n];
                }
                
                if( [desc hasPrefix:@":"] ){
                    CGFloat branchLength = [[desc substringFromIndex:1] floatValue];
                    [n setBranchLength:branchLength];
                }
                
                i = p;
            }
            
            [n release];
            i--;
        }
    }
}

- (void)setAttribute:(id)object forKey:(NSString*)key{
    if( _attributes == nil ){
        _attributes = [[NSMutableDictionary alloc]init];
    }
    [_attributes setObject:object forKey:key];
}

- (id)attributeForKey:(NSString*)key{
    if( _attributes == nil ) return nil;
    return [_attributes objectForKey:key];
}

- (void)setRootAtNode:(MFNode*)theNode{
    if( [theNode isRoot] || [[theNode parent]isRoot] ) return;
    
    MFNode *newRoot = [[MFNode alloc]initWithName:@"root"];
    MFNode *node = [theNode parent];
    
    CGFloat branchLength = [node branchLength];
    NSMutableDictionary *attributes = [node attributes];
    CGFloat midPoint = [theNode branchLength]*0.5;
    
    [theNode setBranchLength:midPoint];
    [node setBranchLength:midPoint];
    
    if( ![theNode isLeaf] ){
        node.attributes = theNode.attributes;
    }
    else {
        theNode.attributes = [NSMutableDictionary dictionary];
        node.attributes = [NSMutableDictionary dictionary];
    }
    
    MFNode *parentNode = [node parent];
    [newRoot addChild:node ];
    [newRoot addChild:theNode];
    
    [parentNode removeChild:node];
    [node removeChild:theNode];
    
    while ( ![parentNode isRoot] ) {
        CGFloat tempBranchLength = [parentNode branchLength];
        [parentNode setBranchLength:branchLength];
        branchLength = tempBranchLength;
        
        NSMutableDictionary *tempAttributes = [parentNode attributes];
        parentNode.attributes = attributes;
        attributes = tempAttributes;
        
        MFNode *tempNode = [parentNode parent];
        [node addChild:parentNode];
        
        node = parentNode;
        parentNode = tempNode;
        [parentNode removeChild:node];
    }
    
    
    
    parentNode = [parentNode childAtIndex:0];
    [parentNode setBranchLength:[parentNode branchLength]+branchLength];
    [node addChild:parentNode];
    
    
    MFNode *root = [self root];
    for ( NSUInteger i = 0; i < [root childCount]; i++ ) {
        [root removeChildAtIndex:i];
    }
    [root addChild:[newRoot childAtIndex:0]];
    [root addChild:[newRoot childAtIndex:1]];
    [root setBranchLength:0];
    
    if( [theNode isLeaf] ){
        for ( NSUInteger i = 0; i < [root childCount]; i++) {
            [root childAtIndex:i].attributes = [NSMutableDictionary dictionary];
        }
    }
    
    [newRoot release];
}


NSComparisonResult customCompareFunction(NSArray* first, NSArray* second, void* context)
{
    id firstValue = [first objectAtIndex:0];
    id secondValue = [second objectAtIndex:0];
    return [firstValue compare:secondValue];
}

- (void)ladderize{
    
    [self enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPostorder usingBlock:^(MFNode *node){
        if ( [node isLeaf] ) {
            
            [node setAttribute:[NSNumber numberWithFloat:1] forKey:@"?mlaf.ladderize"];
        }
        else {
            NSUInteger count = 0;
            NSMutableArray *array = [NSMutableArray array];
            for ( NSUInteger i = 0; i < [node childCount]; i++ ) {
                [array addObject:[NSArray arrayWithObjects:[[node childAtIndex:i] attributeForKey:@"?mlaf.ladderize"], [node childAtIndex:i], nil]];
                count += [[[node childAtIndex:i] attributeForKey:@"?mlaf.ladderize"]unsignedIntegerValue];
                [node removeChildAtIndex:i];
            }
            [node setAttribute:[NSNumber numberWithFloat:count] forKey:@"?mlaf.ladderize"];
            
            NSArray* sortedArray = [array sortedArrayUsingFunction:customCompareFunction context:NULL];
            
            for (NSArray *pair in sortedArray) {
                [node addChild:[pair objectAtIndex:1]];
            }
        }
    }];
    
    [self enumerateNodesWithAlgorithm:MFTreeTraverseAlgorithmPostorder usingBlock:^(MFNode *node){
        [node.attributes removeObjectForKey:@"?mlaf.ladderize"];
    }];
}

@end
