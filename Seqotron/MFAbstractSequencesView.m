//
//  MFAbstractSequencesView.m
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

#import "MFAbstractSequencesView.h"

// The names of the bindings supported by this class, in addition to the ones whose support is inherited from NSView.
NSString *MFSequenceViewSequencesBindingName = @"sequences";
NSString *MFSequenceViewSelectionIndexesBindingName = @"selectionIndexes";
NSString *MFSequenceViewFontNameBindingName = @"fontName";
NSString *MFSequenceViewFontSizeBindingName = @"fontSize";

NSString *MFSequenceViewSequencesObservationContext = @"tk.phylogenetics.MFSequenceView.sequences";
NSString *MFSequenceViewSelectionIndexesObservationContext = @"tk.phylogenetics.MFSequenceView.selectionIndexes";

@implementation MFAbstractSequencesView


@synthesize rowHeight = _rowHeight;
@synthesize residueWidth = _residueWidth;
@synthesize residueHeight = _residueHeight;

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        NSLog(@"MFAbstractSequencesView initWithFrame");
        _fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontSize"]floatValue];
        _fontName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontName"]copy];
        _rowSpacing = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceRowSpacing"]floatValue];
        _colSpacing = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceColumnSpacing"]floatValue];
        [self initSize];
    }
    return self;
}

-(void)awakeFromNib {
    NSLog(@"MFAbstractSequencesView awakeFromNib");
    _fontSize = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontSize"]floatValue];
    _fontName = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceFontName"]copy];
    _rowSpacing = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceRowSpacing"]floatValue];
    _colSpacing = [[[NSUserDefaults standardUserDefaults] objectForKey:@"MFDefaultSequenceColumnSpacing"]floatValue];
    [self initSize];
}

