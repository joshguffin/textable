//
//  TexTable.mm
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import "TexTable.h"

static NSString * TeXTablePBDataType = @"TeX Table Pasteboard Data Type";

@implementation TexTable

/* 
 Data is stored in the mutable array 'table', whose elements are
 in one-to-one correspondence with the number of rows of the table.
 Each element is a mutable array whose number of elements is equal
 to the number of columns of the table.
 
*/

- (id) init
{
    self = [super init];
    if (!self) return self;
    //create an empty table.
    table = [[NSMutableArray arrayWithObject:[NSMutableArray arrayWithObject:@""]] retain];
    numberOfRows = 0;
    numberOfColumns = 0;
    aligned     = YES;
    landscape   = NO;
    useWidth    = NO;
    usePosition = NO;
    
    return self;
}

- (id) initWithRows:(int)rows columns:(int)cols
{
    self = [self init];
    if (!self) return self;
    
    label               = [@" " retain];
    caption             = [@" " retain];
    alignmentFormatting = [@" " retain];
    width               = [@" " retain];
    position            = [@" " retain];
    
    [table release];
    table = [[self createTable:rows andCols:cols] retain];
    
    numberOfColumns = cols;
    numberOfRows    = rows;
    
    undoManager = [[NSUndoManager alloc] init];
    
    return self;
}

- (NSMutableArray *) createTable:(int) rows andCols:(int)cols
{
    NSMutableArray * columns  = [NSMutableArray array];
    NSMutableArray * newTable = [NSMutableArray array];
    
    for (int i = 0; i< cols; i++)
        //[columns addObject:[NSString stringWithFormat:@"%d",i]];
        [columns addObject:@""];
    
    for (int i = 0; i < rows; i++)
        [newTable addObject:[columns mutableCopy]];
    
    return newTable;
}

#pragma mark Table information
//========================================================================================================================================================
- (unsigned int) numberOfColumns
{
    return numberOfColumns;
}

- (unsigned int) numberOfRows
{
    return numberOfRows;
}

- (id) objectAtColumn:(unsigned int)column andRow:(unsigned int)row
{
    if (column >= numberOfColumns || row >= numberOfRows) return nil;
    return [[table objectAtIndex:row] objectAtIndex:column];
}

- (BOOL) setObjectAtColumn:(unsigned int)column andRow:(unsigned int)row toObject:(id) object
{
    if (column >= numberOfColumns || row >= numberOfRows) return NO;
    
    id currentObject = [self objectAtColumn:column andRow:row];
    if (![currentObject isEqual:object])
        [[undoManager prepareWithInvocationTarget:self] setObjectAtColumn:column andRow:row toObject:currentObject];
    
    [[table objectAtIndex:row] replaceObjectAtIndex:column withObject:object];
    return YES;
}

- (NSString *) alignmentFormatting
{
	return alignmentFormatting;
}
- (NSString *) caption
{
	return caption;
}
- (NSString *) label
{
	return label;
}
- (void) setAlignmentFormatting:(NSString *)newAlignmentFormatting
{
	[alignmentFormatting release];
	alignmentFormatting = [[newAlignmentFormatting copy] retain];
}
- (void) setCaption:(NSString *)newCaption
{
	[caption release];
	caption = [[newCaption copy] retain];
}
- (void) setLabel:(NSString *)newLabel
{
	[label release];
	label = [[newLabel copy] retain];
}

- (BOOL) centered
{ 
    return centered;
}
- (void) setCentered:(BOOL)isCentered
{
    centered = isCentered;
}
- (BOOL) aligned
{
	return aligned;
}
- (BOOL) landscape
{
	return landscape;
}
- (void) setAligned:(BOOL)newAligned
{
	aligned = newAligned;
}
- (void) setLandscape:(BOOL)newLandscape
{
	landscape = newLandscape;
}
- (NSString *) width
{
	return width;
}
- (NSString *) position
{
	return position;
}
- (void) setWidth:(NSString *)newWidth
{
	[width release];
	width = [newWidth retain];
}
- (void) setPosition:(NSString *)newPosition
{
	[position release];
	position = [newPosition retain];
}

