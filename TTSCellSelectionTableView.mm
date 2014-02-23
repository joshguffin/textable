//
//  TTSCellSelectionTableView.mm
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import "TTSCellSelectionTableView.h"

@implementation TTSCellSelectionTableView

- (id) initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    NSArray *cols = [self tableColumns];
    for (int i = 0; i < [cols count]; i++) {
        TTSTextFieldSelectableCell * cell = [[[TTSTextFieldSelectableCell alloc] init] autorelease];
        [cell setEditable:YES];
        [cell setSelectable:YES];
        
        [[cols objectAtIndex:i] setDataCell:cell];
        [[cols objectAtIndex:i] setEditable:YES];
    }
    SelectNoneRect = NSMakeRect(0,0,0,0);
    [self setDrawsGrid:YES];
    
    return self;
}

- (void) addTableColumn:(NSTableColumn *) column
{
    [super addTableColumn:column];
    NSTableColumn * tc = [[self tableColumns] lastObject];
    
    TTSTextFieldSelectableCell * cell = [[[TTSTextFieldSelectableCell alloc] init] autorelease];
    [cell setEditable:YES];
    [cell setSelectable:YES];
    
    [tc setDataCell:cell];
    [tc setEditable:YES];
    [[tc headerCell] setTitle:@""];
    
    
    NSMenu * hc = [[[NSMenu alloc] init] autorelease];
    
    NSMenuItem * before = [[[NSMenuItem alloc] initWithTitle:@"Insert Column Before" action:@selector(insert:) keyEquivalent:@""] autorelease];
    NSMenuItem * after  = [[[NSMenuItem alloc] initWithTitle:@"Insert Column After"  action:@selector(insert:) keyEquivalent:@""] autorelease];
    [before setTag:3];
    [after  setTag:4];
    [hc addItem:before];
    [hc addItem:after];
    [[tc headerCell] setMenu:hc];
}

- (void) distributeColumns
{
    float width = [self visibleRect].size.width;
    float numCols = (float) [self numberOfColumns];
    
    float newWidth = width/numCols;
    
    for (int i = 0; i < numCols; i++)
        [[[self tableColumns] objectAtIndex:i] setWidth:newWidth];
}

- (id) init
{
    self = [super init];
    
    SelectNoneRect = NSMakeRect(0,0,0,0);
    
    return self;
}

- (BOOL) acceptsFirstResponder
{
    return YES;
} 

- (id)_highlightColorForCell:(NSCell *)cell {
    return [NSColor whiteColor];
}


#pragma mark Cell Selection
//============================================================================================================================== Cell Selection  =======

- (NSIndexSet *) selectedRows
{
    if ([selectedCells count] == 0) return nil;
    
    int max = -1, min = [self numberOfRows];
    
    for (int i = 0; i < [selectedCells count]; i++) {
        int row = (int) NSPointFromString([selectedCells objectAtIndex:i]).y;
        
        if (row > max) max = row;
        if (row < min) min = row;
    }
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(min, max-min)];
}

- (NSIndexSet *) selectedColumns
{
    if ([selectedCells count] == 0) return nil;
    
    int max = -1, min = [self numberOfRows];
    
    for (int i = 0; i < [selectedCells count]; i++) {
        int row = (int) NSPointFromString([selectedCells objectAtIndex:i]).x;
        
        if (row > max) max = row;
        if (row < min) min = row;
    }
    return [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(min, max-min)];
}

- (void) selectAll:(id)sender
{
    [self selectCellsInRect:[self frame]];
}

- (void) clear:(id)sender
{
    [self selectCellsInRect:SelectNoneRect];
}

- (NSArray *) selectedCells
{
    return selectedCells;
}

#pragma mark Menu methods
//============================================================================================================================== Cell Selection  =======

- (BOOL) validateMenuItem:(NSMenuItem *)anItem
{
    switch ([anItem tag]) {
        case -5: //selection related items
            return ([self validSelection]);
        case -4:
            return [[self delegate] canPaste];
        case -3:
            return [[self delegate] canRedo];
        case -2:
            return [[self delegate] canUndo];
        case -1: // any other items that need validation
            return YES;
        case 1:
            return [self validSelection];
        case 2:
            return [self validSelection];
        case 3:
            return [self validSelection];
        case 4:
            return [self validSelection];
        default:
            return NO;
    }
}

