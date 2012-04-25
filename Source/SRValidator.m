//
//  SRValidator.h
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

#import "SRValidator.h"
#import "SRCommon.h"

static NSString * const SRBundleIdentifier = @"net.wafflesoftware.ShortcutRecorder.framework.Leopard";

@implementation SRValidator

@synthesize delegate = _delegate;

- (id)initWithDelegate:(id<SRValidatorDelegate>)delegate {
    self = [super init];
    if ( !self )
        return nil;
    
    _delegate = delegate;
    
    return self;
}

//---------------------------------------------------------- 
- (BOOL)canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags error:(NSError **)errorRef {
    // if we have a delegate, it goes first...
	if (self.delegate != nil) {
		NSString *delegateReason = nil;
		if (![self.delegate shortcutValidator:self 
							  canUseKeyCode:keyCode 
						  withFlags:SRCarbonToCocoaFlags(flags)
								 reason:&delegateReason]) {
            if ( errorRef != NULL ) {
                NSString *description = [NSString stringWithFormat:
                    SRLoc(@"The key combination \u201c%@\u201d cannot be used."), 
                    SRStringForCarbonModifierFlagsAndKeyCode( flags, keyCode )];
                NSString *recoverySuggestion = [NSString stringWithFormat:
                    SRLoc(@"The key combination \u201c%@\u201d cannot be used because %@."),
                    SRReadableStringForCarbonModifierFlagsAndKeyCode( flags, keyCode ),
                    ( delegateReason && [delegateReason length] ) ? delegateReason : SRLoc(@"it\u2019s already in use")];
                NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										  description, NSLocalizedDescriptionKey,
										  recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
										  nil];
                *errorRef = [NSError errorWithDomain:SRBundleIdentifier code:0 userInfo:userInfo];
            }
			return NO;
		}
	}
	
	NSString *localKeyString = SRStringForKeyCode( keyCode );
	if ([localKeyString length] == 0) {
		// WARNING: this MUST populate errorRef if non NULL
		return NO;
	}
	
	NSArray *globalHotKeys = nil;
	if (CopySymbolicHotKeys((CFArrayRef *)&globalHotKeys) != noErr) {
		// WARNING: this MUST populate errorRef if non NULL
		return NO;
	}
	
	BOOL localCommandMod = NO, localOptionMod = NO, localShiftMod = NO, localCtrlMod = NO;
	// Prepare local carbon comparison flags
	if (flags & cmdKey) localCommandMod = YES;
	if (flags & optionKey) localOptionMod = YES;
	if (flags & shiftKey) localShiftMod = YES;
	if (flags & controlKey) localCtrlMod = YES;
    
	for (NSDictionary *globalHotKeyInfoDictionary in globalHotKeys) {
		// Only check if global hotkey is enabled
		if ((CFBooleanRef)[globalHotKeyInfoDictionary objectForKey:(NSString *)kHISymbolicHotKeyEnabled] != kCFBooleanTrue) {
			continue;
		}
        
        NSInteger globalHotKeyCharCode = [(NSNumber *)[globalHotKeyInfoDictionary objectForKey:(NSString *)kHISymbolicHotKeyCode] shortValue];
        
		int32_t globalHotKeyFlags = 0;
        CFNumberGetValue((CFNumberRef)[globalHotKeyInfoDictionary objectForKey:(NSString *)kHISymbolicHotKeyModifiers], kCFNumberSInt32Type, &globalHotKeyFlags);
        
		BOOL globalCommandMod = NO, globalOptionMod = NO, globalShiftMod = NO, globalCtrlMod = NO;
        if ( globalHotKeyFlags & cmdKey )        globalCommandMod = YES;
        if ( globalHotKeyFlags & optionKey )     globalOptionMod = YES;
        if ( globalHotKeyFlags & shiftKey)       globalShiftMod = YES;
        if ( globalHotKeyFlags & controlKey )    globalCtrlMod = YES;
        
        
        // compare unichar value and modifier flags
		if ( ( globalHotKeyCharCode == keyCode ) 
             && ( globalCommandMod == localCommandMod ) 
             && ( globalOptionMod == localOptionMod ) 
             && ( globalShiftMod == localShiftMod ) 
             && ( globalCtrlMod == localCtrlMod ) )
        {
            if ( errorRef != NULL ) {
                NSString *description = [NSString stringWithFormat: 
                    SRLoc(@"The key combination \u201c%@\u201d cannot be used."), 
                    SRStringForCarbonModifierFlagsAndKeyCode( flags, keyCode )];
                NSString *recoverySuggestion = [NSString stringWithFormat: 
                    SRLoc(@"The key combination \u201c%@\u201d cannot be used because it\u2019s already in use by a system-wide keyboard shortcut. (If you really want to use this key combination, most shortcuts can be changed in the Keyboard & Mouse panel in System Preferences.)"),
                    SRReadableStringForCarbonModifierFlagsAndKeyCode( flags, keyCode )];
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										  description, NSLocalizedDescriptionKey,
										  recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
										  nil];
                *errorRef = [NSError errorWithDomain:SRBundleIdentifier code:0 userInfo:userInfo];
            }
            return NO;
        }
	}
	
	// Check menus too
	return [self canUseKeyCode:keyCode withFlags:flags inMenu:[[NSApplication sharedApplication] mainMenu] error:errorRef];
}