- (BOOL) useWidth
{
	return useWidth;
}
- (BOOL) usePosition
{
	return usePosition;
}

- (void) setUseWidth:(BOOL)newUseWidth
{
	useWidth = newUseWidth;
}

- (void) setUsePosition:(BOOL)newUsePosition
{
	usePosition = newUsePosition;
}

- (void) undo
{
    [undoManager undo];
}

- (void) redo
{
    [undoManager redo];
}

- (NSString *) undoActionName
{
    return [undoManager undoActionName];
}

- (BOOL) canUndo
{
    return [undoManager canUndo];
}

- (BOOL) canRedo
{
    return [undoManager canRedo];
}

#pragma mark CSV Export/Import
//========================================================================================================================================================

- (NSString *) exportWithSeperator:(NSString *)seperator
{
    NSMutableString * output = [NSMutableString string];
    NSMutableArray * tempTable = [table mutableCopy];
    
    for (int row = 0; row < numberOfRows; row++) {
        for (int col = 0; col < numberOfColumns; col++) {
            NSString * elem = [[tempTable objectAtIndex:row] objectAtIndex:col];
            if (!NSEqualRanges(NSMakeRange(NSNotFound, 0), [elem rangeOfString:seperator]))
                [[tempTable objectAtIndex:row] setObject:[NSString stringWithFormat:@"\"%@\"",[[tempTable objectAtIndex:row] objectAtIndex:col]]
                                                 atIndex:col];
        }
        [output appendString:[[table objectAtIndex:row] componentsJoinedByString:seperator]];
        [output appendString:@"\n"];
    }
    return output;
}

- (NSArray *) arrayFromTSV
{
    NSMutableArray * result = [NSMutableArray array];
    NSArray         * lines = [self componentsSeparatedByString:@"\n"];
    NSEnumerator  * theEnum = [lines objectEnumerator];
    NSArray          * keys = nil;
    int            keyCount = 0;
    NSString * theLine;
    
    while (nil != (theLine = [theEnum nextObject]) ) {
        if (![theLine isEqualToString:@""] && ![theLine hasPrefix:@"#"])    // ignore empty lines and lines that startwith #
        {
            if (nil == keys)    // Is keys not set yet? If so, process first real line as list of keys
            {
                keys = [theLine componentsSeparatedByString:@"\t"];
                keyCount = [keys count];
            } else {
                NSMutableDictionary    *lineDict    = [NSMutableDictionary dictionary];
                NSArray                *values        = [theLine componentsSeparatedByString:@"\t"];
                int                    valueCount    = [values count];
                int i;
                
                for ( i = 0 ; i < keyCount && i < valueCount ; i++ ) {
                    NSString *value = [values objectAtIndex:i];
                    if (nil != value && ![value isEqualToString:@""])
                        [lineDict setObject:value forKey:[keys objectAtIndex:i]];
                }
                if ([lineDict count])    // only add the line if there was any data
                {
                    [result addObject:lineDict];
                }
            }
        }
    }
    return result;
}


- (void) importFromCSVfile:(NSString *) path
{
    NSLog(@"parsing %@",path);
    
    CSVParser *parser = [CSVParser new];
    [parser openFile:path];
    NSMutableArray *csvContent = [parser parseFile];
    [parser closeFile];
    
    int maxwidth = 0;
    for (int row = 0; row < [csvContent count]; row++)
        maxwidth = ([[csvContent objectAtIndex:row] count] > maxwidth ? [[csvContent objectAtIndex:row] count] : maxwidth);
    
    for (int row = 0; row < [csvContent count]; row++)
        while ([[csvContent objectAtIndex:row] count] != maxwidth)
            [[csvContent objectAtIndex:row] addObject:@""];
    
    [table release];
    table = [csvContent retain];
    
    numberOfRows    = [table count];
    numberOfColumns = [[table objectAtIndex:0] count];
}

