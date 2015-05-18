//
//  MFDefines.h
//  Seqotron
//
//  Created by Mathieu Fourment on 29/01/14.
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

typedef struct MF2DRange {
    NSRange x;
    NSRange y;
} MF2DRange;

NS_INLINE MF2DRange MFMake2DRange(NSUInteger xo, NSUInteger xl, NSUInteger yo, NSUInteger yl) {
    MF2DRange r;
    r.x = NSMakeRange(xo, xl);
    r.y = NSMakeRange(yo, yl);
    return r;
}

NS_INLINE BOOL MFLocationsin2DRange(NSUInteger x, NSUInteger y, MF2DRange range) {
    return NSLocationInRange(x, range.x) && NSLocationInRange(y, range.y);
}

NS_INLINE MF2DRange MFMakeEmpty2DRange() {
    return MFMake2DRange(0, 0, 0, 0);
}

NS_INLINE BOOL MFIsEmpty2DRange(MF2DRange range){
    if( range.x.length == 0 && range.y.length == 0 ){
        return YES;
    }
    return NO;
}

typedef enum MFSequenceFormat: NSUInteger {
    MFSequenceFormatFASTA     = 0,
    MFSequenceFormatNEXUS     = 1,
    MFSequenceFormatPHYLIP    = 2,
    MFSequenceFormatCLUSTAL   = 3,
    MFSequenceFormatMEGA      = 4,
    MFSequenceFormatGDE       = 5,
    MFSequenceFormatNBRF      = 6,
    MFSequenceFormatSTOCKHOLM = 7
    
} MFSequenceFormat;

#define MFSequenceFormatArray @"FASTA", @"Nexus", @"Phylip", @"Clustal", @"MEGA", @"GDE", @"NBRF", @"Stockholm", nil


typedef enum MFTreeFormat: NSUInteger {
    MFTreeFormatNEWICK  = 0,
    MFTreeFormatNEXUS   = 1
    
} MFTreeFormat;

#define MFTreeFormatArray @"Newick", @"Nexus", nil


extern NSString * const MFSequenceFileFormat;

extern NSString * const MFTreeFileFormat;
