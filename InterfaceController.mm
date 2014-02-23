//
//  InterfaceController.mm
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import "InterfaceController.h"

static NSString * TableAlignmentString    = @"Table Alignment String";
static NSString * LabelString             = @"Table Label String";
static NSString * RowsString              = @"Table Rows String";
static NSString * ColumnsString           = @"Table Columns String";
static NSString * CaptionString           = @"Table Caption String";
static NSString * TextAlignmentBoolean    = @"Text Alignment Boolean";
static NSString * TableOrientationBoolean = @"Table Orientation Boolean";

/* silly example table
 \begin{table}
 \begin{tabular}[htp]{|l|rrrr|}
 & apple        & pear         & zucchini    & banana        \\ 
 colour        & red,green    & yellow green & green       & yellow        \\ 
 shape         & spherical    & like a pear  & banana-like & zucchini-like \\ 
 taste         & I'm allergic & I'm allergic & great       & monkey-tastic \\ 
 seeded        & yes          & yes          & yes         & no            \\ 
 can be fried? & not likely   & no way       & yep         & oh yeah!
 \end{tabular}
 \caption{Some fruits and vegetables, and my unbiased opinion on their properties.}
 \label{table:foodProperties}
 \end{table}
 
 \begin{table}
 \begin{tabular}{ccc}
 & & \\ 
 & & \\ 
 & & 
 \end{tabular}
 \caption{}
 \label{}
 \end{table}
 
*/ 


@implementation InterfaceController

- (IBAction) logSelected:(id)sender
{
    NSLog([[texTable selectedCells] description]);
}

- (void) awakeFromNib
{
    // Instantiate and initialize the model
    NSDictionary * settings = [self texSettings];
    
    tex = [[TexTable alloc] initWithRows:[[settings objectForKey:RowsString]      intValue]
                                 columns:[[settings objectForKey:ColumnsString]   intValue]];
    
    [tex               setLabel:[settings objectForKey:LabelString]];
    [tex             setCaption:[settings objectForKey:CaptionString]];
    [tex setAlignmentFormatting:[settings objectForKey:TableAlignmentString]];
    
    
    [self updateTable];
    
    // set up the text views
    
    NSDictionary * attributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:11.0f],NSFontAttributeName,nil];
    [texText  setTypingAttributes:attributes];
    [caption  setTypingAttributes:attributes];
    
    NSDictionary * smaller = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont fontWithName:@"Monaco" size:10.0f],NSFontAttributeName,nil];
    [messages setTypingAttributes:smaller];
    
    // so we know when the text changes
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textChanged:) name:NSTextDidChangeNotification object:nil];
    
    [self slideVerb:self];
    
    [mainWindow makeKeyAndOrderFront:self];

    preview = [[LatexController alloc] init];
    [preview setController:self];
    [NSBundle loadNibNamed:@"Preview" owner:preview];
    
    NSUserDefaults * ud = [NSUserDefaults standardUserDefaults];
    
    if (![ud valueForKey:@"Latex Preamble"])
        [ud setValue:@"\\documentclass{article}\n\\usepackage{lscape}" forKey:@"Latex Preamble"];
    
    if (![ud valueForKey:@"pdflatex Path"]) {
        [ud setValue:@"/usr/texbin/pdflatex" forKey:@"pdflatex Path"];
        [pdflatexPanel makeKeyAndOrderFront:self];
    }
    
    NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self selector:@selector(didUndo) name:NSUndoManagerDidUndoChangeNotification object:nil];
    [nc addObserver:self selector:@selector(didUndo) name:NSUndoManagerDidRedoChangeNotification object:nil];
    
    NSDateComponents * cp = [[NSDateComponents alloc] init];
    [cp setWeekday:1];
}

- (void) didUndo
{
    [self update:nil];
    [self updateTable];
}