-(void)dealloc{
    // Stop observing objects for the bindings whose support isn't implemented using NSObject's default implementations.
    [self unbind:MFSequenceViewSequencesBindingName];
    [self unbind:MFSequenceViewSelectionIndexesBindingName];
    [_fontName release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

-(void)setFontSize:(NSNumber*)fontSize{
    if( _fontSize!= [fontSize floatValue] ){
        _fontSize = [fontSize floatValue];
        [self initSize];
        [self setNeedsDisplay:YES];
    }
}

-(NSNumber*)fontSize{
    return [NSNumber numberWithFloat:_fontSize];
}

-(void)setFontName:(NSString *)fontName{
    if( ![fontName isEqualToString:_fontName] ){
        [_fontName release];
        _fontName = [fontName copy];
        [self initSize];
        [self setNeedsDisplay:YES];
    }
}

-(void)initSize{
    NSMutableDictionary *attsDict = [[NSMutableDictionary alloc] init];
    NSFont *font = [NSFont fontWithName:_fontName size:_fontSize];
    [attsDict setObject:font forKey:NSFontAttributeName];
    
    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithString:@"A" attributes:attsDict];
    //_rowHeight     = [font capHeight]+_rowSpacing;//[string size].height - 4;
    
    _lineGap = [string size].height+[font descender] - [font capHeight];
    _rowHeight     = [string size].height - _lineGap;
    _residueHeight = [font capHeight];
    _residueWidth  = [string size].width;
    [string release];
    [attsDict release];
    
}

- (NSArray *)sequences {
    
    // A graphic view doesn't hold onto an array of the graphics it's presenting. That would be a cache that hasn't been justified by performance measurement (not yet anyway). Get the array of graphics from the bound-to object (an array controller, in Sketch's case). It's poor practice for a method that returns a collection to return nil, so never return nil.
    NSArray *sequences = [_sequencesContainer valueForKeyPath:_sequencesKeyPath];
    if (!sequences) {
        sequences = [NSArray array];
    }
    return sequences;
    
}

- (NSMutableArray *)mutableSequences {
    
    // Get a mutable array of graphics from the bound-to object (an array controller, in Sketch's case). The bound-to object is responsible for being KVO-compliant enough that all observers of the bound-to property get notified of whatever mutation we perform on the returned array. Trying to mutate the graphics of a graphic view whose graphics aren't bound to anything is a programming error.
    NSAssert((_sequencesContainer && _sequencesKeyPath), @"An MFAbstractSequencesView's 'sequence' property is not bound to anything.");
    NSMutableArray *mutableSequences = [_sequencesContainer mutableArrayValueForKeyPath:_sequencesKeyPath];
    return mutableSequences;
    
}

- (NSIndexSet *)selectionIndexes {
    
    // A graphic view doesn't hold onto the selection indexes. That would be a cache that hasn't been justified by performance measurement (not yet anyway).
    // Get the selection indexes from the bound-to object (an array controller, in Sketch's case). It's poor practice for a method that returns a collection
    // (and an index set is a collection) to return nil, so never return nil.
    NSIndexSet *selectionIndexes = [_selectionIndexesContainer valueForKeyPath:_selectionIndexesKeyPath];
    if (!selectionIndexes) {
        selectionIndexes = [NSIndexSet indexSet];
    }
    return selectionIndexes;
    
}

/* Why isn't this method called -setSelectionIndexes:? Mostly to encourage a naming convention that's useful for a few reasons:
 
 NSObject's default implementation of key-value binding (KVB) uses key-value coding (KVC) to invoke methods like -set<BindingName>: on the bound object when the bound-to property changes, to make it simple to support binding in the simple case of a view property that affects the way a view is drawn but whose value isn't directly manipulated by the user. If NSObject's default implementation of KVB were good enough to use for this "selectionIndexes" property maybe we _would_ implement a -setSelectionIndexes: method instead of stuffing so much code in -observeValueForKeyPath:ofObject:change:context: down below (but it's not, because it doesn't provide a way to get at the old and new selection indexes when they change). So, this method isn't here to take advantage of NSObject's default implementation of KVB. It's here to centralize the bindings work that must be done when the user changes the selection (check out all of the places it's invoked down below). Hopefully the different verb in this method name is a good reminder of the distinction.
 
 A person who assumes that a -set... method always succeeds, and always sets the exact value that was passed in (or throws an exception for invalid values to signal the need for some debugging), isn't assuming anything unreasonable. Setters that invalidate that assumption make a class' interface unnecessarily unpredictable and hard to program against. Sometimes they require people to write code that sets a value and then gets it right back again to keep multiple copies of the value synchronized, in case the setting didn't "take." So, avoid that. When validation is appropriate don't put it in your setter. Instead, implement a separate validation method. Follow the naming pattern established by KVC's -validateValue:forKey:error: when applicable. Now, _this_ method can't guarantee that, when it's invoked, an immediately subsequent invocation of -selectionIndexes will return the passed-in value. It's supposed to set the value of a property in the bound-to object using KVC, but only after asking the bound-to object to validate the value. So, again, -setSelectionIndexes: wouldn't be a very good name for it.
 
 */
- (void)changeSelectionIndexes:(NSIndexSet *)indexes {
    
    // After all of that talk, this method isn't invoking -validateValue:forKeyPath:error:. It will, once we come up with an example of invalid selection indexes for this case.
    
    // It will also someday take any value transformer specified as a binding option into account, so you have an example of how to do that.
    
    // Set the selection index set in the bound-to object (an array controller, in Sketch's case). The bound-to object is responsible for being KVO-compliant enough that all observers of the bound-to property get notified of the setting. Trying to set the selection indexes of a graphic view whose selection indexes aren't bound to anything is a programming error.
    NSAssert((_selectionIndexesContainer && _selectionIndexesKeyPath), @"An MFNamesView's 'selectionIndexes' property is not bound to anything.");
    [_selectionIndexesContainer setValue:indexes forKeyPath:_selectionIndexesKeyPath];
    
}


// An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)bind:(NSString *)bindingName toObject:(id)observableObject withKeyPath:(NSString *)observableKeyPath options:(NSDictionary *)options {
    
    // SKTGraphicView supports several different bindings.
    if ([bindingName isEqualToString:MFSequenceViewSequencesBindingName]) {
        
        // We don't have any options to support for our custom "graphics" binding.
        NSAssert(([options count]==0), @"MFSequenceView doesn't support any options for the 'sequences' binding.");
        
        // Rebinding is just as valid as resetting.
        if (_sequencesContainer || _sequencesKeyPath) {
            [self unbind:MFSequenceViewSequencesBindingName];
        }
        
        // Record the information about the binding.
        _sequencesContainer = [observableObject retain];
        _sequencesKeyPath = [observableKeyPath copy];
        
        // Start observing changes to the array of graphics to which we're bound, and also start observing properties of the graphics themselves that might require redrawing.
        [_sequencesContainer addObserver:self forKeyPath:_sequencesKeyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:MFSequenceViewSequencesObservationContext];
        //[self startObservingSequences:[_sequencesContainer valueForKeyPath:_sequencesKeyPath]];
        
        // Redraw the whole view to make the binding take immediate visual effect. We could be much cleverer about this and just redraw the part of the view that needs it, but in typical usage the view isn't even visible yet, so that would probably be a waste of time (the programmer's and the computer's). If this view ever gets reused in some wildly dynamic situation where the bindings come and go we can reconsider optimization decisions like this then.
        [self setNeedsDisplay:YES];
        //NSLog(@"ABstrctView binding %@ keypath %@",bindingName, _sequencesKeyPath);
        
    } else if ([bindingName isEqualToString:MFSequenceViewSelectionIndexesBindingName]) {
        
        // We don't have any options to support for our custom "selectionIndexes" binding either. Maybe in the future someone will imagine a use for a value transformer on this, and we'll add support for it then.
        NSAssert(([options count]==0), @"MFSequenceView doesn't support any options for the 'selectionIndexes' binding.");
        
        // Rebinding is just as valid as resetting.
        if (_selectionIndexesContainer || _selectionIndexesKeyPath) {
            [self unbind:MFSequenceViewSelectionIndexesBindingName];
        }
        
        // Record the information about the binding.
        _selectionIndexesContainer = [observableObject retain];
        _selectionIndexesKeyPath = [observableKeyPath copy];
        
        // Start observing changes to the selection indexes to which we're bound.
        [_selectionIndexesContainer addObserver:self forKeyPath:_selectionIndexesKeyPath options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:MFSequenceViewSelectionIndexesObservationContext];
        
        // Same comment as above.
        [self setNeedsDisplay:YES];
        //NSLog(@"ABstrctView binding %@",bindingName);
        
    } else {
        
        // For every binding except "graphics" and "selectionIndexes" just use NSObject's default implementation. It will start observing the bound-to property. When a KVO notification is sent for the bound-to property, this object will be sent a [self setValue:theNewValue forKey:theBindingName] message, so this class just has to be KVC-compliant for a key that is the same as the binding name, like "grid." That's why this class has a -setGrid: method. Also, NSView supports a few simple bindings of its own, and there's no reason to get in the way of those.
        [super bind:bindingName toObject:observableObject withKeyPath:observableKeyPath options:options];
        
    }
    
}

