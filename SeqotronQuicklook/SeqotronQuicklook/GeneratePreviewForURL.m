#import <CoreFoundation/CoreFoundation.h>
#import <CoreServices/CoreServices.h>
#import <QuickLook/QuickLook.h>
#import <Cocoa/Cocoa.h>

#import "MFReaderCluster.h"
#import "MFString.h"
#import "MFSequenceReader.h"
#import "MFSequenceSet.h"


OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

// By default a file is an alignment what ever the extension is.
NSString * typeForContentsOfURL(NSURL *url) {
    if ( ![url isFileURL] ) {
        return nil;
    }
    MFReaderCluster *reader = [[MFReaderCluster alloc]initWithFile:url.path];
    NSString *line = nil;
    
    BOOL isTree = NO;
    BOOL isSequence = NO;
    BOOL isNexus = NO;
    
    while ( (line = [reader readLine]) ) {
        // Allow the first line to be empty
        if( [[line stringByTrimmingPaddingWhitespace] length] == 0 ){
            continue;
        }
        if ( [[line uppercaseString] hasPrefix:@"#NEXUS"]) {
            isNexus = YES;
        }
        else if( [line hasPrefix:@"("]){
            isTree = YES;
        }
        break;
    }
    
    if ( isNexus ) {
        while ( (line = [reader readLine]) ) {
            if( [[line stringByTrimmingPaddingWhitespace] length] == 0 ){
                continue;
            }
            if( [[line uppercaseString] hasPrefix:@"BEGIN TREES"] ){
                NSLog(@"nexus tree");
                isTree = YES;
            }
            else if( [[line uppercaseString] hasPrefix:@"BEGIN DATA"] || [[line uppercaseString] hasPrefix:@"BEGIN CHARACTERS"] ){
                isSequence = YES;
                NSLog(@"nexus sequence");
            }
            if( isTree && isSequence)break;
        }
    }
    [reader release];
    
    if(isTree) return @"Tree";
    
    return @"Alignment";
}

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
//    if (false == QLPreviewRequestIsCancelled(preview)) {
    NSURL *myURL = (__bridge NSURL*)url;
    
    MFSequenceSet *sequenceSet = [MFSequenceReader readSequencesFromFile:myURL.path];
    
    if( sequenceSet && [[sequenceSet sequences]count] > 0 ){
        if (false == QLPreviewRequestIsCancelled(preview)) {
            
            NSArray *sequenceArray = [sequenceSet sequences];
            
            NSUInteger numberOfSequences = [sequenceArray count];
            BOOL aligned = YES;
            NSUInteger alignmentLength = [[sequenceArray objectAtIndex:0]length];
            for ( NSUInteger i = 1; i < numberOfSequences; i++ ) {
                if( alignmentLength != [[sequenceArray objectAtIndex:i]length] ){
                    aligned = NO;
                    break;
                }
            }
            
            
            
            // compose the html
            NSMutableString *html = [[NSMutableString alloc] initWithString:@"<!DOCTYPE html>\n"];
            [html appendString:@"<html xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"en\"><head>\n"];
            [html appendFormat:@"<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n"];
            [html appendString:@"<style>\n"];
            // css here
            
            // info
            [html appendFormat:@"</style></head><body><div class=\"file_info\">Number of sequences: <b>%lu</b> Aligned: <b>%@</b>",numberOfSequences, (aligned ? @"yes":@"no")];

            if( aligned ){
                [html appendFormat:@" Alignment length: <b>%lu</b>", alignmentLength];
            }
            [html appendString:@"</div><table>"];
            
            // add the table rows
            BOOL altRow = NO;
            for (MFSequence *seq in sequenceArray) {
                if( [[seq name]length] > 20 ){
                    [html appendFormat:@"<tr><td>%@...</td>", [[seq name]substringToIndex:20]];
                }
                else {
                    [html appendFormat:@"<tr><td>%@</td>", [seq name]];
                }
                if( [[seq sequence]length] > 100 ){
                    [html appendFormat:@"<td>%@...</td>", [[seq sequence]substringToIndex:100]];
                }
                else {
                    [html appendFormat:@"<td>%@</td>", [seq sequence]];
                }
                [html appendString:@"</tr>\n"];
                
                altRow = !altRow;
            }
            
            [html appendString:@"</table>\n"];

            [html appendString:@"</html>"];
            
            // feed the HTML
            CFDictionaryRef properties = (__bridge CFDictionaryRef)@{};
            QLPreviewRequestSetDataRepresentation(preview,
                                                  (__bridge CFDataRef)[html dataUsingEncoding:NSUTF8StringEncoding],
                                                  kUTTypeHTML,
                                                  properties
                                                  );
        }
    }
    // To complete your generator please implement the function GeneratePreviewForURL in GeneratePreviewForURL.c
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}