- (void) insert:(id)sender
{
    [[self delegate] insert:sender];
}

- (BOOL) validSelection
{
    if ([selectedCells count] == 0) return NO;
    
    for (int i= 0; i < [selectedCells count]; i++) {
        NSPoint p = NSPointFromString([selectedCells objectAtIndex:i]);
        if (p.x < 0 || p.y < 0) return NO;
    }
    return YES;
}

- (void) transpose:(id) sender
{
    [[self delegate] transpose:sender];
}

- (void) surround:(id) sender
{
    [[self delegate] surround:sender];
}

- (void) copy:(id) sender
{
    [[self delegate] copy:self];
}

- (void) paste:(id) sender
{
    [[self delegate] paste:self];
}

- (void) undo:(id)sender
{
    [[self delegate] undo];
}

- (void) delete:(id)sender
{
    [[self delegate] delete];
    [self reloadData];
}

- (void) cut:(id)sender
{
    [[self delegate] copy:sender];
    [[self delegate] delete];
    [self clear:sender];
}

- (void) redo:(id)sender
{
    [[self delegate] redo];
}

//this guy only used by undo/redo.  do not call otherwise.
- (void) setSelectionTo:(NSArray *) selection withLastSelection:(NSArray *) lastSelection
{
    [lastSelectedCells release];
    [selectedCells     release];
    lastSelectedCells = [[lastSelection copy] retain];
    selectedCells     = [[selection copy]     retain];
}

#pragma mark Keyboard methods
//=========================================================================================================================== Keyboard Methods =======

- (void)textDidEndEditing:(NSNotification *)aNotification
{
    /*
    // /------------------------------------------------------------------------------------------------------------\
    // |  the default selection behaviour of the table changed between tiger and leopard
    // \------------------------------------------------------------------------------------------------------------/
    if (![self isAtLeastLeopard]) {
        
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"Do Not Select New Cell"] boolValue]) {
            
            NSDictionary *userInfo = [aNotification userInfo];
            int textMovement = [[userInfo valueForKey:@"NSTextMovement"] intValue];
            if (textMovement == NSReturnTextMovement || textMovement == NSTabTextMovement 
                || textMovement == NSBacktabTextMovement) {
                NSMutableDictionary *newInfo;
                newInfo = [NSMutableDictionary dictionaryWithDictionary: userInfo];
                [newInfo setObject:[NSNumber numberWithInt: NSIllegalTextMovement] forKey: @"NSTextMovement"];
                aNotification = [NSNotification notificationWithName:[aNotification name] 
                                                              object:[aNotification object] userInfo:newInfo];
            }
        }
        [super textDidEndEditing:aNotification];
        [[self window] makeFirstResponder:self];
        return;
    }
    // \------------------------------------------------------------------------------------------------------------/
    
    */
    
    if ([[[NSUserDefaults standardUserDefaults] objectForKey:@"Do Not Select New Cell"] boolValue])
        return;
    
    [super textDidEndEditing:aNotification];
    
    // /------------------------------------------------------------------------------------------------------------\
    // |  Enter => next row, with next column if at the last row
    // |  Tab   => next column, with next row if at the last column
    // \------------------------------------------------------------------------------------------------------------/    
    NSPoint op = NSMakePoint([self columnAtPoint:beginningPoint],[self rowAtPoint:beginningPoint]);
    NSPoint pt = NSMakePoint([self columnAtPoint:beginningPoint],[self rowAtPoint:beginningPoint]);
    int rows = [self numberOfRows];
    int cols = [self numberOfColumns];
    
    switch ([[[aNotification userInfo] valueForKey:@"NSTextMovement"] intValue]) {
        case NSReturnTextMovement:
            pt.y++;
            if (pt.y >= rows)
                pt.x++;
            break;
        case NSTabTextMovement:
            pt.x++;
            if (pt.x >= cols)
                pt.y++;
            break;
        case NSBacktabTextMovement:
            pt.x--;
            if (pt.x < 0)
                pt.y--;
    }
    
    if (pt.x < 0)
        pt.x += cols;
    else if (pt.x >= cols)
        pt.x -= cols;
    if (pt.y < 0)
        pt.y += rows;
    else if (pt.y >= rows)
        pt.y -= rows;
    
    [self selectRow:pt.y byExtendingSelection:NO];
    [self selectCellAtColumn:pt.x andRow:pt.y];
    // if the point has changed, it the new one
    if (pt.x != op.x || pt.y != op.y)
        [self editColumn:pt.x row:pt.y withEvent:nil select:YES];
    // \------------------------------------------------------------------------------------------------------------/
    
}

