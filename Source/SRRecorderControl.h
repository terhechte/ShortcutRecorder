//
//  SRRecorderControl.h
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

#import <Cocoa/Cocoa.h>
#import "SRRecorderCell.h"

@class SRRecorderControl;

// Delegate Methods
@protocol SRRecorderControlDelegate <NSObject>

@optional
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags reason:(NSString **)aReason;
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo;

@end

@interface SRRecorderControl : NSControl <SRRecorderCellDelegate>

#pragma mark *** Aesthetics ***
- (BOOL)animates;
- (void)setAnimates:(BOOL)an;
- (SRRecorderStyle)style;
- (void)setStyle:(SRRecorderStyle)nStyle;

#pragma mark *** Delegate ***

@property (nonatomic, weak) IBOutlet id<SRRecorderControlDelegate> delegate;

#pragma mark *** Key Combination Control ***

- (NSUInteger)allowedFlags;
- (void)setAllowedFlags:(NSUInteger)flags;

- (BOOL)allowsKeyOnly;
- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord;
- (BOOL)escapeKeysRecord;
- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly;
- (void)setEscapeKeysRecord:(BOOL)nEscapeKeysRecord;

- (BOOL)canCaptureGlobalHotKeys;
- (void)setCanCaptureGlobalHotKeys:(BOOL)inState;

- (NSUInteger)requiredFlags;
- (void)setRequiredFlags:(NSUInteger)flags;

- (KeyCombo)keyCombo;
- (void)setKeyCombo:(KeyCombo)aKeyCombo;

- (NSString *)keyChars;
- (NSString *)keyCharsIgnoringModifiers;

#pragma mark *** Autosave Control ***

- (NSString *)autosaveName;
- (void)setAutosaveName:(NSString *)aName;

#pragma mark -

// Returns the displayed key combination if set
- (NSString *)keyComboString;

#pragma mark *** Conversion Methods ***

- (NSUInteger)cocoaToCarbonFlags:(NSUInteger)cocoaFlags;
- (NSUInteger)carbonToCocoaFlags:(NSUInteger)carbonFlags;

@end