#pragma mark TeX Export/Import
//========================================================================================================================================================
- (NSString *) texify
{
    NSMutableString * output = [NSMutableString string];

    if (landscape)
        [output appendString:@"% don't forget to add \\usepackage{lscape}\n\n\\begin{landscape}\n"];
    
    [output appendFormat:@"\\begin{table}\n"];
    
    if (centered)
        [output appendString:@"\t\\begin{center}\n\t"];
    
    if (useWidth)    
        [output appendFormat:@"\t\\begin{tabular*}{%@}",width];
    else
        [output appendFormat:@"\t\\begin{tabular}",width];
    
    if (usePosition) [output appendFormat:@"[%@]",position];
    [output appendFormat:@"{%@}\n",alignmentFormatting];
    
    // maxWidths has one entry per column
    NSMutableArray * maxWidths = [NSMutableArray array];
    
    // first, we find the column width for each column
    for (int col = 0; col < numberOfColumns; col++) {
        unsigned int maxWidth = 0;
        for (int row = 0; row < numberOfRows; row++) {
            NSString * value = [[table objectAtIndex:row] objectAtIndex:col];
            unsigned int length = [value length];
            if (maxWidth < length)
                maxWidth = length;
        }
        [maxWidths addObject:[NSNumber numberWithUnsignedInt:maxWidth]];
    }
    
    //now, construct the string, so that all the & are aligned.
    for (int row = 0; row < numberOfRows; row++) {
        [output appendString:(centered?@"\t\t\t":@"\t\t")];
        
        for (int col = 0; col < numberOfColumns; col++) {
            NSString *toAdd;
            
            if (aligned)
                toAdd = [self padString:[[table objectAtIndex:row] objectAtIndex:col]
                               toLength:[[maxWidths objectAtIndex:col] unsignedIntValue]];
            else
                toAdd = [[table objectAtIndex:row] objectAtIndex:col];
            
            [output appendString:toAdd];
            if (col != numberOfColumns - 1)
                [output appendString:@" & "];
                
        }
        if (row != numberOfRows - 1) 
            [output appendString:@" \\\\ \n"];
        else
            [output appendString:@"\n"];
    }
    
    if (useWidth)    
        [output appendFormat:@"%@\\end{tabular*}\n",(centered?@"\t\t":@"\t")];
    else
        [output appendFormat:@"%@\\end{tabular}\n",(centered?@"\t\t":@"\t")];
    
    [output appendFormat:@"%@\\caption{%@}\n",(centered?@"\t\t":@"\t"),caption];
    [output appendFormat:@"%@\\label{%@}\n",  (centered?@"\t\t":@"\t"),label];
    
    if (centered)
        [output appendString:@"\t\\end{center}\n"];
    
    [output appendString:@"\\end{table}\n"];
    
    if (landscape)
        [output appendString:@"\\end{landscape}\n"];
    
    
    return output;
}