- (BOOL)canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags inMenu:(NSMenu *)menu error:(NSError **)errorRef {
	BOOL localCommandMod = NO, localOptionMod = NO, localShiftMod = NO, localCtrlMod = NO;
	// Prepare local carbon comparison flags
	if ( flags & cmdKey )       localCommandMod = YES;
	if ( flags & optionKey )    localOptionMod = YES;
	if ( flags & shiftKey )     localShiftMod = YES;
	if ( flags & controlKey )   localCtrlMod = YES;
	
	for (NSMenuItem *currentMenuItem in [menu itemArray]) {
        // rescurse into all submenus...
		if ([currentMenuItem hasSubmenu]) {
			if (![self canUseKeyCode:keyCode withFlags:flags inMenu:[currentMenuItem submenu] error:errorRef]) {
				return NO;
			}
		}
		
		NSString *menuItemKeyEquivalent = [currentMenuItem keyEquivalent];
		if ( menuItemKeyEquivalent == nil || [menuItemKeyEquivalent isEqualToString: @""])
		{
			continue;
		}
		
		NSUInteger menuItemModifierFlags = [currentMenuItem keyEquivalentModifierMask];
		BOOL menuItemCommandMod = NO, menuItemOptionMod = NO, menuItemShiftMod = NO, menuItemCtrlMod = NO;
		if ( menuItemModifierFlags & NSCommandKeyMask )     menuItemCommandMod = YES;
		if ( menuItemModifierFlags & NSAlternateKeyMask )   menuItemOptionMod = YES;
		if ( menuItemModifierFlags & NSShiftKeyMask )       menuItemShiftMod = YES;
		if ( menuItemModifierFlags & NSControlKeyMask )     menuItemCtrlMod = YES;
		
		NSString *localKeyString = SRStringForKeyCode( keyCode );
		
		// Compare translated keyCode and modifier flags
		if ( ( [[menuItemKeyEquivalent uppercaseString] isEqualToString: localKeyString] ) 
			&& ( menuItemCommandMod == localCommandMod ) 
			&& ( menuItemOptionMod == localOptionMod ) 
			&& ( menuItemShiftMod == localShiftMod ) 
			&& ( menuItemCtrlMod == localCtrlMod ) )
		{
			if (errorRef != NULL) {
				// WARNING: make this error creation code and the error creation code in `- (BOOL)canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags error:(NSError **)errorRef` common
				
				NSString *description = [NSString stringWithFormat: 
										 SRLoc(@"The key combination \u201c%@\u201d can\u2019t be used."),
										 SRStringForCarbonModifierFlagsAndKeyCode( flags, keyCode )];
				NSString *recoverySuggestion = [NSString stringWithFormat: 
												SRLoc(@"The key combination \u201c%@\u201d can\u2019t be used because it\u2019s already in use by the menu item \u201c%@\u201d."),
												SRReadableStringForCocoaModifierFlagsAndKeyCode( menuItemModifierFlags, keyCode ),
												[currentMenuItem title]];
				NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
										  description, NSLocalizedDescriptionKey,
										  recoverySuggestion, NSLocalizedRecoverySuggestionErrorKey,
										  nil];
				*errorRef = [NSError errorWithDomain:SRBundleIdentifier code:0 userInfo:userInfo];
			}
			return NO;
		}
	}
	
	return YES;
}

@end
