//
//  SRRecorderCell.m
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

#import "SRRecorderCell.h"
#import "SRRecorderControl.h"
#import "SRKeyCodeTransformer.h"

@interface SRRecorderCell (Private)
- (void)_privateInit;
- (void)_createGradient;
- (void)_setJustChanged;
- (void)_startRecordingTransition;
- (void)_endRecordingTransition;
- (void)_transitionTick;
- (void)_startRecording;
- (void)_endRecording;

- (BOOL)_effectiveIsAnimating;
- (BOOL)_supportsAnimation;

- (NSString *)_defaultsKeyForAutosaveName:(NSString *)name;
- (void)_saveKeyCombo;
- (void)_loadKeyCombo;

- (NSRect)_removeButtonRectForFrame:(NSRect)cellFrame;
- (NSRect)_snapbackRectForFrame:(NSRect)cellFrame;

- (NSUInteger)_filteredCocoaFlags:(NSUInteger)flags;
- (NSUInteger)_filteredCocoaToCarbonFlags:(NSUInteger)cocoaFlags;
- (BOOL)_validModifierFlags:(NSUInteger)flags;

- (BOOL)_isEmpty;
@end

#pragma mark -

@implementation SRRecorderCell

@synthesize delegate = _delegate;

- (id)init {
    self = [super init];
	
	if (self != nil) {
		[self _privateInit];
	}
	
    return self;
}

- (void)dealloc {
    [validator release];
	
	[keyCharsIgnoringModifiers release];
	[keyChars release];
    
	[recordingGradient release];
	[autosaveName release];
	
	[cancelCharacterSet release];
	
	[super dealloc];
}

#pragma mark *** Coding Support ***

- (id)initWithCoder:(NSCoder *)aDecoder
{
	self = [super initWithCoder: aDecoder];
	
	[self _privateInit];

	if ([aDecoder allowsKeyedCoding]) {
		autosaveName = [[aDecoder decodeObjectForKey: @"autosaveName"] retain];
		
		keyCombo.code = [[aDecoder decodeObjectForKey: @"keyComboCode"] shortValue];
		keyCombo.flags = [[aDecoder decodeObjectForKey: @"keyComboFlags"] unsignedIntegerValue];
		
		if ([aDecoder containsValueForKey:@"keyChars"]) {
			hasKeyChars = YES;
			keyChars = (NSString *)[aDecoder decodeObjectForKey: @"keyChars"];
			keyCharsIgnoringModifiers = (NSString *)[aDecoder decodeObjectForKey: @"keyCharsIgnoringModifiers"];
		}

		allowedFlags = [[aDecoder decodeObjectForKey: @"allowedFlags"] unsignedIntegerValue];
		requiredFlags = [[aDecoder decodeObjectForKey: @"requiredFlags"] unsignedIntegerValue];
		
		allowsKeyOnly = [[aDecoder decodeObjectForKey:@"allowsKeyOnly"] boolValue];
		escapeKeysRecord = [[aDecoder decodeObjectForKey:@"escapeKeysRecord"] boolValue];
		isAnimating = [[aDecoder decodeObjectForKey:@"isAnimating"] boolValue];
		
		style = [[aDecoder decodeObjectForKey:@"style"] shortValue];
	} else {
		autosaveName = [[aDecoder decodeObject] retain];
		
		keyCombo.code = [[aDecoder decodeObject] shortValue];
		keyCombo.flags = [[aDecoder decodeObject] unsignedIntegerValue];
		
		allowedFlags = [[aDecoder decodeObject] unsignedIntegerValue];
		requiredFlags = [[aDecoder decodeObject] unsignedIntegerValue];
	}
	
	allowedFlags |= NSFunctionKeyMask;

	[self _loadKeyCombo];

	return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
	[super encodeWithCoder: aCoder];
	
	if ([aCoder allowsKeyedCoding]) {
		[aCoder encodeObject:[self autosaveName] forKey:@"autosaveName"];
		[aCoder encodeObject:[NSNumber numberWithShort: keyCombo.code] forKey:@"keyComboCode"];
		[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:keyCombo.flags] forKey:@"keyComboFlags"];
	
		[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:allowedFlags] forKey:@"allowedFlags"];
		[aCoder encodeObject:[NSNumber numberWithUnsignedInteger:requiredFlags] forKey:@"requiredFlags"];
		
		if (hasKeyChars) {
			[aCoder encodeObject:keyChars forKey:@"keyChars"];
			[aCoder encodeObject:keyCharsIgnoringModifiers forKey:@"keyCharsIgnoringModifiers"];
		}
		
		[aCoder encodeObject:[NSNumber numberWithBool: allowsKeyOnly] forKey:@"allowsKeyOnly"];
		[aCoder encodeObject:[NSNumber numberWithBool: escapeKeysRecord] forKey:@"escapeKeysRecord"];
		
		[aCoder encodeObject:[NSNumber numberWithBool: isAnimating] forKey:@"isAnimating"];
		[aCoder encodeObject:[NSNumber numberWithShort:style] forKey:@"style"];
	} else {
		// Unkeyed archiving and encoding is deprecated and unsupported. Use keyed archiving and encoding.
		[aCoder encodeObject: [self autosaveName]];
		[aCoder encodeObject: [NSNumber numberWithShort: keyCombo.code]];
		[aCoder encodeObject: [NSNumber numberWithUnsignedInteger: keyCombo.flags]];
		
		[aCoder encodeObject: [NSNumber numberWithUnsignedInteger:allowedFlags]];
		[aCoder encodeObject: [NSNumber numberWithUnsignedInteger:requiredFlags]];
	}
}

