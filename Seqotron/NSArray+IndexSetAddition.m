//
//  NSArray+IndexSetAddition.m
//  Seqotron
//
//  Created by Mathieu on 24/11/2014.
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

#import "NSArray+IndexSetAddition.h"


@implementation NSArray (IndexSetAddition)

- (NSArray *) subarrayWithIndexes: (NSIndexSet *)indexes{
    NSMutableArray *targetArray  = [NSMutableArray array];
    NSUInteger count = [self count];
    
    NSUInteger index = [indexes firstIndex];
    while ( index != NSNotFound ) {
        if ( index < count )
            [targetArray addObject: [self objectAtIndex: index]];
        
        index = [indexes indexGreaterThanIndex: index];
    }
    
    return targetArray;
}

@end