// returns nil if there is no error, otherwise an informative error message.
- (NSString *) importTeX:(NSString *)tableString 
{
    NSCharacterSet * cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    NSString *returnString = nil;
    
    
    // /------------------------------------------------------------------------------------------\
    // | Get the contents of the table, which is between \begin and \end {tabular}'s
    // | also, check if the table's alignment has been specified
    // \------------------------------------------------------------------------------------------/
    NSScanner * scan = [[[NSScanner alloc] initWithString:tableString] autorelease];
    [scan setCharactersToBeSkipped:nil];
    
    NSString *theTable = nil;
    [scan scanUpToString:@"\\begin{tabular}" intoString:nil];
    [scan     scanString:@"\\begin{tabular}" intoString:nil];
    
    int tableBeginLoc = [scan scanLocation];
    
    // /-----------------------------------------------------------------------------------\
    // | if '&' wasn't found, but a '{' was, then there are arguments to the 
    // | tabular environment.  otherwise, no arguments are specified.
    // | this code reads arguments in the form {width}[pos]{cols}
    // \-----------------------------------------------------------------------------------/
    
    NSString *remaining = [tableString substringFromIndex:tableBeginLoc];
    
    [scan scanUpToString:@"\n" intoString:&remaining];
    [scan scanString:@"\n"     intoString:nil];
    
    NSDictionary * args = [self scanArguments:remaining];
    
    NSString * temp;
    
    [width release];
    [alignmentFormatting release];
    [position release];
    
    if (temp = [args valueForKey:@"Alignment"])
        alignmentFormatting = [[temp copy] retain];
    else 
        alignmentFormatting = [@"" retain];
    if (temp = [args valueForKey:@"Width"]) {
        width = [[temp copy] retain];
        useWidth = YES;
    } else {
        useWidth = NO;
        width = [@"" retain];
    }
    if (temp = [args valueForKey:@"Position"]) {
        position = [[temp copy] retain];
        usePosition = YES;
    } else {
        usePosition = NO;
        position = [@"" retain];
    }
    // \-----------------------------------------------------------------------------------/
    
    [scan scanUpToString:@"\\end{tabular}" intoString:&theTable];
    [scan     scanString:@"\\end{tabular}" intoString:nil];
    
    if (!theTable)
        return nil;
    // \------------------------------------------------------------------------------------------/
    
    
    // /------------------------------------------------------------------------------------------\
    // | now we need to check for the caption and label.  since they might be accidentally
    // | order-reversed, we need to store the scan location
    // \------------------------------------------------------------------------------------------/
    
    NSString           *regexString = @"caption\\{([^\\}]*)\\}";
    OFRegularExpression    *express = [[OFRegularExpression alloc] initWithString:regexString];
    OFRegularExpressionMatch *match = [express matchInString:tableString];
    
    if ([match subexpressionAtIndex:0]) {
        [caption release];
        caption = [[[match subexpressionAtIndex:0] copy] retain];
    }
    
    [express  release];
    regexString = @"label\\{([^\\}]*)\\}";
    express     = [[OFRegularExpression alloc] initWithString:regexString];
    match       = [express matchInString:tableString];
    
    if ([match subexpressionAtIndex:0]) {
        [label release];
        label = [[[match subexpressionAtIndex:0] copy] retain];
    }
    // \------------------------------------------------------------------------------------------/
    
    
    // /------------------------------------------------------------------------------------------\
    // | Check if the table is set as centered                                                    |
    // \------------------------------------------------------------------------------------------/
    regexString = @"\\begin{center}";
    express     = [[[OFRegularExpression alloc] initWithString:regexString] autorelease];
    match       = [express matchInString:tableString];
    centered    = (match != nil);
    // \------------------------------------------------------------------------------------------/
    
    
    NSMutableString * mutTable = [NSMutableString stringWithString:theTable];
    
    // remove 'hline's, since they'll confuse the table 
    if (!NSEqualRanges(NSMakeRange(NSNotFound,0),[mutTable rangeOfString:@"\\hline"])) {
        [mutTable replaceOccurrencesOfString:@"\\hline" withString:@"" options:NSLiteralSearch range:NSMakeRange(0,[mutTable length])];
        returnString = @"Removed \\hline from your table";
    }
    
    NSArray * rows = [mutTable componentsSeparatedByString:@"\\\\"];
    
    if (table)
        [table release];
    
    table = [[NSMutableArray array] retain];
    int numCols = 0;
    numberOfRows = [rows count];
    
    // /------------------------------------------------------------------------------------------\
    // | for each row in the table, find the cells and the total number of columns in the row.
    // \------------------------------------------------------------------------------------------/
    for (int i = 0; i < numberOfRows; i++) {
        
        [table addObject:[NSMutableArray array]];
        NSArray * cols = [[rows objectAtIndex:i] componentsSeparatedByString:@"&"];
        
        for (int j = 0; j < [cols count]; j++) {
            [[table objectAtIndex:i] addObject:
                [[cols objectAtIndex:j] stringByTrimmingCharactersInSet:cs]];
        }
        if (numCols < [cols count])
            numCols = [cols count];
    }
    // \------------------------------------------------------------------------------------------/
    
    
    // /------------------------------------------------------\
    // | pad each row with empty strings  if necessary, 
    // | so that the table is square
    // \------------------------------------------------------/
    numberOfColumns = numCols;
    for (int i = 0; i < numberOfRows; i++) {
        while ([[table objectAtIndex:i] count] != numCols)
            [[table objectAtIndex:i] addObject:@""];
    }
    // \------------------------------------------------------/
    
    return returnString;
}