- (id)copyWithZone:(NSZone *)zone
{
    SRRecorderCell *cell;
    cell = (SRRecorderCell *)[super copyWithZone: zone];
	
	cell->recordingGradient = [recordingGradient retain];
	cell->autosaveName = [autosaveName retain];

	cell->isRecording = isRecording;
	cell->mouseInsideTrackingArea = mouseInsideTrackingArea;
	cell->mouseDown = mouseDown;

	cell->removeTrackingRectTag = removeTrackingRectTag;
	cell->snapbackTrackingRectTag = snapbackTrackingRectTag;

	cell->keyCombo = keyCombo;

	cell->allowedFlags = allowedFlags;
	cell->requiredFlags = requiredFlags;
	cell->recordingFlags = recordingFlags;
	
	cell->allowsKeyOnly = allowsKeyOnly;
	cell->escapeKeysRecord = escapeKeysRecord;
	
	cell->isAnimating = isAnimating;
	
	cell->style = style;

	cell->cancelCharacterSet = [cancelCharacterSet retain];
    
	cell->_delegate = _delegate;
	
    return cell;
}

#pragma mark *** Drawing ***

+ (BOOL)styleSupportsAnimation:(SRRecorderStyle)style {
	return (style == SRGreyStyle);
}

- (BOOL)animates {
	return isAnimating;
}

- (void)setAnimates:(BOOL)an {
	isAnimating = an;
}

- (SRRecorderStyle)style {
	return style;
}

