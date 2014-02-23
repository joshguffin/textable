//
//  TTSTextFieldSelectableCell.h
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import <Cocoa/Cocoa.h>


@interface TTSTextFieldSelectableCell : NSTextFieldCell {
    BOOL _selected;
}

- (BOOL) isSelected;
- (void) setSelected:(BOOL)selected;

@end
