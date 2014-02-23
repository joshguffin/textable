//
//  TTSTextFieldSelectableCell.mm
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import "TTSTextFieldSelectableCell.h"


@implementation TTSTextFieldSelectableCell


- (BOOL) isSelected
{
    return _selected;
}

- (void) setSelected:(BOOL)selected
{
    _selected = selected;
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
    if ([self isSelected]) {
        [[NSColor colorWithCalibratedRed:0.08 green:0.08 blue:0.95 alpha:1] set];
        [NSBezierPath fillRect:cellFrame];
    } else {
        [[NSColor whiteColor] set];
        [NSBezierPath fillRect:cellFrame];
    }
    
    NSMutableParagraphStyle *style = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
    [style setLineBreakMode:NSLineBreakByTruncatingTail];
    
    NSString * value = [self objectValue];
    NSAttributedString * title;
    
    if ([value isEqualToString:@""]) {
        NSColor *textColor;
        if ([self isSelected])
            textColor = [NSColor colorWithCalibratedWhite:0.8 alpha:1];
        else
            textColor = [NSColor grayColor];
        title = [[[NSAttributedString alloc] initWithString:@"<empty>"
                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [NSFont fontWithName:@"Monaco" size:13],NSFontAttributeName,
                                                             textColor,NSForegroundColorAttributeName,
                                                             style,NSParagraphStyleAttributeName,
                                                             nil]] autorelease];
    } else {
        NSColor *textColor;
        if ([self isSelected])
            textColor = [NSColor whiteColor];
        else
            textColor = [NSColor blackColor];
        
        title = [[[NSAttributedString alloc] initWithString:value
                                                 attributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [NSFont fontWithName:@"Monaco" size:13],NSFontAttributeName,
                                                             textColor,NSForegroundColorAttributeName,
                                                             style,NSParagraphStyleAttributeName,
                                                             nil]] autorelease];
    }
    
    NSRect insetFrame = NSMakeRect(cellFrame.origin.x+5,cellFrame.origin.y+5,cellFrame.size.width-5,cellFrame.size.height-5);
    
    [title drawInRect:insetFrame];
            
    //[super drawWithFrame:cellFrame inView:controlView];
}

@end
