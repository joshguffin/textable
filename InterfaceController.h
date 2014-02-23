//
//  InterfaceController.h
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import <Cocoa/Cocoa.h>
#import "TTSCellSelectionTableView.h"
#import "TexTable.h"
#import "LatexController.h"

@interface InterfaceController : NSObject {
    
    IBOutlet NSTextField  * alignment;
    IBOutlet NSTextField  * width;
    IBOutlet NSTextField  * position;
    IBOutlet NSTextField  * label;
    IBOutlet NSTextField  * rows;
    IBOutlet NSTextField  * columns;
    IBOutlet NSStepper    * rowStepper;
    IBOutlet NSStepper    * colStepper;
    IBOutlet NSTextView   * caption;
    IBOutlet NSButtonCell * landscape;
    IBOutlet NSButton     * align;
    IBOutlet NSButton     * widthCheck;
    IBOutlet NSButton     * positionCheck;
    IBOutlet NSButton     * recognize;
    IBOutlet NSButton     * centering;
    
    IBOutlet NSMatrix     * portLand;
    
    IBOutlet NSTextView  * messages;
    IBOutlet NSTextView  * texText;
    
    IBOutlet NSTextField * verbosityDescription;
    IBOutlet NSSlider    * verbositySlider;
    
    IBOutlet TTSCellSelectionTableView * texTable;
    
    IBOutlet NSPanel        * pdflatexPanel;
    IBOutlet NSTextField    * pdflatexPath;
    IBOutlet NSWindow       * mainWindow;
    
    IBOutlet NSPanel        * bigMessagesPanel;
    IBOutlet NSTextView     * bigMessages;
    
    IBOutlet NSProgressIndicator * indicator;

    TexTable * tex;
    LatexController * preview;
}

- (IBAction) normalizeColumns:(id)sender;
- (IBAction) transpose:(id)sender;
- (IBAction)    update:(id)sender;
- (IBAction)  surround:(id)sender;
- (IBAction) slideVerb:(id)sender;
- (IBAction) go:(id)sender;
- (IBAction) copyTeX:(id)sender;
- (IBAction) clearMessages:(id)sender;
- (IBAction) save:(id)sender;
- (IBAction) saveAs:(id)sender;

- (IBAction) importCSV:(id)sender;
- (IBAction) exportCSV:(id)sender;

- (IBAction) logSelected:(id)sender;

- (NSString *) texString;

- (void) addMessage:(NSString *) newMessage;
- (NSDictionary *) texSettings;
- (void) updateTableSize;
- (void) updateTable;
- (void) texDataChanged;

@end
