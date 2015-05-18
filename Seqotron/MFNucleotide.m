//
//  MFNucleotide.m
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

#import "MFNucleotide.h"

static bool const NUCLEOTIDE_STATES[128] = {
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,	// 15
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,	// 31
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,	// 47
    false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,false,	// 63
    //	   A          C                      G
    false, true,false,true,false,false,false,true,false,false,false,false,false, false,false,false,	    // 79
    //                      T    U
    false,false,false,false,true,true,false,false,false,false,false,false,false,false,false,false,	    // 95
    //	   a          c                      g
    false, true,false,true,false,false,false,true,false,false,false,false,false, false,false,false,	    // 111
    //                      t    u
    false,false,false,false,true,true,false,false,false,false,false,false,false,false,false,false,		// 1127
};

@implementation MFNucleotide

- (NSUInteger)stateCount{
    return 4;
}

-(NSString*)description{
    return @"Nucleotide";
}

-(BOOL)isAmbiguous:(NSString *)character{
    return [character rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"KMRSWYBDHVN"]].location != NSNotFound;
}

-(BOOL)isKnown:(NSString *)character{
    return [character rangeOfCharacterFromSet: [NSCharacterSet characterSetWithCharactersInString: @"ACTGU"]].location != NSNotFound;
}

- (BOOL)isKnownChar:(char)character{
    return NUCLEOTIDE_STATES[character];
}

-(BOOL)isValid:(NSString *)character{
    return [self isKnown:character] || [self isAmbiguous:character] || [self isGap:character] || [self isUnknown:character];
}

+ (id)sharedInstance{
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init]; // or some other init method
    });
    return _sharedObject;
}

+ (void) logCharacterSet:(NSCharacterSet*)characterSet {
    unichar unicharBuffer[20];
    int index = 0;
    
    for (unichar uc = 0; uc < (0xFFFF); uc ++)
    {
        if ([characterSet characterIsMember:uc])
        {
            unicharBuffer[index] = uc;
            
            index ++;
            
            if (index == 20)
            {
                NSString * characters = [NSString stringWithCharacters:unicharBuffer length:index];
                NSLog(@"%@", characters);
                
                index = 0;
            }
        }
    }
    
    if (index != 0)
    {
        NSString * characters = [NSString stringWithCharacters:unicharBuffer length:index];
        NSLog(@"%@", characters);
    }
}
@end
