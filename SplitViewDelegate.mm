//
//  SplitViewDelegate.mm
//  TexTable
//
//  Created by Josh Guffin on 19/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import "SplitViewDelegate.h"


@implementation SplitViewDelegate

- (void) awakeFromNib
{
    [controlsTeXSplitView setStateFromString:[[NSUserDefaults standardUserDefaults] valueForKey:@"Left/Right Split View State"]];
    [tableTextSplitView   setStateFromString:[[NSUserDefaults standardUserDefaults] valueForKey:@"Up/Down Split View State"]];
    canSaveState = YES;
}

// cause the left of the horizontally split panes and the lower of the vertically 
// split panes to be of constant size when the window is resizing
- (void)splitView:(RBSplitView*)sender wasResizedFrom:(float)oldDimension to:(float)newDimension
{
    if (sender == controlsTeXSplitView)
        [sender adjustSubviewsExcepting:[sender subviewAtPosition:0]];
    if (sender == tableTextSplitView)
        [sender adjustSubviewsExcepting:[sender subviewAtPosition:1]];
    
}

// remember the position of the subviews upon resize
- (void)didAdjustSubviews:(RBSplitView*)sender
{
    if (canSaveState) {
    if (sender == controlsTeXSplitView)
        [[NSUserDefaults standardUserDefaults] setValue:[sender stringWithSavedState] forKey:@"Left/Right Split View State"];
    if (sender == tableTextSplitView)
        [[NSUserDefaults standardUserDefaults] setValue:[sender stringWithSavedState] forKey:@"Up/Down Split View State"];
    }
}



@end
