//
//  MFNode.m
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

#import "MFNode.h"

NSString *MFNodeDefaultInternalKey = @"tk.phylogenetics.MFNode.default.key";

@implementation MFNode

@synthesize attributes = _attributes;
@synthesize parent = _parent;
@synthesize branchLength = _branchLength;
@synthesize name = _name;

-(id)init{
    if( self = [super init]){
        _child = [[NSMutableArray alloc]init];
        _parent = nil;
        _attributes = [[NSMutableDictionary alloc]init];;
        _branchLength = 0;
        _name = [[NSString alloc]initWithString:@""];
    }
    return self;
}

-(id)initWithName:(NSString*)name{
    if( self = [super init]){
        _child = [[NSMutableArray alloc]init];
        _parent = nil;
        _attributes = [[NSMutableDictionary alloc]init];
        _branchLength = 0;
        _name = [name copy];
    }
    return self;
}

-(void)dealloc{
    [_child release];
    [_attributes release];
    [_name release];
    _parent = nil;
    [super dealloc];
}

-(NSString*)description{
    return [NSString stringWithFormat:@"MFNode %@", _name];
}

- (BOOL)isRoot{
    return  _parent == nil;
}

- (BOOL)isLeaf{
    return [_child count] == 0;
}

-(NSUInteger)childCount{
    return [_child count];
}

-(void)addChild:(MFNode*)child{
    [_child addObject:child];
    child.parent = self;
}

- (void)removeChild:(MFNode*)child{
    [_child removeObject:child];
}

-(void)removeChildAtIndex:(NSUInteger)index{
    [_child removeObjectAtIndex:index];
}

-(MFNode*)childAtIndex:(NSUInteger)index{
    return [_child objectAtIndex:index];
}

- (void)setAttribute:(id)object forKey:(NSString*)key{
    [_attributes setObject:object forKey:key];
}

- (id)attributeForKey:(NSString*)key{
    return [_attributes objectForKey:key];
}

- (void)rotate{
    if( [_child count] > 1 ){
        MFNode *last = [_child lastObject];
        [_child insertObject:last atIndex:0];
        [_child removeObjectAtIndex:[_child count]-1];
    }
}

@end
