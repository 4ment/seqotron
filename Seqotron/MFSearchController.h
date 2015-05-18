//
//  MFSearchController.h
//  Seqotron
//
//  Created by Mathieu on 14/05/2015.
//  Copyright (c) 2015 University of Sydney. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MFSearchController : NSWindowController{

}


@property (readwrite) NSInteger selectionMode;
@property (readwrite,getter=isCaseSensitive) BOOL caseSensitive;
@property (readwrite) BOOL regex;
@property (readwrite) BOOL wrapAround;

@end