// string MUST NOT CONTAIN THE OPENING BRACKET!!!
// that is, if you want to read "{arg} blah blah", pass it "arg} blah blah"
- (NSString *) read:(NSString *)string untilClosing:(NSString*)bracket
{
    NSString * openingBracket;
    
    if ([bracket isEqualToString:@"]"])
        openingBracket = @"[";
    else if ([bracket isEqualToString:@"}"])
        openingBracket = @"{";
    else if ([bracket isEqualToString:@")"])
        openingBracket = @"(";
    else 
        return nil;

    int openBrackets = 1;

    int location = 0;

    for (; location < [string length]; location++) {
        if ([string characterAtIndex:location] == [openingBracket characterAtIndex:0])
            openBrackets++;
        if ([string characterAtIndex:location] == [bracket characterAtIndex:0])
            openBrackets--;
        if (openBrackets == 0)
            break;
    }
        
    return [string substringToIndex:location];
}

- (NSDictionary *) scanArguments:(NSString *) arguments
{
    NSMutableDictionary * output = [NSMutableDictionary dictionary];
    NSMutableArray      * bracketargs   = [NSMutableArray array];
    NSMutableArray      * braceargs   = [NSMutableArray array];
    
    int location = 0;
    for (; location < [arguments length]; location++) {
        if ([arguments characterAtIndex:location] == [@"{" characterAtIndex:0]) {
            NSString *arg = [self read:[arguments substringFromIndex:location+1] untilClosing:@"}"];
            if (arg) {
                [braceargs addObject:arg];
                location += [arg length]+1;
            }
        } else if ([arguments characterAtIndex:location] == [@"[" characterAtIndex:0]) {
            NSString * arg = [self read:[arguments substringFromIndex:location+1] untilClosing:@"]"];
            if (arg) {
                [bracketargs addObject:arg];
                location += [arg length]+1;
            }
        }
        if ([braceargs count]+[bracketargs count] == 3) break;
    }
    
    location = 0;
    
    switch ([braceargs count]) {
        case 2:
            [output setObject:[braceargs objectAtIndex:location] forKey:@"Width"];
            location++;
        case 1:
            [output setObject:[braceargs objectAtIndex:location] forKey:@"Alignment"];
    }
    
    if ([bracketargs count] > 0) {
        [output setObject:[bracketargs objectAtIndex:0] forKey:@"Position"];
        location++;
    }

    return [output copy];
}


- (NSString *) padString:(NSString *)string toLength:(unsigned int) length
{
    NSMutableString * output = [NSMutableString stringWithString:string];
    unsigned int toAdd = length - [string length];
    for (int i = 0; i < toAdd; i++)
        [output appendString:@" "];
    return [output copy];
}

#pragma mark Table Operations
//========================================================================================================================================================
- (BOOL) insertRow:(NSArray *)rowItems atIndex:(unsigned int)rowIndex
{
    if ([rowItems count] != numberOfColumns || rowIndex > numberOfRows) return NO;
    [table insertObject:[NSMutableArray arrayWithArray:rowItems] atIndex:rowIndex];
    
    [[undoManager prepareWithInvocationTarget:self] deleteRowAtIndex:rowIndex];
    
    numberOfRows = [table count];
    return YES;
}