- (void)setStyle:(SRRecorderStyle)nStyle {
	switch (nStyle) {
		case SRGreyStyle:
			style = SRGreyStyle;
			break;
		case SRGradientBorderStyle:
		default:
			style = SRGradientBorderStyle;
			break;
	}
}

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	[[NSGraphicsContext currentContext] saveGraphicsState];
	
	// Draw button content area
	NSBezierPath* contentPath = [NSBezierPath
								 bezierPathWithSRCRoundRectInRect:cellFrame
								 radius:NSHeight(cellFrame) / 2.0f];
	
	[contentPath addClip];
	
	if(isRecording) {
		NSGradient* fillGradient = [[NSGradient alloc] initWithStartingColor:
									[NSColor colorWithCalibratedRed:(199.0f / 255.0f) green:(242.0f / 255.0f) blue:(255.0f / 255.0f) alpha:1.0f]
																 endingColor:[NSColor colorWithCalibratedRed:(167.0f / 255.0f) green:(210.0f / 255.0f) blue:(255.0f / 255.0f) alpha:1.0f]];
		[fillGradient drawInRect:cellFrame
						   angle:270.0f];
		[fillGradient release];
	} else {
		NSGradient* fillGradient = [[NSGradient alloc] initWithStartingColor:
									[NSColor colorWithCalibratedWhite:(254.0f / 255.0f) alpha:1.0f]
																 endingColor:[NSColor colorWithCalibratedWhite:(218.0f / 255.0f) alpha:1.0f]];
		[fillGradient drawInRect:cellFrame
						   angle:mouseDownInButton ? 90.0f : 270.0f];
		[fillGradient release];
	}
	
	// Draw border and remove badge if needed
	[[NSColor colorWithCalibratedWhite:(167.0f / 255.0f) alpha:1.0f] set];
	[contentPath setLineWidth:2.0f];
	[contentPath stroke];
	
	if(!isRecording && ![self _isEmpty] && [self isEnabled]) {
		[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
		
		NSString* removeImageName = [NSString stringWithFormat:@"RemoveShortcut%@",
									 (mouseInsideTrackingArea ? (mouseDown ? @"Pressed" : @"") : (mouseDown ? @"" : @""))];
		
		NSPoint drawOrigin = [self _removeButtonRectForFrame:cellFrame].origin;
		//		drawOrigin.x -= 1.0;
		//		drawOrigin.y -= 1.0;
		
		[DGImage(removeImageName) dissolveToPoint:drawOrigin fraction:1.0f];
	}
	
	// Draw gradient when in recording mode
	if(isRecording) {
		// Draw snapback image
		NSImage* snapBackArrow = DGImage(@"Snapback");
		
		NSPoint drawOrigin = [self _snapbackRectForFrame:cellFrame].origin;
		drawOrigin.x -= 1.0f;
		drawOrigin.y -= 1.0f;
		
		[snapBackArrow dissolveToPoint:drawOrigin fraction:1.0f];
	}
	
	[[NSGraphicsContext currentContext] restoreGraphicsState];
	
	// Draw text
	NSMutableParagraphStyle* paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	
	[paragraphStyle setLineBreakMode:NSLineBreakByTruncatingTail];
	[paragraphStyle setAlignment:NSCenterTextAlignment];
	
	// Only the KeyCombo should be black and in a bigger font size
	BOOL recordingOrEmpty = (isRecording || [self _isEmpty]);
	
	NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
	
	[attributes setObject:paragraphStyle forKey:NSParagraphStyleAttributeName];
	[attributes setObject:[NSFont systemFontOfSize:[NSFont smallSystemFontSize]]
				   forKey:NSFontAttributeName];
	[attributes setObject:[NSColor blackColor]
				   forKey:NSForegroundColorAttributeName];
	
	if([self _isEmpty] && !isRecording) {
		[attributes setObject:[[NSColor blackColor] highlightWithLevel:0.25f]
					   forKey:NSForegroundColorAttributeName];
	}
	
	if(recordingOrEmpty) {
		[attributes setObject:[NSFont systemFontOfSize:[NSFont labelFontSize]]
					   forKey:NSFontAttributeName];
	}
	
	if(!isRecording) {
		NSShadow* textShadow = [[[NSShadow alloc] init] autorelease];
		
		[textShadow setShadowOffset:
		 NSMakeSize(0.0f, -1.0f)];
		[textShadow setShadowBlurRadius:0.0f];
		[textShadow setShadowColor:
		 [NSColor whiteColor]];
		
		[attributes setObject:textShadow
					   forKey:NSShadowAttributeName];
	}
	
	NSString *displayString;
	
	if (isRecording)
	{
		// Recording, but no modifier keys down
		if (![self _validModifierFlags: recordingFlags])
		{
			if (mouseInsideTrackingArea)
			{
				// Mouse over snapback
				displayString = SRLoc(@"Use old shortcut");
			}
			else
			{
				// Mouse elsewhere
				displayString = SRLoc(@"Type shortcut");
			}
		}
		else
		{
			// Display currently pressed modifier keys
			displayString = SRStringForCocoaModifierFlags(recordingFlags);
			
			if([displayString length] == 0) {
				displayString = SRLoc(@"Type shortcut");
			}
		}
	}
	else
	{
		// Not recording...
		if ([self _isEmpty])
		{
			displayString = SRLoc(@"Click to record shortcut");
		}
		else
		{
			// Display current key combination
			displayString = [self keyComboString];
		}
	}
	
	// Calculate rect in which to draw the text in...
	NSRect textRect = cellFrame;
	//	textRect.size.width -= 6;
	//	textRect.size.width -= ((!isRecording && [self _isEmpty]) ? 6 : (isRecording ? [self _snapbackRectForFrame: cellFrame].size.width : [self _removeButtonRectForFrame: cellFrame].size.width) + 6);
	//	textRect.origin.x += 6;
	textRect.origin.y = -(NSMidY(cellFrame) - [displayString sizeWithAttributes:attributes].height/2.0f);
	
	// TODO cosmetic tweak
	
	if(recordingOrEmpty) {
		textRect.origin.y -= 1;
	}
	
	// Finally draw it
	[displayString drawInRect:textRect withAttributes:attributes];
}

#pragma mark *** Mouse Tracking ***

- (void)resetTrackingRects
{	
	SRRecorderControl *controlView = (SRRecorderControl *)[self controlView];
	NSRect cellFrame = [controlView bounds];
	NSPoint mouseLocation = [controlView convertPoint:[[NSApp currentEvent] locationInWindow] fromView:nil];

	// We're not to be tracked if we're not enabled
	if (![self isEnabled])
	{
		if (removeTrackingRectTag != 0) [controlView removeTrackingRect: removeTrackingRectTag];
		if (snapbackTrackingRectTag != 0) [controlView removeTrackingRect: snapbackTrackingRectTag];
		
		return;
	}
	
	// We're either in recording or normal display mode
	if (!isRecording)
	{
		// Create and register tracking rect for the remove badge if shortcut is not empty
		NSRect removeButtonRect = [self _removeButtonRectForFrame: cellFrame];
		BOOL mouseInside = [controlView mouse:mouseLocation inRect:removeButtonRect];
		
		if (removeTrackingRectTag != 0) [controlView removeTrackingRect: removeTrackingRectTag];
		removeTrackingRectTag = [controlView addTrackingRect:removeButtonRect owner:self userData:nil assumeInside:mouseInside];
		
		if (mouseInsideTrackingArea != mouseInside) mouseInsideTrackingArea = mouseInside;
	}
	else
	{
		// Create and register tracking rect for the snapback badge if we're in recording mode
		NSRect snapbackRect = [self _snapbackRectForFrame: cellFrame];
		BOOL mouseInside = [controlView mouse:mouseLocation inRect:snapbackRect];

		if (snapbackTrackingRectTag != 0) [controlView removeTrackingRect: snapbackTrackingRectTag];
		snapbackTrackingRectTag = [controlView addTrackingRect:snapbackRect owner:self userData:nil assumeInside:mouseInside];	
		
		if (mouseInsideTrackingArea != mouseInside) mouseInsideTrackingArea = mouseInside;
	}
}

