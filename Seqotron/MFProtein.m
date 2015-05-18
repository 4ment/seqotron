//
//  MFProtein.m
//  Seqotron
//
//  Created by Mathieu Fourment on 8/02/14.
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

#import "MFProtein.h"

bool const AMINOACID_STATES[128] = {
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,	// 0-15
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,	// 16-31
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,	// 32-47
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,	// 48-63
    //	  A    B     C    D    E    F    G    H    I          K    L    M    N
    false,true,false,true,true,true,true,true,true,true,false,true,true,true,true,false,	            // 64-79
    // P Q    R    S    T          V    W    X     Y
    true,true,true,true,true,false,true,true,false,true,false,false,false,false,false,false,	        // 80-95
    //	  a          c    d    e    f    g    h    i          k    l    m    n
    false,true,false,true,true,true,true,true,true,true,false,true,true,true,true,false,	            // 96-111
    // p q    r    s    t          v    w          y
    true,true,true,true,true,false,true,true,false,true,false,false,false,false,false,false		        // 112-127
};

@implementation MFProtein

- (NSUInteger)stateCount{
    return 20;
}

-(NSString*)description{
    return @"Protein";
}

-(BOOL)isAmbiguous:(NSString *)character{
    return NO;
}

-(BOOL)isKnown:(NSString *)character{
    return [character rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"ACDEFGHIKLMNPQRSTVWY"]].location != NSNotFound;
}

- (BOOL)isKnownChar:(char)character{
    return AMINOACID_STATES[character];
}

-(BOOL)isValid:(NSString *)character{
    return [self isKnown:character] || [self isGap:character] || [self isUnknown:character];
}

+ (id)sharedInstance{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

@end
