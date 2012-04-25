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

#import <Cocoa/Cocoa.h>

@class SRValidator;

@protocol SRValidatorDelegate <NSObject>

- (BOOL)shortcutValidator:(SRValidator *)validator canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags reason:(NSString **)aReason;

@end

@interface SRValidator : NSObject

@property (nonatomic, weak) id<SRValidatorDelegate> delegate;

- (id)initWithDelegate:(id<SRValidatorDelegate>)delegate;

- (BOOL)canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags error:(NSError **)error;
- (BOOL)canUseKeyCode:(NSInteger)keyCode withFlags:(NSUInteger)flags inMenu:(NSMenu *)menu error:(NSError **)error;

@end