- (void)mouseEntered:(NSEvent *)theEvent
{
	NSView *view = [self controlView];

	if ([[view window] isKeyWindow] || [view acceptsFirstMouse: theEvent])
	{
		mouseInsideTrackingArea = YES;
		[view display];
	}
}

- (void)mouseExited:(NSEvent*)theEvent
{
	NSView *view = [self controlView];
	
	if ([[view window] isKeyWindow] || [view acceptsFirstMouse: theEvent])
	{
		mouseInsideTrackingArea = NO;
		[view display];
	}
}

- (BOOL)trackMouse:(NSEvent *)theEvent inRect:(NSRect)cellFrame ofView:(SRRecorderControl *)controlView untilMouseUp:(BOOL)flag
{		
	NSEvent *currentEvent = theEvent;
	NSPoint mouseLocation;
	
	NSRect trackingRect = (isRecording ? [self _snapbackRectForFrame: cellFrame] : [self _removeButtonRectForFrame: cellFrame]);
	NSRect leftRect = cellFrame;

	// Determine the area without any badge
	if (!NSEqualRects(trackingRect,NSZeroRect)) leftRect.size.width -= NSWidth(trackingRect) + 4;
		
	do {
        mouseLocation = [controlView convertPoint: [currentEvent locationInWindow] fromView:nil];
		
		switch ([currentEvent type])
		{
			case NSLeftMouseDown:
			{
				// Check if mouse is over remove/snapback image
				if ([controlView mouse:mouseLocation inRect:trackingRect])
				{
					mouseDown = YES;
					[controlView setNeedsDisplayInRect: cellFrame];
				} else {
					mouseDownInButton = YES;
				}
				
				break;
			}
			case NSLeftMouseDragged:
			{				
				// Recheck if mouse is still over the image while dragging 
				mouseInsideTrackingArea = [controlView mouse:mouseLocation inRect:trackingRect];
				[controlView setNeedsDisplayInRect: cellFrame];
				
				mouseDownInButton = !mouseInsideTrackingArea && [controlView mouse:mouseLocation inRect:cellFrame];
				
				break;
			}
			default: // NSLeftMouseUp
			{
				mouseDownInButton = mouseDown = NO;
				mouseInsideTrackingArea = [controlView mouse:mouseLocation inRect:trackingRect];

				if (mouseInsideTrackingArea)
				{
					if (isRecording)
					{
						// Mouse was over snapback, just redraw
                        [self _endRecordingTransition];
					}
					else
					{
						// Mouse was over the remove image, reset all
						[self setKeyCombo: SRMakeKeyCombo(ShortcutRecorderEmptyCode, ShortcutRecorderEmptyFlags)];
					}
				}
				else if ([controlView mouse:mouseLocation inRect:leftRect] && !isRecording)
				{
					if ([self isEnabled]) 
					{
                        [self _startRecordingTransition];
					}
					/* maybe beep if not editable?
					 else
					{
						NSBeep();
					}
					 */
				}
				
				// Any click inside will make us firstResponder
				if ([self isEnabled]) [[controlView window] makeFirstResponder: controlView];

				// Reset tracking rects and redisplay
				[self resetTrackingRects];
				[controlView setNeedsDisplayInRect: cellFrame];
				
				return YES;
			}
		}
		
    } while ((currentEvent = [[controlView window] nextEventMatchingMask:(NSLeftMouseDraggedMask | NSLeftMouseUpMask) untilDate:[NSDate distantFuture] inMode:NSEventTrackingRunLoopMode dequeue:YES]));
	
    return YES;
}

#pragma mark *** Responder Control ***

- (BOOL) becomeFirstResponder
{
    // reset tracking rects and redisplay
    [self resetTrackingRects];
    [[self controlView] display];
    
    return YES;
}

- (BOOL)resignFirstResponder
{
	if (isRecording) {
		[self _endRecordingTransition];
	}
    
    [self resetTrackingRects];
    [[self controlView] display];
    return YES;
}

