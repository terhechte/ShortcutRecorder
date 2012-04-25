//
//  SRRecorderCell.h
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
#import "SRCommon.h"
#import "SRValidator.h"

#define SRMinWidth 50
#define SRMaxHeight 22

#define SRTransitionFPS 30.0f
#define SRTransitionDuration 0.35f
//#define SRTransitionDuration 2.35
#define SRTransitionFrames (SRTransitionFPS*SRTransitionDuration)
#define SRAnimationAxisIsY YES
#define ShortcutRecorderNewStyleDrawing

#define SRAnimationOffsetRect(X,Y)	(SRAnimationAxisIsY ? NSOffsetRect(X,0.0f,-NSHeight(Y)) : NSOffsetRect(X,NSWidth(Y),0.0f))

@class SRRecorderCell;
@class SRRecorderControl;

// Delegate Methods
@protocol SRRecorderCellDelegate <NSObject>

- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags reason:(NSString **)aReason;
- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(KeyCombo)newCombo;

@end

enum {
    SRGradientBorderStyle = 0,
    SRGreyStyle = 1
};
typedef NSUInteger SRRecorderStyle;

@interface SRRecorderCell : NSActionCell <NSCoding, SRValidatorDelegate> {
	NSGradient          *recordingGradient;
	NSString            *autosaveName;
	
	BOOL                isRecording;
	BOOL                mouseInsideTrackingArea;
	BOOL                mouseDown;
	BOOL				mouseDownInButton;
	
	SRRecorderStyle		style;
	
	BOOL				isAnimating;
	CGFloat				transitionProgress;
	BOOL				isAnimatingNow;
	BOOL				isAnimatingTowardsRecording;
	BOOL				comboJustChanged;
	
	NSTrackingRectTag   removeTrackingRectTag;
	NSTrackingRectTag   snapbackTrackingRectTag;
	
	KeyCombo            keyCombo;
	BOOL				hasKeyChars;
	NSString		    *keyChars;
	NSString		    *keyCharsIgnoringModifiers;
	
	NSUInteger        allowedFlags;
	NSUInteger        requiredFlags;
	NSUInteger        recordingFlags;
	
	BOOL				allowsKeyOnly;
	BOOL				escapeKeysRecord;
	
	NSSet               *cancelCharacterSet;
	
    SRValidator         *validator;
    
	BOOL				globalHotKeys;
	void				*hotKeyModeToken;
}

- (void)resetTrackingRects;

#pragma mark *** Aesthetics ***

+ (BOOL)styleSupportsAnimation:(SRRecorderStyle)style;

- (BOOL)animates;
- (void)setAnimates:(BOOL)an;
- (SRRecorderStyle)style;
- (void)setStyle:(SRRecorderStyle)nStyle;

#pragma mark *** Delegate ***

@property (nonatomic, weak) IBOutlet id<SRRecorderCellDelegate> delegate;

#pragma mark *** Responder Control ***

- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

#pragma mark *** Key Combination Control ***

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)flagsChanged:(NSEvent *)theEvent;

- (NSUInteger)allowedFlags;
- (void)setAllowedFlags:(NSUInteger)flags;

- (NSUInteger)requiredFlags;
- (void)setRequiredFlags:(NSUInteger)flags;

- (BOOL)allowsKeyOnly;
- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord;

- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly;
- (void)setEscapeKeysRecord:(BOOL)nEscapeKeysRecord;
- (BOOL)escapeKeysRecord;

- (BOOL)canCaptureGlobalHotKeys;
- (void)setCanCaptureGlobalHotKeys:(BOOL)inState;

- (KeyCombo)keyCombo;
- (void)setKeyCombo:(KeyCombo)aKeyCombo;

#pragma mark *** Autosave Control ***

- (NSString *)autosaveName;
- (void)setAutosaveName:(NSString *)aName;

// Returns the displayed key combination if set
- (NSString *)keyComboString;

- (NSString *)keyChars;
- (NSString *)keyCharsIgnoringModifiers;

@end
