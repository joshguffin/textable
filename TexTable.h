//
//  TexTable.h
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import <Cocoa/Cocoa.h>
#import <OmniFoundation/OmniFoundation.h>
#import <Foundation/Foundation.h>
#import "parseCSV.h"

@interface TexTable : NSObject {
    
    unsigned int numberOfColumns;
    unsigned int numberOfRows;
    
    BOOL landscape;
    BOOL aligned;
    
    BOOL usePosition;
    BOOL useWidth;
    BOOL centered;
    
    NSMutableArray * table;
    NSString * width;
    NSString * position;
    NSString * alignmentFormatting;
    NSString * label;
    NSString * caption;
    
    NSUndoManager * undoManager;
}

- (id) initWithRows:(int)rows columns:(int)cols;
- (NSMutableArray *) createTable:(int) rows andCols:(int)cols;
- (void) redo;
- (void) undo;
- (NSString *) undoActionName;
- (NSUndoManager *) undoManager;

// ------------------------------ table operations -------------------------------

- (BOOL) canUndo;
- (BOOL) canRedo;
- (void) copyCells:(NSArray *) cells;
- (void) deleteCells:(NSArray *) cells;
- (void) pasteCellsAt:(NSPoint) location;
- (BOOL) exchangeColumn:(int)col1 andColumn:(int)col2;

// ------------------------------ table information ------------------------------
- (unsigned int) numberOfColumns;
- (unsigned int) numberOfRows;
- (id) objectAtColumn:(unsigned int)column andRow:(unsigned int)row;
- (BOOL) setObjectAtColumn:(unsigned int)column andRow:(unsigned int)row toObject:(id) object;
- (NSString *) alignmentFormatting;
- (NSString *) caption;
- (NSString *) label;
- (void) setAlignmentFormatting:(NSString *)newAlignmentFormatting;
- (void) setCaption:(NSString *)newCaption;
- (void) setLabel:(NSString *)newLabel;
- (BOOL) centered;
- (BOOL) aligned;
- (BOOL) landscape;
- (void) setCentered:(BOOL)isCentered;
- (void) setAligned:(BOOL)newAligned;
- (void) setLandscape:(BOOL)newLandscape;
- (NSString *) width;
- (NSString *) position;
- (void) setWidth:(NSString *)newWidth;
- (void) setPosition:(NSString *)newPosition;
- (BOOL) useWidth;
- (BOOL) usePosition;
- (void) setUseWidth:(BOOL)newUseWidth;
- (void) setUsePosition:(BOOL)newUsePosition;

// -------------------------------- export/import --------------------------------
- (NSString *) texify;
- (NSString *) exportWithSeperator:(NSString *)seperator;
- (void) importFromCSVfile:(NSString *) path;
- (NSDictionary *) scanArguments:(NSString *) arguments;
- (NSString *) importTeX:(NSString *)tableString;
- (NSString *) padString:(NSString *)string toLength:(unsigned int) length;

// --------------------------------- row editing ---------------------------------
- (BOOL) insertRow:(NSArray *)rowItems atIndex:(unsigned int)rowIndex;
- (BOOL) deleteRowAtIndex:(unsigned int)rowIndex;
- (BOOL) insertColumn:(NSArray *)columnItems atIndex:(unsigned int)columnIndex;
- (BOOL) deleteColumnAtIndex:(unsigned int)columnIndex;
- (NSArray *) columnAtIndex:(int) columnIndex;
- (NSArray *) rowAtIndex:(int) rowIndex;
- (void) addRow;
- (void) addColumn;
- (void) addRowAtIndex:(int) row;
- (void) addColumnAtIndex:(int) column;
- (BOOL) transpose:(NSArray *) cells;
- (void)  surround:(NSArray *) cells;



@end
