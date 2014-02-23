//
//  LatexController.mm
//  TexTable
//
//  Created by Josh Guffin on 30/11/07.
//  Copyright 2007 Josh Guffin. 
//  Released under the GPL (see gpl-3.0.txt in the Resources for details)
//

#import "LatexController.h"

static NSString * ZoomSliderToolbarItemIdentifier = @"Zoom Slider Toolbar Identifier";
static NSString * ZoomTextToolbarItemIdentifier   = @"Zoom Text Toolbar Identifier";
static NSString * AutoZoomToolbarItemIdentifier   = @"Auto Zoom Toolbar Identifier";
static NSString * RunTeXToolbarItemIdentifier     = @"Run TeX Toolbar Identifier";

static float bFactor = 0.0529835;

@implementation LatexController

- (void) awakeFromNib
{
    NSToolbar *tb = [[[NSToolbar alloc] initWithIdentifier:@"TeXtable PDF Preview Identifier"] autorelease];
    [tb setAllowsUserCustomization:YES];
    [tb setAutosavesConfiguration:YES];
    [tb setShowsBaselineSeparator:YES];
    [tb setDisplayMode:NSToolbarDisplayModeIconOnly];
    [tb setDelegate:self];
    
    [previewWindow setToolbar:tb];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(handlePageChangedNotification:) 
               name:PDFViewPageChangedNotification object:pdf];
    [nc addObserver:self selector:@selector(scaleChanged:) name:PDFViewScaleChangedNotification object:pdf];
    
    [pdf setScaleFactor:[[self valueForKey:@"Scale Factor"] floatValue]];
    [pdf  setAutoScales:[[self valueForKey:@"Auto Scales"]   boolValue]];
}

- (void) setController:(id) contr
{
    controller = contr;
}

- (NSString *) latexWithPreamble:(NSString *)preamble andTable:(NSString *)table
{
    // write the latex to a file
    NSString * latexString = [NSString stringWithFormat:@"%@\n\\begin{document}\n%@\n\\end{document}",preamble,table];
    NSString * tempDir = NSTemporaryDirectory();
    NSString * texPath = [NSString stringWithFormat:@"%@%@",tempDir,@"TexTablePreview.tex"];
    NSString * pdfPath = [NSString stringWithFormat:@"%@%@",tempDir,@"TexTablePreview.pdf"];
    [latexString writeToFile:texPath atomically:YES];
    
    NSString *pdfLatexPath = [[NSUserDefaults standardUserDefaults] valueForKey:@"pdflatex Path"];
    if (!pdfLatexPath) return [NSString stringWithFormat:@"pdflatex not found at path \"%@\"",
                               [[NSUserDefaults standardUserDefaults] valueForKey:@"pdflatex Path"]];
    
    NSString * output = [self run:pdfLatexPath 
                    withArguments:[NSArray arrayWithObjects:@"-interaction=nonstopmode",texPath,nil]
                           atPath:tempDir];

    if ([[NSFileManager defaultManager] fileExistsAtPath:pdfPath])
        [pdf setDocument:[[[PDFDocument alloc] initWithData:[NSData dataWithContentsOfFile:pdfPath]] autorelease]];
    else
        [pdf setDocument:[[[PDFDocument alloc] initWithData:[NSData dataWithContentsOfFile:
                            [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath],@"error.pdf"]]] autorelease]];
    return output;
}

- (id) valueForKey:(NSString *) key
{
    return [[NSUserDefaults standardUserDefaults] valueForKey:key];
}

- (void) setValue:(id) value forKey:(NSString *) key
{
    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
}

- (void) scaleChanged:(id) sender
{
    [self setValue:[NSNumber numberWithFloat:[pdf scaleFactor]] forKey:@"Scale Factor"];
    [self setValue:[NSNumber   numberWithInt:[pdf autoScales]]  forKey:@"Auto Scales"];
    
    [zoom setFloatValue:(1/bFactor * log(10 * [pdf scaleFactor]))];
    [zoomSize setIntValue:(int) (100 * [pdf scaleFactor])];
}

- (void) handlePageChangedNotification:(id) sender
{
    
}

- (NSString *) runTeX:(id) sender
{
    return [self latexWithPreamble:[self valueForKey:@"Latex Preamble"]
                          andTable:[controller texString]];
}

- (void) toggleAutoZoom:(id) sender
{
    [pdf setAutoScales:![pdf autoScales]];
}

-(IBAction) zoom:(id)sender
{
    [pdf setAutoScales:NO];
    
    if ([sender isKindOfClass:[NSTextField class]])
        [pdf setScaleFactor:[sender floatValue]/100];
    else if ([sender isKindOfClass:[NSSlider class]])
        [pdf setScaleFactor:(0.1 * exp (bFactor * [sender floatValue]))];
}