- (BOOL) exchangeColumn:(int)col1 andColumn:(int)col2
{
    [undoManager beginUndoGrouping];
    
    for (int row = 0; row < numberOfRows; row++) {
        NSString * col1Val = [self objectAtColumn:col1 andRow:row];
        NSString * col2Val = [self objectAtColumn:col2 andRow:row];
        
        [[undoManager prepareWithInvocationTarget:self] setObjectAtColumn:col1 andRow:row toObject:col1Val];
        [[undoManager prepareWithInvocationTarget:self] setObjectAtColumn:col2 andRow:row toObject:col2Val];
        
        [self setObjectAtColumn:col1 andRow:row toObject:col2Val];
        [self setObjectAtColumn:col2 andRow:row toObject:col1Val];
    }
    
    [undoManager endUndoGrouping];
    
    return YES;
}

- (BOOL) deleteRowAtIndex:(unsigned int)rowIndex
{
    if (rowIndex >= numberOfRows) return NO;
    
    [[undoManager prepareWithInvocationTarget:self] insertRow:[table objectAtIndex:rowIndex] atIndex:rowIndex];
    
    [table removeObjectAtIndex:rowIndex];
    numberOfRows = [table count];
    
    return YES;
}

- (BOOL) insertColumn:(NSArray *)columnItems atIndex:(unsigned int)columnIndex
{
    if ([columnItems count] != numberOfRows || columnIndex > numberOfColumns) return NO;
    
    for (int i = 0; i < numberOfRows; i++) 
        [[table objectAtIndex:i] insertObject:[columnItems objectAtIndex:i] atIndex:columnIndex];
    
    numberOfColumns = [[table objectAtIndex:0] count];
    return YES;
}

- (NSArray *) rowAtIndex:(int) rowIndex
{
    return [NSArray arrayWithArray:[table objectAtIndex:rowIndex]];
}

- (NSArray *) columnAtIndex:(int) columnIndex
{
    NSMutableArray * column = [NSMutableArray array];
    for (int i = 0; i < numberOfRows; i++)
        [column addObject:[[table objectAtIndex:i] objectAtIndex:columnIndex]];
    
    return column;
}

- (BOOL) deleteColumnAtIndex:(unsigned int)columnIndex
{
    if (columnIndex >= numberOfColumns) return NO;
    
    [[undoManager prepareWithInvocationTarget:self] insertColumn:[self columnAtIndex:columnIndex] atIndex:columnIndex];
    
    for (int i = 0; i < numberOfRows; i++)
        [[table objectAtIndex:i] removeObjectAtIndex:columnIndex];
        
    numberOfColumns = [[table objectAtIndex:0] count];
    
    return YES;
}

- (void) addRow
{
    NSMutableArray * newRow = [NSMutableArray array];
    for (int i = 0; i < numberOfColumns; i++)
        [newRow addObject:@""];
    [self insertRow:newRow atIndex:numberOfRows];
}

- (void) addRowAtIndex:(int) row
{
    NSMutableArray * newRow = [NSMutableArray array];
    for (int i = 0; i < numberOfColumns; i++)
        [newRow addObject:@""];
    [self insertRow:newRow atIndex:row];
}

- (void) addColumn
{
    NSMutableArray * newCol = [NSMutableArray array];
    for (int i = 0; i < numberOfRows; i++)
        [newCol addObject:@""];
    [self insertColumn:newCol atIndex:numberOfColumns];
}

- (void) addColumnAtIndex:(int) column
{
    NSMutableArray * newCol = [NSMutableArray array];
    for (int i = 0; i < numberOfRows; i++)
        [newCol addObject:@""];
    [self insertColumn:newCol atIndex:column];
}

//  replace each cell location in the array with its string surrounded by $'s
- (void) surround:(NSArray *) cells
{
    [undoManager beginUndoGrouping];
    for (int i = 0; i < [cells count]; i++) {
        NSPoint pt = NSPointFromString([cells objectAtIndex:i]);
        
        // skip invalid cells
        if (pt.x < 0 || pt.y < 00) continue;
        
        NSString * obj = [self objectAtColumn:pt.x andRow:pt.y];
        
        [[undoManager prepareWithInvocationTarget:self] setObjectAtColumn:pt.x andRow:pt.y toObject:obj];
        [self setObjectAtColumn:pt.x andRow:pt.y toObject:[NSString stringWithFormat:@"$%@$",obj]];
    }
    [undoManager endUndoGrouping];
}

