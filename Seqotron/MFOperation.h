//
//  MFOperation.h
//  Seqotron
//
//  Created by Mathieu Fourment on 10/03/2015.
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

#import <Foundation/Foundation.h>

#import "MFOperationDelegate.h"

extern NSString *MFOperationDescriptionKey;
extern NSString *MFOperationOutputKey;
extern NSString *MFOperationDocumentClassKey;

@interface MFOperation : NSOperation{
    NSString *_classType;
    NSURL *_outputURL;
}

- (id)initWithOptions:(NSDictionary*)options;

- (id)initWithOutputURL:(NSURL*)url classDocument:(NSString*)type;

@property (nonatomic, readwrite, retain)NSURL *outputURL;
@property (retain,readonly)NSString *classType;
@property (copy,readwrite)NSString *description;

@property (retain,readonly)NSDictionary *options;

@property (atomic,assign) id<MFOperationDelegate> delegate;

@end