#pragma mark *** Key Combination Control ***

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent
{	
	NSUInteger flags = [self _filteredCocoaFlags: [theEvent modifierFlags]];
	NSNumber *keyCodeNumber = [NSNumber numberWithUnsignedShort: [theEvent keyCode]];
	BOOL snapback = [cancelCharacterSet containsObject: keyCodeNumber];
	BOOL validModifiers = [self _validModifierFlags: (snapback) ? [theEvent modifierFlags] : flags]; // Snapback key shouldn't interfer with required flags!
    
    // Special case for the space key when we aren't recording...
    if (!isRecording && [[theEvent characters] isEqualToString:@" "]) {
        [self _startRecordingTransition];
        return YES;
    }
	
	// Do something as long as we're in recording mode and a modifier key or cancel key is pressed
	if (isRecording && (validModifiers || snapback)) {
		if (!snapback || validModifiers) {
			BOOL goAhead = YES;
			
			// Special case: if a snapback key has been entered AND modifiers are deemed valid...
			if (snapback && validModifiers) {
				// ...AND we're set to allow plain keys
				if (allowsKeyOnly) {
					// ...AND modifiers are empty, or empty save for the Function key
					// (needed, since forward delete is fn+delete on laptops)
					if (flags == ShortcutRecorderEmptyFlags || flags == (ShortcutRecorderEmptyFlags | NSFunctionKeyMask)) {
						// ...check for behavior in escapeKeysRecord.
						if (!escapeKeysRecord) {
							goAhead = NO;
						}
					}
				}
			}
			
			if (goAhead) {
				
				NSString *character = [[theEvent charactersIgnoringModifiers] uppercaseString];
				
			// accents like "¬¥" or "`" will be ignored since we don't get a keycode
				if ([character length]) {
					NSError *error = nil;
					
				// Check if key combination is already used or not allowed by the delegate
					if (![validator canUseKeyCode:[theEvent keyCode] 
										withFlags:[self _filteredCocoaToCarbonFlags:flags]
											error:&error] ) {
                    // display the error...
						NSAlert *alert = [NSAlert alertWithNonRecoverableError:error];
						[alert setAlertStyle:NSCriticalAlertStyle];
						[alert runModal];
						
					// Recheck pressed modifier keys
						[self flagsChanged:[NSApp currentEvent]];
						
						return YES;
					} else {
					// All ok, set new combination
						keyCombo.flags = flags;
						keyCombo.code = [theEvent keyCode];
						
						hasKeyChars = YES;
						keyChars = [[theEvent characters] retain];
						keyCharsIgnoringModifiers = [[theEvent charactersIgnoringModifiers] retain];
//						NSLog(@"keychars: %@, ignoringmods: %@", keyChars, keyCharsIgnoringModifiers);
//						NSLog(@"calculated keychars: %@, ignoring: %@", SRStringForKeyCode(keyCombo.code), SRCharacterForKeyCodeAndCocoaFlags(keyCombo.code,keyCombo.flags));
						
					// Notify delegate
						if ([self delegate] != nil)
							[[self delegate] shortcutRecorderCell:self keyComboDidChange:keyCombo];
						
					// Save if needed
						[self _saveKeyCombo];
						
						[self _setJustChanged];
					}
				} else {
				// invalid character
					NSBeep();
				}
			}
		}
		
		// reset values and redisplay
		recordingFlags = ShortcutRecorderEmptyFlags;
        
        [self _endRecordingTransition];
		
		[self resetTrackingRects];
		[[self controlView] display];
		
		return YES;
	} else {
		//Start recording when the spacebar is pressed while the control is first responder
		if (([[[self controlView] window] firstResponder] == [self controlView]) &&
			([[theEvent characters] length] && [[theEvent characters] characterAtIndex:0] == 32) &&
			([self isEnabled]))
		{
			[self _startRecordingTransition];
		}
	}
	
	return NO;
}

- (void)flagsChanged:(NSEvent *)theEvent
{
	if (isRecording)
	{
		recordingFlags = [self _filteredCocoaFlags: [theEvent modifierFlags]];
		[[self controlView] display];
	}
}

#pragma mark -

- (NSUInteger)allowedFlags
{
	return allowedFlags;
}

- (void)setAllowedFlags:(NSUInteger)flags
{
	allowedFlags = flags;
	
	// filter new flags and change keycombo if not recording
	if (isRecording)
	{
		recordingFlags = [self _filteredCocoaFlags: [[NSApp currentEvent] modifierFlags]];;
	}
	else
	{
		NSUInteger originalFlags = keyCombo.flags;
		keyCombo.flags = [self _filteredCocoaFlags: keyCombo.flags];
		
		if (keyCombo.flags != originalFlags && keyCombo.code > ShortcutRecorderEmptyCode)
		{
			// Notify delegate if keyCombo changed
			if ([self delegate] != nil)
				[[self delegate] shortcutRecorderCell:self keyComboDidChange:keyCombo];
			
			// Save if needed
			[self _saveKeyCombo];
		}
	}
	
	[[self controlView] display];
}

- (BOOL)allowsKeyOnly {
	return allowsKeyOnly;
}

- (BOOL)escapeKeysRecord {
	return escapeKeysRecord;
}

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord {
	allowsKeyOnly = nAllowsKeyOnly;
	escapeKeysRecord = nEscapeKeysRecord;
}

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly {
	allowsKeyOnly = nAllowsKeyOnly;
}

- (void)setEscapeKeysRecord:(BOOL)nEscapeKeysRecord {
	escapeKeysRecord = nEscapeKeysRecord;
}


- (NSUInteger)requiredFlags
{
	return requiredFlags;
}

