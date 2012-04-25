//
//  SRRecorderControl.m
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

#import "SRRecorderControl.h"
#import "SRCommon.h"

#define SRCell (SRRecorderCell *)[self cell]

@interface SRRecorderControl (Private)
- (void)resetTrackingRects;
@end

@implementation SRRecorderControl

@synthesize delegate = _delegate;

+ (Class)cellClass {
    return [SRRecorderCell class];
}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	
	if (self != nil) {
		[SRCell setDelegate:self];
	}
	
	return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
	self = [super initWithCoder:aDecoder];
	
	if (self != nil) {
		[SRCell setDelegate:self];
	}
	
	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}

#pragma mark *** Cell Behavior ***

// We need keyboard access
- (BOOL)acceptsFirstResponder
{
    return YES;
}

// Allow the control to be activated with the first click on it even if it's window isn't the key window
- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
	return YES;
}

- (BOOL) becomeFirstResponder 
{
    BOOL okToChange = [SRCell becomeFirstResponder];
    if (okToChange) [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    return okToChange;
}

- (BOOL) resignFirstResponder 
{
    BOOL okToChange = [SRCell resignFirstResponder];
    if (okToChange) [super setKeyboardFocusRingNeedsDisplayInRect:[self bounds]];
    return okToChange;
}

#pragma mark *** Aesthetics ***
- (BOOL)animates {
	return [SRCell animates];
}

- (void)setAnimates:(BOOL)an {
	[SRCell setAnimates:an];
}

- (SRRecorderStyle)style {
	return [SRCell style];
}

- (void)setStyle:(SRRecorderStyle)nStyle {
	[SRCell setStyle:nStyle];
}

#pragma mark *** Interface Stuff ***


// If the control is set to be resizeable in width, this will make sure that the tracking rects are always updated
- (void)viewDidMoveToWindow
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    
    [center removeObserver: self];
	[center addObserver:self selector:@selector(viewFrameDidChange:) name:NSViewFrameDidChangeNotification object:self];
	
	[self resetTrackingRects];
}

- (void)viewFrameDidChange:(NSNotification *)aNotification
{
	[self resetTrackingRects];
}

// Prevent from being too small
- (void)setFrameSize:(NSSize)newSize
{
	NSSize correctedSize = newSize;
	correctedSize.height = SRMaxHeight;
	if (correctedSize.width < SRMinWidth) correctedSize.width = SRMinWidth;
	
	[super setFrameSize: correctedSize];
}

- (void)setFrame:(NSRect)frameRect
{
	NSRect correctedFrarme = frameRect;
	correctedFrarme.size.height = SRMaxHeight;
	if (correctedFrarme.size.width < SRMinWidth) correctedFrarme.size.width = SRMinWidth;

	[super setFrame: correctedFrarme];
}

- (NSString *)keyChars {
	return [SRCell keyChars];
}

- (NSString *)keyCharsIgnoringModifiers {
	return [SRCell keyCharsIgnoringModifiers];	
}

#pragma mark *** Key Interception ***

// Like most NSControls, pass things on to the cell
- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{
	// Only if we're key, please. Otherwise hitting Space after having
	// tabbed past SRRecorderControl will put you into recording mode.
	if (([[[self window] firstResponder] isEqual:self])) { 
		if ([SRCell performKeyEquivalent:theEvent]) return YES;
	}

	return [super performKeyEquivalent: theEvent];
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	[SRCell flagsChanged:theEvent];
}

- (void)keyDown:(NSEvent *)theEvent
{
	if ( [SRCell performKeyEquivalent: theEvent] )
        return;
    
    [super keyDown:theEvent];
}

#pragma mark *** Key Combination Control ***

- (NSUInteger)allowedFlags
{
	return [SRCell allowedFlags];
}

- (void)setAllowedFlags:(NSUInteger)flags
{
	[SRCell setAllowedFlags: flags];
}

- (BOOL)allowsKeyOnly {
	return [SRCell allowsKeyOnly];
}

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord {
	[SRCell setAllowsKeyOnly:nAllowsKeyOnly escapeKeysRecord:nEscapeKeysRecord];
}

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly {
	[SRCell setAllowsKeyOnly:nAllowsKeyOnly];
}

- (void)setEscapeKeysRecord:(BOOL)nEscapeKeysRecord {
	[SRCell setEscapeKeysRecord:nEscapeKeysRecord];
}


- (BOOL)escapeKeysRecord {
	return [SRCell escapeKeysRecord];
}

- (BOOL)canCaptureGlobalHotKeys
{
	return [[self cell] canCaptureGlobalHotKeys];
}

- (void)setCanCaptureGlobalHotKeys:(BOOL)inState
{
	[[self cell] setCanCaptureGlobalHotKeys:inState];
}

- (NSUInteger)requiredFlags
{
	return [SRCell requiredFlags];
}

- (void)setRequiredFlags:(NSUInteger)flags
{
	[SRCell setRequiredFlags: flags];
}

- (KeyCombo)keyCombo
{
	return [SRCell keyCombo];
}

- (void)setKeyCombo:(KeyCombo)aKeyCombo
{
	[SRCell setKeyCombo: aKeyCombo];
}

#pragma mark *** Autosave Control ***

- (NSString *)autosaveName
{
	return [SRCell autosaveName];
}

- (void)setAutosaveName:(NSString *)aName
{
	[SRCell setAutosaveName: aName];
}

#pragma mark -

- (NSString *)keyComboString
{
	return [SRCell keyComboString];
}

#pragma mark *** Conversion Methods ***

- (NSUInteger)cocoaToCarbonFlags:(NSUInteger)cocoaFlags
{
	return SRCocoaToCarbonFlags( cocoaFlags );
}

- (NSUInteger)carbonToCocoaFlags:(NSUInteger)carbonFlags
{
	return SRCarbonToCocoaFlags( carbonFlags );
}

#pragma mark *** Delegate pass-through ***

- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags reason:(NSString **)aReason {
	if ([self delegate] != nil && [[self delegate] respondsToSelector:@selector(shortcutRecorder:canUseKeyCode:withFlags:reason:)]) {
		return [[self delegate] shortcutRecorder:self canUseKeyCode:keyCode withFlags:flags reason:aReason];
	} else {
		return YES;
	}
}

- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(KeyCombo)newKeyCombo {
	if ([self delegate] != nil && [[self delegate] respondsToSelector:@selector(shortcutRecorder:keyComboDidChange:)])
		[[self delegate] shortcutRecorder:self keyComboDidChange:newKeyCombo];
}

@end

@implementation SRRecorderControl (Private)

- (void)resetTrackingRects {
	[SRCell resetTrackingRects];
}

@end