// An override of the NSObject(NSKeyValueBindingCreation) method.
- (void)unbind:(NSString *)bindingName {

    // SKTGraphicView supports several different bindings. For the ones that don't use NSObject's default implementation of key-value binding, undo what we do in -bind:toObject:withKeyPath:options:, and then redraw the whole view to make the unbinding take immediate visual effect.
    if ([bindingName isEqualToString:MFSequenceViewSequencesBindingName]) {
        //[self stopObservingSequences:[self sequences]];
        [_sequencesContainer removeObserver:self forKeyPath:_sequencesKeyPath];
        [_sequencesContainer release];
        _sequencesContainer = nil;
        [_sequencesKeyPath release];
        _sequencesKeyPath = nil;
        [self setNeedsDisplay:YES];
    } else if ([bindingName isEqualToString:MFSequenceViewSelectionIndexesBindingName]) {
        [_selectionIndexesContainer removeObserver:self forKeyPath:_selectionIndexesKeyPath];
        [_selectionIndexesContainer release];
        _selectionIndexesContainer = nil;
        [_selectionIndexesKeyPath release];
        _selectionIndexesKeyPath = nil;
        [self setNeedsDisplay:YES];
    } else {
        
        // // For every binding except "graphics" and "selectionIndexes" just use NSObject's default implementation. Also, NSView supports a few simple bindings of its own, and there's no reason to get in the way of those.
        [super unbind:bindingName];
        
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(NSObject *)observedObject change:(NSDictionary *)change context:(void *)context {
    
    //NSLog(@"AbstactSequencesView observeValueForKeyPath %@",context);
    [super observeValueForKeyPath:keyPath ofObject:observedObject change:change context:context];
    
}
// This doesn't contribute to any KVC or KVO compliance. It's just a convenience method that's invoked down below.
- (NSArray *)selectedSequences {
    
    // Simple, because we made sure -graphics and -selectionIndexes never return nil.
    return [[self sequences] objectsAtIndexes:[self selectionIndexes]];
    
}

@end