- (id)tableView:(NSTableView *)tv objectValueForTableColumn:(NSTableColumn *)tc row:(int)row
{
    return [tex objectAtColumn:[[tv tableColumns] indexOfObject:tc] andRow:row];
}

- (void)tableView:(NSTableView *)tv setObjectValue:anObject forTableColumn:(NSTableColumn *)tc row:(int)row
{
    if ([tex setObjectAtColumn:[[tv tableColumns] indexOfObject:tc] andRow:row toObject:anObject])
        [texText setString:[tex texify]];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [tex numberOfRows];
}

- (void) tableView:(NSTableView *)tv didMoveColumn:(int)column toColumn:(int)newColumn
{
    [texTable clear:self];
    [tex exchangeColumn:column andColumn:newColumn];
    [self update:self];
}

- (void)tableView:(NSTableView *)tv willDisplayCell:(id)cell forTableColumn:(NSTableColumn *)tc row:(int)row
{
    NSArray * selectedCells = [(TTSCellSelectionTableView *) tv selectedCells];
    int col = [[tv tableColumns] indexOfObject:tc];
    
    BOOL selected = NO;
    
    for (int i = 0; i < [selectedCells count]; i++) {
        NSPoint colRow = NSPointFromString([selectedCells objectAtIndex:i]);
        if (col == colRow.x && row == colRow.y) {
            selected = YES;
            break;
        }
    }
    
    [cell setSelected:selected];
}

- (IBAction) copyTeX:(id)sender
{
    NSPasteboard* cb = [NSPasteboard generalPasteboard];
    
    [cb declareTypes:[NSArray arrayWithObjects:NSStringPboardType,nil] owner:self];
    [cb    setString:[tex texify] forType:NSStringPboardType];
}

- (IBAction) normalizeColumns:(id)sender
{
    [texTable distributeColumns];
}

- (IBAction) transpose:(id)sender
{
    if ([tex transpose:[texTable selectedCells]]) {
        [self updateTable];
        [texText setString:[tex texify]];
    }
    else
        [self addMessage:@"Cannot transpose: selection not square"];
}

- (IBAction) surround:(id)sender
{
    [tex surround:[texTable selectedCells]];
    [self updateTable];
    [texText setString:[tex texify]];
}

- (void) addMessage:(NSString *) newMessage
{
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"Clear Messages"] boolValue]) {
        [messages setString:newMessage]; 
        [bigMessages setString:newMessage];
    } else {
        
        NSString * oldMess = [messages string];
        
        if ([oldMess length] > 0) {
            [messages setString:[NSString stringWithFormat:@"%@\n%@",oldMess,newMessage]];
            [bigMessages setString:[NSString stringWithFormat:@"%@\n%@",oldMess,newMessage]];
        } else {
            [messages setString:newMessage];
            [bigMessages setString:newMessage];
        }
    }
}

- (NSDictionary *) texSettings
{
    return [NSDictionary dictionaryWithObjectsAndKeys:
        [alignment  stringValue],                        TableAlignmentString,
        [label      stringValue],                        LabelString,
        [rows       stringValue],                        RowsString,
        [columns    stringValue],                        ColumnsString,
        [caption    string],                             CaptionString,
        [NSNumber numberWithInt:[align state]],          TextAlignmentBoolean,
        [NSNumber numberWithInt:[portLand selectedRow]], TableOrientationBoolean,
        nil];
}

- (void) updateTable
{
    [texTable reloadData];
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:@"Keep Normalized"] boolValue])
        [self normalizeColumns:texTable];
}