- (void) selectCellAtColumn:(int) col andRow:(int) row
{
    NSRect frame = [self frameOfCellAtColumn:col row:row];
    
    float x = frame.origin.x + frame.size.width/2;
    float y = frame.origin.y + frame.size.height/2;
    
    beginningPoint = NSMakePoint(x,y);
    
    [self selectCellsInRect:frame];
}

- (void)keyDown:(NSEvent *)theEvent
{
    NSPoint oldPt = NSPointFromString([selectedCells objectAtIndex:0]);
    NSPoint pt    = NSPointFromString([selectedCells objectAtIndex:0]);
    
    int x = 0, y = 0;
    
    switch ([[theEvent characters] characterAtIndex:0]) {
        case NSEnterCharacter:
            [self editColumn:pt.x row:pt.y withEvent:theEvent select:YES];
            break;
        case NSCarriageReturnCharacter:
            [self editColumn:pt.x row:pt.y withEvent:theEvent select:YES];
            break;
        case NSDeleteCharacter:
            [self delete:self];
            break;
        case NSDownArrowFunctionKey:
            y = 1;
            break;
        case NSUpArrowFunctionKey:
            y = -1;
            break;
        case NSLeftArrowFunctionKey: 
            x = -1;
            break;
        case NSRightArrowFunctionKey:
            x = 1;
            break;
    }
    
    pt.x += x;
    if (pt.x < 0)
        pt.x += [self numberOfColumns];
    else if (pt.x >= [self numberOfColumns])
        pt.x -= [self numberOfColumns];
    
    pt.y += y;
    if (pt.y < 0)
        pt.y += [self numberOfRows];
    else if (pt.y >= [self numberOfRows])
        pt.y -= [self numberOfRows];
    
    
    [selectedCells release];
    selectedCells = [[NSArray arrayWithObject:NSStringFromPoint(pt)] retain];
    
    [self setNeedsDisplayInRect:[self frameOfCellAtColumn:oldPt.x row:oldPt.y]];
    [self setNeedsDisplayInRect:[self frameOfCellAtColumn:pt.x row:pt.y]];
}

#pragma mark mouse methods
//============================================================================================================================== Mouse Methods =======
- (void) mouseUp:(NSEvent *)theEvent
{
    if ([theEvent clickCount] == 2) {
        [self selectCellsInRect:SelectNoneRect];
    } else {
        NSPoint endPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
        [self selectCellsInRect:[self frameFrom:beginningPoint to:endPoint]];
    }
}

