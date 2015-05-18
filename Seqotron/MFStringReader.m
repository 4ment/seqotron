//
//  MFStringReader.m
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

#import "MFStringReader.h"

@implementation MFStringReader


-(id)initWithString:(NSString *)content{
    self = [super init];
    if (self) {
        _content = [content retain];
        _contentsEnd = 0;
        _range = NSMakeRange(0, 0);
    }
    return self;
}

-(void)dealloc{
    [_content release];
    [super dealloc];
}

-(NSString*)readLine{
    NSString *line = nil;
    if ( _contentsEnd < [_content length] ){
        [_content getLineStart:&_start end:&_end contentsEnd:&_contentsEnd forRange:_range];
        line = [_content substringWithRange:NSMakeRange(_start,_contentsEnd-_start)];
        _range = NSMakeRange(_end,0);
    }
    return line;
}

-(void)rewind{
    _contentsEnd = 0;
    _range = NSMakeRange(0, 0);
}
@end