// selection assumed to be SQUARE
- (BOOL) transpose:(NSArray *) cells
{
    int upperLeftCol = numberOfColumns;
    int upperLeftRow = numberOfRows;
    
    int lowerRightCol = 0;
    int lowerRightRow = 0;
    
    
    NSMutableDictionary * oldVals = [NSMutableDictionary dictionary];
    // /-----------------------------------------------------------------------------------------------\
    // | We need to know the upper left and lower right locations, so that the transposition only  
    // | occurs within the selection.  We check here if it is square.
    // \-----------------------------------------------------------------------------------------------/
    for (int i = 0; i < [cells count]; i++) {
        NSPoint cell = NSPointFromString([cells objectAtIndex:i]);
        if (upperLeftCol > cell.x)
            upperLeftCol = cell.x;
        if (lowerRightCol < cell.x)
            lowerRightCol = cell.x;
        if (upperLeftRow > cell.y)
            upperLeftRow = cell.y;
        if (lowerRightRow < cell.y)
            lowerRightRow = cell.y;
        
        // find what the old values of the selected cells are
        [oldVals setObject:[self objectAtColumn:cell.x andRow:cell.y]
                    forKey:NSStringFromPoint(NSMakePoint(cell.x,cell.y))];
    }
    if (lowerRightCol - upperLeftCol != lowerRightRow - upperLeftRow) return NO; // not square!
    // \-----------------------------------------------------------------------------------------------/
    
    [undoManager beginUndoGrouping];
        
    NSArray *keys = [oldVals allKeys];
    for (int i = 0; i < [keys count]; i++) {
        NSPoint cell = NSPointFromString([keys objectAtIndex:i]);
        
        int x = upperLeftCol + (cell.y - upperLeftRow);
        int y = upperLeftRow + (cell.x - upperLeftCol);
        
        [self setObjectAtColumn:x andRow:y toObject:[oldVals objectForKey:[keys objectAtIndex:i]]];
        [[undoManager prepareWithInvocationTarget:self] setObjectAtColumn:cell.x andRow:cell.y 
                                                                 toObject:[oldVals objectForKey:[keys objectAtIndex:i]]];
    }
    
    [undoManager endUndoGrouping];
    return YES;
}


#pragma mark Copy/Paste Support
//========================================================================================================================================================
/* 
 For internal use, cells are stored in an archived nsdictionary, with keys 
 of the form "(col,row)" and objects the string at that location.
 Also available is the string form, with the format 
   a  &  b  &  c
   d  &  e  &  f
 */