- (IBAction) update:(id)sender
{   
    [tex setAlignmentFormatting:[alignment stringValue]];
    [tex       setLabel:[label stringValue]];
    [tex     setCaption:[caption string]];
    [tex     setAligned:[align state]];
    [tex   setLandscape:[portLand selectedRow]];
    [tex       setWidth:[width stringValue]];
    [tex    setPosition:[position stringValue]];
    [tex    setUseWidth:[widthCheck state]];
    [tex setUsePosition:[positionCheck state]];
    [tex    setCentered:[centering state]];
    
    if (sender == rowStepper || sender == rows) {
        int newRows = [sender intValue];
        
        while (newRows < [tex numberOfRows])
            [tex deleteRowAtIndex:[tex numberOfRows] - 1];
        while (newRows > [tex numberOfRows])
            [tex addRow];
        [rowStepper setIntValue:newRows];
        [rows       setIntValue:newRows];
        
        [self updateTable];
    }
    
    if (sender == colStepper || sender == columns) {
        int newCols = [sender intValue];
        
        while (newCols < [tex numberOfColumns])
            [tex deleteColumnAtIndex:[tex numberOfColumns] - 1];
        while (newCols > [tex numberOfColumns])
            [tex addColumn];
        
        [colStepper setIntValue:newCols];
        [columns    setIntValue:newCols];
        
        [self updateTableSize];
    }
    
    [texText setString:[tex texify]];
}

- (void) textChanged:(NSNotification *) notification
{
    if ([notification object] == caption) {
        
        [tex setCaption:[caption string]];
        [texText setString:[tex texify]];
    } else if ([notification object] == texText) {
        
        if ([recognize state] == NSOffState) return;
        
        NSRange charPosition = [texText selectedRange];
        
        NSString * results = [tex importTeX:[texText string]];
        
        if (results) 
            [self addMessage:results];
        
        [self texDataChanged];
        
        [texText setSelectedRange:charPosition];
    }
}

- (void) texDataChanged
{
    [caption        setString:[tex caption]];
    [alignment setStringValue:[tex alignmentFormatting]];
    [label     setStringValue:[tex label]];
    [width     setStringValue:[tex width]];
    [position  setStringValue:[tex position]];
    [widthCheck      setState:[tex useWidth]];
    [positionCheck   setState:[tex usePosition]];
    [centering       setState:[tex centered]];
    
    [rows       setIntValue:[tex numberOfRows]];
    [columns    setIntValue:[tex numberOfColumns]];
    [rowStepper setIntValue:[tex numberOfRows]];
    [colStepper setIntValue:[tex numberOfColumns]];
    
    [self updateTableSize];
    
}

- (void) updateTableSize
{
    while ([texTable numberOfColumns] < [tex numberOfColumns])
        [texTable addTableColumn:[[[NSTableColumn alloc] init] autorelease]];
    
    while ([texTable numberOfColumns] > [tex numberOfColumns])
        [texTable removeTableColumn:[[texTable tableColumns] lastObject]];
    
    [self updateTable];
}

- (BOOL)windowShouldClose:(id)sender
{
    return NO;
}


#pragma mark Menu actions for the table
//================================================================================================================================================
- (void) copy:(id)sender
{
    NSArray * selected = [texTable selectedCells];
    if (selected && [selected count] > 0)
        [tex copyCells:selected];
}

- (BOOL) canPaste
{
    NSPasteboard* cb = [NSPasteboard generalPasteboard];
    NSString* type = [cb availableTypeFromArray:[NSArray arrayWithObjects:@"TeX Table Pasteboard Data Type", nil]];
    return (type != nil);
}

- (void) delete
{
    NSArray * selected = [texTable selectedCells];
    if (selected && [selected count] > 0)
        [tex deleteCells:selected];
}

- (void) paste:(id)sender
{
    NSString * point = [[[texTable selectedCells] sortedArrayUsingSelector:@selector(compare:)] objectAtIndex:0];
    if (!point) return;
    
    [tex pasteCellsAt:NSPointFromString(point)];
    [self updateTable];
    [texText setString:[tex texify]];
}

- (BOOL) canUndo
{
    return [tex canUndo];
}

- (BOOL) canRedo
{
    return [tex canRedo];
}

- (NSString *) undoActionName
{
    return [tex undoActionName];
}

- (void) undo
{
    [tex undo];
    [self updateTable];
    [texText setString:[tex texify]];
}

