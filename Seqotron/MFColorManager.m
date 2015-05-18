//
//  MFColorManager.m
//  Seqotron
//
//  Created by Mathieu Fourment on 4/03/2015.
//  Copyright (c) 2015 Mathieu Fourment. All rights reserved.
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

#import "MFColorManager.h"

@implementation MFColorManager


+ (NSArray*)colorSchemesAtPath:(NSString*)path{
    
    NSError *error = nil;
    NSMutableArray *schemes = [[NSMutableArray alloc]init];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if( !error ){
        for ( NSString *file in dirFiles) {
            if ( [file hasSuffix:@"plist"] ) {
                NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
                [schemes addObject:[dict objectForKey:@"Description"]];
                [dict release];
            }
        }
    }
    return [schemes autorelease];
}

+ (NSArray*)colorUserSchemes:(NSString*)type{
    NSString *userColorDir = [MFColorManager userColorDirectory];
    if( userColorDir ){
        NSString *path = [userColorDir stringByAppendingPathComponent:type];
        
        NSMutableArray *schemes = [[NSMutableArray alloc]init];
        NSError *error = nil;
        NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
        if( !error ){
            for ( NSString *file in dirFiles) {
                if ( [file hasSuffix:@"plist"] ) {
                    NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
                    [schemes addObject:[dict objectForKey:@"Description"]];
                    [dict release];
                }
            }
            return [schemes autorelease];
        }
        [schemes release];
    }
    return nil;
}

+ (NSArray*)colorSchemesWithInfoAtPath:(NSString*)path{
    
    NSError *error = nil;
    NSMutableArray *schemes = [[NSMutableArray alloc]init];
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    if( !error ){
        for ( NSString *file in dirFiles) {
            if ( [file hasSuffix:@"plist"] ) {
                NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
                NSMutableDictionary *scheme = [NSMutableDictionary dictionary];
                [scheme setObject:[dict objectForKey:@"Description"] forKey:@"desc"];
                [scheme setObject:[file stringByDeletingPathExtension] forKey:@"file"];
                [schemes addObject:scheme];
                [dict release];
            }
        }
    }
    return [schemes autorelease];
}

+ (NSString*)userColorDirectory{
    NSString *rootPath = nil;
    NSError *err = nil;
    NSURL *appSupportDir = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:nil create:YES error:&err];

    if( !err ){
        NSString *executableName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleExecutable"];
        rootPath = [[appSupportDir path] stringByAppendingPathComponent:[executableName stringByAppendingPathComponent:[[NSUserDefaults standardUserDefaults] objectForKey:@"MFColoringDirectory"]]];
    }
    return rootPath;
}

+ (NSString*)applicationColorDirectory{
    NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[[NSUserDefaults standardUserDefaults] objectForKey:@"MFColoringDirectory"]];
    return path;
}

+ (NSDictionary*)coloring:(NSString*)desc fromPath:(NSString*)path{
    NSMutableDictionary *colors = [[NSMutableDictionary alloc]init];
    NSError *error = nil;
    NSArray *dirFiles = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:&error];
    
    if(!error){
        for ( NSString *file in dirFiles) {
            if ( [file hasSuffix:@"plist"] ) {
                NSDictionary *dict = [[NSDictionary alloc] initWithContentsOfFile:[path stringByAppendingPathComponent:file]];
                if ( [[dict objectForKey:@"Description"] isEqualToString:desc] ) {
                    
                    NSDictionary *temp = [dict objectForKey:@"Foreground"];
                    if ( temp != nil ) {
                        NSMutableDictionary *foreground = [[NSMutableDictionary alloc]init];
                        for (NSString *key in [temp keyEnumerator]) {
                            NSArray *colors = [temp valueForKey:key];
                            CGFloat red   = [[colors objectAtIndex:0] floatValue];
                            CGFloat green = [[colors objectAtIndex:1] floatValue];
                            CGFloat blue  = [[colors objectAtIndex:2] floatValue];
                            CGFloat alpha = 1;
                            if( [colors count] == 4 ) [[colors objectAtIndex:3] floatValue];
                            
                            NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
                            [foreground setValue: color forKey:key];
                        }
                        [colors setObject:foreground forKey:NSForegroundColorAttributeName];
                        [foreground release];
                    }
                    
                    temp = [dict objectForKey:@"Background"];
                    if ( temp != nil ) {
                        NSMutableDictionary *background = [[NSMutableDictionary alloc]init];
                        for (NSString *key in [temp keyEnumerator]) {
                            NSArray *colors = [temp valueForKey:key];
                            CGFloat red   = [[colors objectAtIndex:0] floatValue];
                            CGFloat green = [[colors objectAtIndex:1] floatValue];
                            CGFloat blue  = [[colors objectAtIndex:2] floatValue];
                            CGFloat alpha = 1;
                            if( [colors count] == 4 ) [[colors objectAtIndex:3] floatValue];
                            
                            NSColor *color = [NSColor colorWithDeviceRed:red green:green blue:blue alpha:alpha];
                            [background setValue: color forKey:key];
                        }
                        [colors setObject:background forKey:NSBackgroundColorAttributeName];
                        [background release];
                    }
                    [dict release];
                    break;
                }
                [dict release];
            }
        }
    }
    return [colors autorelease];
}

@end