- (void)setRequiredFlags:(NSUInteger)flags
{
	requiredFlags = flags;
	
	// filter new flags and change keycombo if not recording
	if (isRecording)
	{
		recordingFlags = [self _filteredCocoaFlags: [[NSApp currentEvent] modifierFlags]];
	}
	else
	{
		NSUInteger originalFlags = keyCombo.flags;
		keyCombo.flags = [self _filteredCocoaFlags: keyCombo.flags];
		
		if (keyCombo.flags != originalFlags && keyCombo.code > ShortcutRecorderEmptyCode)
		{
			// Notify delegate if keyCombo changed
			if ([self delegate] != nil)
				[[self delegate] shortcutRecorderCell:self keyComboDidChange:keyCombo];
			
			// Save if needed
			[self _saveKeyCombo];
		}
	}
	
	[[self controlView] setNeedsDisplay:YES];
}

- (KeyCombo)keyCombo
{
	return keyCombo;
}

- (void)setKeyCombo:(KeyCombo)aKeyCombo
{
	keyCombo = aKeyCombo;
	keyCombo.flags = [self _filteredCocoaFlags: aKeyCombo.flags];
	
	hasKeyChars = NO;

	// Notify delegate
	if ([self delegate] != nil)
		[[self delegate] shortcutRecorderCell:self keyComboDidChange:keyCombo];
	
	// Save if needed
	[self _saveKeyCombo];
	
	[[self controlView] setNeedsDisplay:YES];
}

- (BOOL)canCaptureGlobalHotKeys
{
	return globalHotKeys;
}

- (void)setCanCaptureGlobalHotKeys:(BOOL)inState
{
	globalHotKeys = inState;
}

#pragma mark *** Autosave Control ***

- (NSString *)autosaveName
{
	return autosaveName;
}

- (void)setAutosaveName:(NSString *)aName
{
	if (aName != autosaveName)
	{
		[autosaveName release];
		autosaveName = [aName copy];
	}
    
    // if the auto save name is != nil, try to load the key combo
    // this makes it possible to use the control even when it's
    // added programatically in a non IB environment
    if (autosaveName != nil) {
        [self _loadKeyCombo];
    }
}

#pragma mark -

- (NSString *)keyComboString
{
	if ([self _isEmpty]) return nil;
	
	return [NSString stringWithFormat: @"%@%@",
        SRStringForCocoaModifierFlags( keyCombo.flags ),
        SRStringForKeyCode( keyCombo.code )];
}

- (NSString *)keyChars {
	if (!hasKeyChars) return SRStringForKeyCode(keyCombo.code);
	return keyChars;
}

- (NSString *)keyCharsIgnoringModifiers {
	if (!hasKeyChars) return SRCharacterForKeyCodeAndCocoaFlags(keyCombo.code,keyCombo.flags);
	return keyCharsIgnoringModifiers;
}

#pragma mark *** Delegate pass-through ***

- (BOOL)shortcutValidator:(SRValidator *)validator canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags reason:(NSString **)aReason {
    if ([self delegate] != nil) {
        return [[self delegate] shortcutRecorderCell:self canUseKeyCode:keyCode withFlags:flags reason:aReason];
    }
    return YES;
}

@end

#pragma mark -

@implementation SRRecorderCell (Private)

- (void)_privateInit {
	mouseDownInButton = NO;
    // init the validator object...
    validator = [[SRValidator alloc] initWithDelegate:self];
    
	// Allow all modifier keys by default, nothing is required
	allowedFlags = ShortcutRecorderAllFlags;
	requiredFlags = ShortcutRecorderEmptyFlags;
	recordingFlags = ShortcutRecorderEmptyFlags;
	
	// Create clean KeyCombo
	keyCombo.flags = ShortcutRecorderEmptyFlags;
	keyCombo.code = ShortcutRecorderEmptyCode;
	
	keyChars = nil;
	keyCharsIgnoringModifiers = nil;
	hasKeyChars = NO;
	
	// These keys will cancel the recoding mode if not pressed with any modifier
	cancelCharacterSet = [[NSSet alloc] initWithObjects: [NSNumber numberWithInteger:ShortcutRecorderEscapeKey], 
		[NSNumber numberWithInteger:ShortcutRecorderBackspaceKey], [NSNumber numberWithInteger:ShortcutRecorderDeleteKey], nil];
		
	NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
	[notificationCenter addObserver:self selector:@selector(_createGradient) name:NSSystemColorsDidChangeNotification object:nil]; // recreate gradient if needed
	[self _createGradient];

	[self _loadKeyCombo];
}

- (void)_createGradient
{
	NSColor *gradientStartColor = [[[NSColor alternateSelectedControlColor] shadowWithLevel: 0.2f] colorWithAlphaComponent: 0.9f];
	NSColor *gradientEndColor = [[[NSColor alternateSelectedControlColor] highlightWithLevel: 0.2f] colorWithAlphaComponent: 0.9f];
	
	recordingGradient = [[NSGradient alloc] initWithStartingColor:gradientStartColor endingColor:gradientEndColor];
}

- (void)_setJustChanged {
	comboJustChanged = YES;
}

- (BOOL)_effectiveIsAnimating {
	return (isAnimating && [self _supportsAnimation]);
}

- (BOOL)_supportsAnimation {
	return [[self class] styleSupportsAnimation:style];
}