- (void) copyCells:(NSArray *) cells
{
    NSMutableDictionary * output = [NSMutableDictionary dictionary];
    
    int upperLeftCol = numberOfColumns;
    int upperLeftRow = numberOfRows;
    
    int lowerRightCol = 0;
    int lowerRightRow = 0;
    
    // /-----------------------------------------------------------------------------------------------\
    // | We need to know the upper left and lower right locations, so that the string 
    // | can be constructed properly, and so that the origin of the copy can be added
    // | to the dictionary.  This is so that an offset may be constructed when pasting.
    // \-----------------------------------------------------------------------------------------------/
    for (int i = 0; i < [cells count]; i++) {
        NSPoint cell = NSPointFromString([cells objectAtIndex:i]);
        [output setObject:[self objectAtColumn:cell.x andRow:cell.y] forKey:[cells objectAtIndex:i]];
        if (upperLeftCol > cell.x)
            upperLeftCol = cell.x;
        if (lowerRightCol < cell.x)
            lowerRightCol = cell.x;
        if (upperLeftRow > cell.y)
            upperLeftRow = cell.y;
        if (lowerRightRow < cell.y)
            lowerRightRow = cell.y;
    }
    // \-----------------------------------------------------------------------------------------------/
    
    if ([cells count] == 1 && upperLeftRow < 0) return;
    
    // /-----------------------------------------------------------------------------------------------\
    // | Construct the output dictionary
    // \-----------------------------------------------------------------------------------------------/
    [output setObject:NSStringFromPoint(NSMakePoint(upperLeftCol,upperLeftRow)) forKey:@"Origin"];
    
    NSData* clipData = [NSKeyedArchiver archivedDataWithRootObject:output];
    NSPasteboard* cb = [NSPasteboard generalPasteboard];
    
    [cb declareTypes:[NSArray arrayWithObjects:TeXTablePBDataType, NSStringPboardType,nil] owner:self];
    [cb setData:clipData forType:TeXTablePBDataType];
    // \-----------------------------------------------------------------------------------------------/
    
    
    // /----------------------------------------------------------------------------\
    // | Construct the output string
    // \----------------------------------------------------------------------------/
    NSMutableString * texString = [NSMutableString string];
    for (int row = upperLeftRow; row <= lowerRightRow; row++) {
        for (int col = upperLeftCol; col <= lowerRightCol; col++) {
            [texString appendFormat:@" %@ ",[self objectAtColumn:col andRow:row]];
            if (col != lowerRightCol)
                [texString appendString:@"&"];
            else
                [texString appendString:@"\n"];
        }
    }
    [cb setString:[texString copy] forType:NSStringPboardType];
    // \----------------------------------------------------------------------------/
}

- (void) deleteCells:(NSArray *) cells
{
    [undoManager beginUndoGrouping];
    for (int i = 0; i < [cells count]; i++) {
        NSPoint cell = NSPointFromString([cells objectAtIndex:i]);
        int x = cell.x;
        int y = cell.y;
        
        [[undoManager prepareWithInvocationTarget:self] setObjectAtColumn:x andRow:y toObject:[self objectAtColumn:x andRow:y]];
        [self setObjectAtColumn:x andRow:y toObject:@""];
    }
    [undoManager endUndoGrouping];
}

- (void) pasteCellsAt:(NSPoint) location
{
    NSPasteboard* cb = [NSPasteboard generalPasteboard];
    NSString* type = [cb availableTypeFromArray:[NSArray arrayWithObjects:TeXTablePBDataType, nil]];
    
    if ( type )
    {
        NSData    * clipData = [cb dataForType:type];
        NSDictionary * cells = [NSKeyedUnarchiver unarchiveObjectWithData:clipData];
        
        NSPoint origin = NSPointFromString([cells objectForKey:@"Origin"]);
        
        if ((origin.x < 0 || origin.y < 0) && [cells count] < 3) return;
        
        int xOffset = location.x - origin.x;
        int yOffset = location.y - origin.y;
        
        NSArray * keys = [[cells allKeys] arrayByRemovingObject:@"Origin"];
        
        [undoManager beginUndoGrouping];
        
        for (int i = 0; i < [keys count]; i++) {
            NSPoint cellPoint = NSPointFromString([keys objectAtIndex:i]);
            
            int x = (cellPoint.x + xOffset), y = (cellPoint.y + yOffset) ;
            
            if (0 <= x < numberOfColumns && 0 <= y < numberOfRows) {
                [self setObjectAtColumn:x andRow:y toObject:[cells objectForKey:[keys objectAtIndex:i]]];
                [[undoManager prepareWithInvocationTarget:self] setObjectAtColumn:x andRow:y toObject:[self objectAtColumn:x andRow:y]];
            }
        }
        [undoManager endUndoGrouping];

    }
}

- (NSUndoManager *) undoManager
{
    return undoManager;
}

- (void) dealloc
{
    [table release];
    
    [alignmentFormatting release];
    [caption release];
    [label release];
    [width release];
    [position release];
    [undoManager release];
    
    [super dealloc];
}

@end