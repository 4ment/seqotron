//
//  MFFileReader.m
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

#import "MFFileReader.h"

@implementation MFFileReader

-(id)initWithFile:(NSString*)path{
    self = [super init];
    if (self) {
        _line = [[NSMutableString alloc]init];
        _file = fopen([path UTF8String], "r");
        if(_file == NULL ){
            NSLog(@"Cannot open file %@",path );
        }
        _buffer[0] = '\0';
    }
    return self;
}

-(void)dealloc{
    fclose(_file);
    [_line release];
    [super dealloc];
}

-(NSString*) readLine2{
    if ( feof(_file) ) {
        return nil;
    }
    
    [_line setString:@""];
    char c;
	while ( !feof(_file) ) {
		c = fgetc(_file);
		
		if ( c == '\n' || c == '\r' ) {
			// check if it is windows
			if ( c == '\r' ) {
				fpos_t pos;
				fgetpos(_file, &pos);
				char cc = fgetc(_file);
				if( cc != '\n' ){
					fsetpos(_file, &pos);
				}
			}
			break;
		}
		else {
			if( c == EOF ){
				break;
			}
			else {
				[_line appendFormat:@"%c", c];
			}
		}
	}
    
//    int charsRead;
//    do {
//        if(fscanf(_file, "%4095[^\n]%n%*c", _buffer, &charsRead) == 1)
//            [_line appendFormat:@"%s", _buffer];
//        else
//            break;
//    } while(charsRead == 4095);

    return _line;
}

-(NSString*) readLine{
    
    size_t ret,i,len;
    char c;
    
    if ( feof(_file) && _buffer[0] == '\e'  ) {
        return nil;
    }
    
    len = strlen(_buffer);
    
    for ( i = 0; i < len; i++ ) {
        c = _buffer[i];
        if( c == '\n' || c == '\r' ){
            _buffer[i] = '\0';
            [_line setString:[NSString stringWithUTF8String:_buffer]];
            
            if( i < len-1){
                if( c == '\r' && _buffer[i+1] == '\n'){
                    i++;
                }
            }
            memmove(&_buffer[0], &_buffer[i+1], (len-i-1)*sizeof(char));
            _buffer[len-i-1] = '\0';
            
            return _line;
        }
    }
    
    [_line setString:[NSString stringWithUTF8String:_buffer]];
    
    // last line of the file without \n and \r at the end
    if( i == strlen(_buffer) && feof(_file) ){
        _buffer[0] = '\e';
        return _line;
    }
    
    _buffer[0] = '\0';
    
    while ( 1 ) {
        ret = fread(_buffer, sizeof(char), 4096, _file);
        if( ret == 0 ){
            _buffer[0] = '\e';
            break;
        }
        
        for ( i = 0; i < ret; i++ ) {
            c = _buffer[i];
            if( c == '\n' || c == '\r' ){
                _buffer[i] = '\0';
                [_line appendFormat:@"%s", _buffer];
                
                if( i < ret-1){
                    if( c == '\r' && _buffer[i+1] == '\n'){
                        i++;
                    }
                }
                memmove(&_buffer[0], &_buffer[i+1], (ret-i-1)*sizeof(char));
                _buffer[ret-i-1] = '\0';
                
                return _line;
            }
        }
        _buffer[i] = '\0';
        [_line appendFormat:@"%s", _buffer];
        
    }
    return _line;
}

- (void)rewind{
    rewind(_file);
    _buffer[0] = '\0';
    [_line setString:@""];
}

@end