- (void)_startRecordingTransition {
	if ([self _effectiveIsAnimating]) {
		isAnimatingTowardsRecording = YES;
		isAnimatingNow = YES;
		transitionProgress = 0.0f;
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_transitionTick) object:nil];
		[self performSelector:@selector(_transitionTick) withObject:nil afterDelay:(SRTransitionDuration/SRTransitionFrames)];
//	NSLog(@"start recording-transition");
	} else {
		[self _startRecording];
	}
}

- (void)_endRecordingTransition {
	if ([self _effectiveIsAnimating]) {
		isAnimatingTowardsRecording = NO;
		isAnimatingNow = YES;
		transitionProgress = 0.0f;
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_transitionTick) object:nil];
		[self performSelector:@selector(_transitionTick) withObject:nil afterDelay:(SRTransitionDuration/SRTransitionFrames)];
//	NSLog(@"end recording-transition");
	} else {
		[self _endRecording];
	}
}

- (void)_transitionTick {
	transitionProgress += (1.0f/SRTransitionFrames);
//	NSLog(@"transition tick: %f", transitionProgress);
	if (transitionProgress >= 0.998f) {
//		NSLog(@"transition deemed complete");
		isAnimatingNow = NO;
		transitionProgress = 0.0f;
		if (isAnimatingTowardsRecording) {
			[self _startRecording];
		} else {
			[self _endRecording];
		}
	} else {
//		NSLog(@"more to do");
		[[self controlView] setNeedsDisplay:YES];
		[[self class] cancelPreviousPerformRequestsWithTarget:self selector:@selector(_transitionTick) object:nil];
		[self performSelector:@selector(_transitionTick) withObject:nil afterDelay:(SRTransitionDuration/SRTransitionFrames)];
	}
}

- (void)_startRecording
{
    // Jump into recording mode if mouse was inside the control but not over any image
    isRecording = YES;
    
    // Reset recording flags and determine which are required
    recordingFlags = [self _filteredCocoaFlags: ShortcutRecorderEmptyFlags];
    
/*	[self setFocusRingType:NSFocusRingTypeNone];
	[[self controlView] setFocusRingType:NSFocusRingTypeNone];*/	
	[[self controlView] setNeedsDisplay:YES];
	
    // invalidate the focus ring rect...
    NSView *controlView = [self controlView];
    [controlView setKeyboardFocusRingNeedsDisplayInRect:[controlView bounds]];

    if (globalHotKeys) hotKeyModeToken = PushSymbolicHotKeyMode(kHIHotKeyModeAllDisabled);
}

- (void)_endRecording
{
    isRecording = NO;
	comboJustChanged = NO;

/*	[self setFocusRingType:NSFocusRingTypeNone];
	[[self controlView] setFocusRingType:NSFocusRingTypeNone];*/	
	[[self controlView] setNeedsDisplay:YES];
	
    // invalidate the focus ring rect...
    NSView *controlView = [self controlView];
    [controlView setKeyboardFocusRingNeedsDisplayInRect:[controlView bounds]];
	
	if (globalHotKeys) PopSymbolicHotKeyMode(hotKeyModeToken);
}

#pragma mark *** Autosave ***

- (NSString *)_defaultsKeyForAutosaveName:(NSString *)name
{
	return [NSString stringWithFormat: @"ShortcutRecorder %@", name];
}

- (void)_saveKeyCombo
{
	NSString *defaultsKey = [self autosaveName];

	if (defaultsKey != nil && [defaultsKey length])
	{
		id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
		
		NSDictionary *defaultsValue = [NSDictionary dictionaryWithObjectsAndKeys:
			[NSNumber numberWithShort: keyCombo.code], @"keyCode",
			[NSNumber numberWithUnsignedInteger: keyCombo.flags], @"modifierFlags", // cocoa
			[NSNumber numberWithUnsignedInteger:SRCocoaToCarbonFlags(keyCombo.flags)], @"modifiers", // carbon, for compatibility with PTKeyCombo
			nil];
		
		if (hasKeyChars) {
			
			NSMutableDictionary *mutableDefaultsValue = [[defaultsValue mutableCopy] autorelease];
			[mutableDefaultsValue setObject:keyChars forKey:@"keyChars"];
			[mutableDefaultsValue setObject:keyCharsIgnoringModifiers forKey:@"keyCharsIgnoringModifiers"];
			
			defaultsValue = mutableDefaultsValue;
		}
		
		[values setValue:defaultsValue forKey:[self _defaultsKeyForAutosaveName: defaultsKey]];
	}
}

