//
//  LatexController.h
//  TexTable
//
//  Created by Josh Guffin on 30/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface LatexController : NSObject {
    IBOutlet PDFView     * pdf;
    IBOutlet NSSlider    * zoom;
    IBOutlet NSTextField * zoomSize;
    IBOutlet NSView      * zoomSlideView;
    IBOutlet NSView      * zoomTextView;
    IBOutlet NSView      * zoomAutoView;
    IBOutlet NSWindow    * previewWindow;
    
    id controller;
}
- (void) show;
- (IBAction) zoom:(id)sender;
- (NSString *) runTeX:(id) sender;
- (NSString *) run:(NSString *)pathToCommand withArguments:(NSArray *)arguments atPath:(NSString *)path;
- (NSString *) latexWithPreamble:(NSString *)preamble andTable:(NSString *)table;

@end