- (void) redo
{
    [tex redo];
    [self updateTable];
    [texText setString:[tex texify]];
}

- (void) tableView:(TTSCellSelectionTableView *) tv changedSelectionFrom:(NSArray *)selection withLastSelection:(NSArray *) lastSelection
{
    [[[tex undoManager] prepareWithInvocationTarget:tv] setSelectionTo:selection withLastSelection:lastSelection];
}

- (IBAction) importCSV:(id)sender
{
    NSOpenPanel * op = [NSOpenPanel openPanel];
    
    [op setAllowsMultipleSelection:NO];
    
    if (NSCancelButton == [op runModal])
        return;
    
    NSString * path = [op filename];
    
    [tex importFromCSVfile:path];
    //[tex importCSV:[NSString stringWithContentsOfFile:path]];
    [self texDataChanged];
    [texTable reloadData];
}

- (IBAction) exportCSV:(id)sender
{
    NSSavePanel * sp = [NSSavePanel savePanel];
    
    [sp setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
    [sp setAllowsOtherFileTypes:YES];
    [sp runModal];
    
    [[tex exportWithSeperator:@","] writeToFile:[sp filename] atomically:YES];
}

- (IBAction) slideVerb:(id)sender
{
    int verbosity = [verbositySlider intValue];
    
    switch (verbosity) {
        case 1:
            [verbosityDescription setStringValue:@"Lowest verbosity, only errors are shown"];
            break;
        case 2:
            [verbosityDescription setStringValue:@"Medium verbosity, errors and warnings are shown"];
            break;
        case 3:
            [verbosityDescription setStringValue:@"High verbosity, every possible message is shown"];
    }
}

- (void) startAnimation:(NSTimer *) timer
{
    //[[timer userInfo] setHidden:YES];
    [indicator startAnimation:self];
    [timer release];
}

- (void) runTeX:(NSTimer *) timer
{
    NSString * results = [preview runTeX:self];
    
    [preview show];
    [self addMessage:results];
    //[[timer userInfo] setHidden:NO];
    [indicator stopAnimation:self];
    [timer release];
}

- (IBAction) go:(id)sender
{
    id send = nil;
    if ([sender isKindOfClass:[NSButton class]])
        send = sender;
    
    [[NSTimer scheduledTimerWithTimeInterval:0.05
                                                        target:self
                                                      selector:@selector(startAnimation:)
                                                      userInfo:send
                                                       repeats:NO] retain];
    
    [[NSTimer scheduledTimerWithTimeInterval:0.1
                                                        target:self
                                                      selector:@selector(runTeX:)
                                                      userInfo:send
                                                       repeats:NO] retain];
    
}

- (void) insert:(id)sender
{
    NSIndexSet * selRows = [texTable selectedRows];
    NSIndexSet * selCols = [texTable selectedColumns];
    
    switch ([sender tag]) {
        case 1: //row before
            [tex addRowAtIndex:[selRows firstIndex]];
            break;
        case 2: // row after
            [tex addRowAtIndex:[selRows lastIndex]+1];
            break;
        case 3: //column before
            [tex addColumnAtIndex:[selCols firstIndex]];
            break;
        case 4: //column after
            [tex addColumnAtIndex:[selCols lastIndex]+1];
            break;
    }
    [self updateTable];
    [texText setString:[tex texify]];
}

- (void)controlTextDidChange:(NSNotification *)notification {
    //NSLog(@"textDidChange notification received %@",notification);
    //[self go:[notification object]];
}

- (IBAction) save:(id)sender
{
    
}


- (IBAction) saveAs:(id)sender
{
    
}


- (IBAction) clearMessages:(id)sender
{
    [bigMessages setString:@""];
    [messages    setString:@""];
}

- (NSString *) texString
{
    return [texText string];
}

- (void) dealloc
{
    [tex release];
    [preview release];
    
    [super dealloc];
}

@end