#pragma mark Toolbar Delegate Methods
//=============================================================================================== Toolbar Delegate Methods ===================
- (NSArray *) toolbarAllowedItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects:
            //custom cocoa toolbar items;
            AutoZoomToolbarItemIdentifier,
            ZoomSliderToolbarItemIdentifier,
            ZoomTextToolbarItemIdentifier,
            RunTeXToolbarItemIdentifier,
            //standard cocoa toolbar items;
            NSToolbarFlexibleSpaceItemIdentifier,
            NSToolbarSpaceItemIdentifier,
            NSToolbarSeparatorItemIdentifier, nil];
}
- (NSArray *) toolbarDefaultItemIdentifiers: (NSToolbar *) toolbar {
    return [NSArray arrayWithObjects: 
            NSToolbarFlexibleSpaceItemIdentifier,
            ZoomSliderToolbarItemIdentifier,
            ZoomTextToolbarItemIdentifier,
            AutoZoomToolbarItemIdentifier,
            RunTeXToolbarItemIdentifier,
            NSToolbarFlexibleSpaceItemIdentifier,nil];
}

- (NSToolbarItem *) toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{ 
    NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier: itemIdentifier] autorelease];
    
    // -------------------- Zoom Slider Toolbar Item --------------------
    if ([itemIdentifier isEqual:ZoomSliderToolbarItemIdentifier]) {
        [toolbarItem setLabel:@"Zoom Silder"];
        [toolbarItem setPaletteLabel:@"Zoom Slider"];
        [toolbarItem setToolTip:@"Set the PDF's zooming"];
        [toolbarItem setView:zoomSlideView];
        [toolbarItem setTarget:self];
        [toolbarItem setAction:@selector(zoom:)];
    // --------------------- Auto Zoom Toolbar Item ---------------------
    } else if ([itemIdentifier isEqual:RunTeXToolbarItemIdentifier]) {
        [toolbarItem setLabel:@"Run TeX"];
        [toolbarItem setPaletteLabel:@"Run TeX"];
        [toolbarItem setToolTip:@"Run TeX"];
        [toolbarItem setTarget:self];
        [toolbarItem setImage:[NSImage imageNamed:@"TeX"]];
        [toolbarItem setMinSize:NSMakeSize(24,24)];
        [toolbarItem setMaxSize:NSMakeSize(24,24)];
        [toolbarItem setAction:@selector(runTeX:)];
    // --------------------- Auto Zoom Toolbar Item ---------------------
    } else if ([itemIdentifier isEqual:AutoZoomToolbarItemIdentifier]) {
        [toolbarItem setLabel:@"Auto Zoom"];
        [toolbarItem setPaletteLabel:@"Auto Zoom"];
        [toolbarItem setToolTip:@"Auto Zoom"];
        [toolbarItem setTarget:self];
        [toolbarItem setImage:[NSImage imageNamed:@"NSEnterFullScreenTemplate"]];
        [toolbarItem setMinSize:NSMakeSize(24,24)];
        [toolbarItem setMaxSize:NSMakeSize(24,24)];
        [toolbarItem setAction:@selector(toggleAutoZoom:)];
    // --------------------- Zoom Text Toolbar Item ---------------------
    } else if ([itemIdentifier isEqual:ZoomTextToolbarItemIdentifier]) {
        [toolbarItem setLabel:@"Zoom"];
        [toolbarItem setPaletteLabel:@"Zoom"];
        [toolbarItem setToolTip:@"Zoom Text"];
        [toolbarItem setTarget:self];
        [toolbarItem setView:zoomTextView];
        [toolbarItem setAction:@selector(toggleAutoZoom:)];
    } else
        toolbarItem = nil;
    
    return toolbarItem;
}

- (void) show
{
    [previewWindow makeKeyAndOrderFront:self];
}


// small routine to run a shell command with arguments and return its output
//--------------------------------------------------------------------------------------------------------
- (NSString *) run:(NSString *)pathToCommand withArguments:(NSArray *)arguments atPath:(NSString *)path
{
    NSTask *task;
    NSPipe *pipe = [NSPipe pipe];
    NSFileHandle *file = [pipe fileHandleForReading];
    
    task = [[NSTask alloc] init];
    [task     setLaunchPath:pathToCommand];
    [task      setArguments:arguments];
    [task setStandardOutput:pipe];
    [task  setStandardError:pipe];

    [task setCurrentDirectoryPath:path];
    
    [task launch];

    NSData *dataFromFile = [file readDataToEndOfFile];
    NSString * output = [[[NSString alloc] initWithData:dataFromFile encoding:NSASCIIStringEncoding] autorelease];

    return output;
}   


@end
