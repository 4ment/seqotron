//
//  MFAbstractSequencesView.h
//  Seqotron
//
//  Created by Mathieu Fourment on 10/09/2014.
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

#import <Cocoa/Cocoa.h>

extern NSString *MFSequenceViewSequencesBindingName;
extern NSString *MFSequenceViewSelectionIndexesBindingName;
extern NSString *MFSequenceViewFontSizeBindingName;

extern NSString *MFSequenceViewSequencesObservationContext;
extern NSString *MFSequenceViewSelectionIndexesObservationContext;

@interface MFAbstractSequencesView : NSView{
    // Information that is recorded when the "graphics" and "selectionIndexes" bindings are established. Notice that we don't keep around copies of the actual graphics array and selection indexes. Those would just be unnecessary (as far as we know, so far, without having ever done any relevant performance measurement) caches of values that really live in the bound-to objects.
    NSObject *_sequencesContainer;
    NSString *_sequencesKeyPath;
    NSObject *_selectionIndexesContainer;
    NSString *_selectionIndexesKeyPath;

    
    CGFloat _fontSize;
    NSString *_fontName;
    CGFloat _rowSpacing;
    CGFloat _rowHeight;
    CGFloat _residueHeight;
    CGFloat _residueWidth;
    CGFloat _lineGap;
    CGFloat _colSpacing;
}


@property (readwrite) CGFloat rowHeight;
@property (readwrite) CGFloat residueWidth;
@property (readwrite) CGFloat residueHeight;

-(void)setFontSize:(NSNumber*)fontSize;

-(void)setFontName:(NSString *)fontName;

- (NSArray *)sequences;

- (NSMutableArray *)mutableSequences;

- (NSIndexSet *)selectionIndexes;

- (void)changeSelectionIndexes:(NSIndexSet *)indexes;


// An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)bind:(NSString *)bindingName toObject:(id)observableObject withKeyPath:(NSString *)observableKeyPath options:(NSDictionary *)options;

// An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)unbind:(NSString *)bindingName;


- (NSArray *)selectedSequences;

@end