- (void) mouseDragged:(NSEvent *)theEvent
{
    NSPoint endPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    [self selectCellsInRect:[self frameFrom:beginningPoint to:endPoint]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
    if (!([theEvent modifierFlags] & NSShiftKeyMask)) {
        [[self delegate] tableView:self changedSelectionFrom:selectedCells withLastSelection:lastSelectedCells];
        [lastSelectedCells release];
        lastSelectedCells = [[selectedCells copy] retain];
        beginningPoint = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    }
    
    
    if ([theEvent clickCount] == 2) {
        int row = [self    rowAtPoint:beginningPoint];
        int col = [self columnAtPoint:beginningPoint];
        [self  selectRow:row byExtendingSelection:NO];
        [self editColumn:col row:row withEvent:theEvent select:YES];
    }
}


- (void) selectCellsInRect:(NSRect) frame
{
    
    if (NSEqualRects(frame,SelectNoneRect)) {
        [selectedCells release];
        selectedCells = [[NSArray array] retain];
        [self updateSelectedColumns];
    } else {
        
        NSPoint origin   = frame.origin;
        NSPoint endpoint = NSMakePoint(origin.x + frame.size.width,origin.y + frame.size.height);
        
        int endRow = [self    rowAtPoint:endpoint];
        int endCol = [self columnAtPoint:endpoint];
        int begRow = [self    rowAtPoint:origin];
        int begCol = [self columnAtPoint:origin];
        
        if (endRow == -1 && begRow == -1 && selectedCells != nil) {
            [selectedCells release];
            selectedCells = [[NSArray array] retain];
            [self updateSelectedColumns];
            [self setNeedsDisplay:YES];
            
            return;
        }
        
        // allows selection to begin or end outside of valid cells, but not both 
        if (endRow == -1)
            endRow = [self numberOfRows];
        if (endCol == -1) 
            endCol = [self numberOfColumns];
        
        NSMutableArray * newPoints = [NSMutableArray array];
        
        
        // selectedCells contains the column and row information for each selected cell
        // in the form of an NSString constructed from an NSPoint, (col,row)
        for (int row = begRow; row <= endRow; row++) {
            for (int col = begCol; col <= endCol; col++) {
                [newPoints addObject:NSStringFromPoint(NSMakePoint(col,row))];
            }
        }
        
        [selectedCells release];
        selectedCells = [[newPoints copy] retain];
        [self updateSelectedColumns];
        
    }
    
    [self setNeedsDisplay:YES];
}

- (void) updateSelectedColumns
{
    int max = 0;
    int min = [self numberOfColumns];
    
    for (int i = 0; i < [selectedCells count]; i++) {
        int x = NSPointFromString([selectedCells objectAtIndex:i]).x;
        if (x < min) min = x;
        if (x > max) max = x;
    }
    
    if (max == 0 && min == [self numberOfColumns])
        [super selectColumnIndexes:[NSIndexSet indexSet] byExtendingSelection:NO];
    else
        [super selectColumnIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(min, max - min + 1)]  byExtendingSelection:NO];
    
}

- (void) selectColumnIndexes:(NSIndexSet *)set byExtendingSelection:(BOOL) extension
{
    [super selectColumnIndexes:set byExtendingSelection:extension];
    NSMutableArray * newSel = [NSMutableArray array];
    
    unsigned int col = [set firstIndex];
    if (col == NSNotFound) return;
        
    do {
        for (int row = 0; row < [self numberOfRows]; row++)
            [newSel addObject:NSStringFromPoint(NSMakePoint(col,row))];
            
    } while ((col = [set indexGreaterThanIndex:col]) != NSNotFound);
    
    [selectedCells release];
    selectedCells = [[newSel copy] retain];
}
     



// given two points, construct a rectangle with them as upper left and lower right 
- (NSRect) frameFrom:(NSPoint)beginning to:(NSPoint)end
{
    int endX = end.x;
    int endY = end.y;
    
    int begX = beginning.x;
    int begY = beginning.y;
    
    int x,y,w,h;
    
    if (begX > endX) {
        x = endX;
        w = begX - endX;
    } else {
        x = begX;
        w = endX - begX;
    }
    
    if (begY > endY) {
        y = endY;
        h = begY - endY;
    } else {
        y = begY;
        h = endY - begY;
    }
    return NSMakeRect(x,y,w,h);
}

- (void)moveColumn:(int)columnIndex toColumn:(int)newIndex
{
    [super moveColumn:columnIndex toColumn:newIndex];
    if ([[self dataSource] respondsToSelector:@selector(tableView:didMoveColumn:toColumn:)])
        [[self dataSource] tableView:self didMoveColumn:columnIndex toColumn:newIndex];
}

- (BOOL) isAtLeastLeopard
{
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/CoreServices/SystemVersion.plist"];
    NSString *versionString = [dict objectForKey:@"ProductVersion"];
    NSArray *array = [versionString componentsSeparatedByString:@"."];
    int count = [array count];
    int major = (count >= 1) ? [[array objectAtIndex:0] intValue] : 0;
    int minor = (count >= 2) ? [[array objectAtIndex:1] intValue] : 0;
    
    if (major > 10 || major == 10 && minor >= 5)
        return YES;
    else
        return NO;
}


- (void) dealloc
{
    [selectedCells release];
    [lastSelectedCells release];
    
    [super dealloc];
}

@end