- (void)_loadKeyCombo
{
	NSString *defaultsKey = [self autosaveName];

	if (defaultsKey != nil && [defaultsKey length])
	{
		id values = [[NSUserDefaultsController sharedUserDefaultsController] values];
		NSDictionary *savedCombo = [values valueForKey: [self _defaultsKeyForAutosaveName: defaultsKey]];
		
		NSInteger keyCode = [[savedCombo valueForKey: @"keyCode"] shortValue];
		NSUInteger flags;
		if ((nil == [savedCombo valueForKey:@"modifierFlags"]) && (nil != [savedCombo valueForKey:@"modifiers"])) { // carbon, for compatibility with PTKeyCombo
			flags = SRCarbonToCocoaFlags([[savedCombo valueForKey: @"modifiers"] unsignedIntegerValue]);
		} else { // cocoa
			flags = [[savedCombo valueForKey: @"modifierFlags"] unsignedIntegerValue];
		}
		
		keyCombo.flags = [self _filteredCocoaFlags:flags];
		keyCombo.code = keyCode;
		
		NSString *kc = [savedCombo valueForKey: @"keyChars"];
		hasKeyChars = (nil != kc);
		if (kc) {
			keyCharsIgnoringModifiers = [[savedCombo valueForKey: @"keyCharsIgnoringModifiers"] retain];
			keyChars = [kc retain];
		}
		
		// Notify delegate
		if ([self delegate] != nil)
			[[self delegate] shortcutRecorderCell:self keyComboDidChange:keyCombo];
		
		[[self controlView] display];
	}
}

#pragma mark *** Drawing Helpers ***

- (NSRect)_removeButtonRectForFrame:(NSRect)cellFrame
{	
	if ([self _isEmpty] || ![self isEnabled]) return NSZeroRect;
	
	NSRect removeButtonRect;
	NSImage *removeImage = SRResIndImage(@"SRRemoveShortcut");
	
	removeButtonRect.origin = NSMakePoint(NSMaxX(cellFrame) - [removeImage size].width - 4, (NSMaxY(cellFrame) - [removeImage size].height)/2);
	removeButtonRect.size = [removeImage size];

	return removeButtonRect;
}

- (NSRect)_snapbackRectForFrame:(NSRect)cellFrame
{	
//	if (!isRecording) return NSZeroRect;

	NSRect snapbackRect;
	NSImage *snapbackImage = SRResIndImage(@"SRSnapback");
	
	snapbackRect.origin = NSMakePoint(NSMaxX(cellFrame) - [snapbackImage size].width - 2, (NSMaxY(cellFrame) - [snapbackImage size].height)/2 + 1);
	snapbackRect.size = [snapbackImage size];

	return snapbackRect;
}

#pragma mark *** Filters ***

- (NSUInteger)_filteredCocoaFlags:(NSUInteger)flags
{
	NSUInteger filteredFlags = ShortcutRecorderEmptyFlags;
	NSUInteger a = allowedFlags;
	NSUInteger m = requiredFlags;

	if (m & NSCommandKeyMask) filteredFlags |= NSCommandKeyMask;
	else if ((flags & NSCommandKeyMask) && (a & NSCommandKeyMask)) filteredFlags |= NSCommandKeyMask;
	
	if (m & NSAlternateKeyMask) filteredFlags |= NSAlternateKeyMask;
	else if ((flags & NSAlternateKeyMask) && (a & NSAlternateKeyMask)) filteredFlags |= NSAlternateKeyMask;
	
	if ((m & NSControlKeyMask)) filteredFlags |= NSControlKeyMask;
	else if ((flags & NSControlKeyMask) && (a & NSControlKeyMask)) filteredFlags |= NSControlKeyMask;
	
	if ((m & NSShiftKeyMask)) filteredFlags |= NSShiftKeyMask;
	else if ((flags & NSShiftKeyMask) && (a & NSShiftKeyMask)) filteredFlags |= NSShiftKeyMask;
	
	if ((m & NSFunctionKeyMask)) filteredFlags |= NSFunctionKeyMask;
	else if ((flags & NSFunctionKeyMask) && (a & NSFunctionKeyMask)) filteredFlags |= NSFunctionKeyMask;
	
	return filteredFlags;
}

- (BOOL)_validModifierFlags:(NSUInteger)flags
{
	return (allowsKeyOnly ? YES : (((flags & NSCommandKeyMask) || (flags & NSAlternateKeyMask) || (flags & NSControlKeyMask) || (flags & NSShiftKeyMask) || (flags & NSFunctionKeyMask)) ? YES : NO));	
}

#pragma mark -

- (NSUInteger)_filteredCocoaToCarbonFlags:(NSUInteger)cocoaFlags
{
	NSUInteger carbonFlags = ShortcutRecorderEmptyFlags;
	NSUInteger filteredFlags = [self _filteredCocoaFlags: cocoaFlags];
	
	if (filteredFlags & NSCommandKeyMask) carbonFlags |= cmdKey;
	if (filteredFlags & NSAlternateKeyMask) carbonFlags |= optionKey;
	if (filteredFlags & NSControlKeyMask) carbonFlags |= controlKey;
	if (filteredFlags & NSShiftKeyMask) carbonFlags |= shiftKey;
	
	// I couldn't find out the equivalent constant in Carbon, but apparently it must use the same one as Cocoa. -AK
	if (filteredFlags & NSFunctionKeyMask) carbonFlags |= NSFunctionKeyMask;
	
	return carbonFlags;
}

#pragma mark *** Internal Check ***

- (BOOL)_isEmpty
{
	return ( ![self _validModifierFlags: keyCombo.flags] || !SRStringForKeyCode( keyCombo.code ) );
}

@end
