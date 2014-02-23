//
//  TTSCellSelectionTableView.h
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import <Cocoa/Cocoa.h>
#import "TTSTextFieldSelectableCell.h"

@interface TTSCellSelectionTableView : NSTableView {
    
    NSRect SelectNoneRect;
    
    NSPoint beginningPoint;
    NSArray * selectedCells;
    NSArray * lastSelectedCells;
    
    BOOL isEditing;
    
}
- (void)selectAll:(id)sender;
- (void)    clear:(id)sender;

- (NSArray *) selectedCells;
- (NSRect) frameFrom:(NSPoint)beginning to:(NSPoint)end;
- (void) selectCellsInRect:(NSRect) frame;
- (void) selectCellAtColumn:(int) col andRow:(int) row;
- (void) setSelectionTo:(NSArray *) selection withLastSelection:(NSArray *) lastSelection;
- (void) distributeColumns;
- (void) insert:(id)sender;
- (BOOL) validSelection;
- (BOOL) isAtLeastLeopard;
- (NSIndexSet *) selectedColumns;
- (NSIndexSet *) selectedRows;

@end

@interface NSObject (TTSCellSelectionTableViewDelegateMethod)
- (BOOL)canPaste;
- (BOOL) canTranspose:(NSArray *) cells;
- (BOOL)tableView:(TTSCellSelectionTableView *)tv changedSelectionFrom:(NSArray *)selection withLastSelection:(NSArray *)lastSelection;
@end

@interface NSObject (TTSCellSelectionTableViewDatasourceMethod)
- (void) tableView:(TTSCellSelectionTableView *)tv didMoveColumn:(int) column toColumn:(int) newColumn;
@end