//
//  MFNode.h
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


extern NSString *MFNodeDefaultInternalKey;

@interface MFNode : NSObject{
    NSString *_name;
    CGFloat _branchLength;
    MFNode *_parent;
    NSMutableArray *_child;
    NSMutableDictionary *_attributes;
}

@property (readwrite, copy) NSString *name;
@property (readwrite, retain) NSMutableDictionary *attributes;
@property (readwrite, assign) MFNode *parent; // assign to avoid circular references
@property CGFloat branchLength;

-(id)initWithName:(NSString*)name;

- (BOOL)isLeaf;

- (BOOL)isRoot;

-(NSUInteger)childCount;

-(void)addChild:(MFNode*)child;

- (void)removeChild:(MFNode*)child;

-(void)removeChildAtIndex:(NSUInteger)index;

-(MFNode*)childAtIndex:(NSUInteger)index;

- (void)setAttribute:(id)object forKey:(NSString*)key;

- (id)attributeForKey:(NSString*)key;

- (void)rotate;

@end
