#import <Foundation/Foundation.h>

@interface NSView (ResizabilityExtentions)
// Shifts the view vertically by the given amount.
-(void)breakpad_shiftVertically:(CGFloat)offset;

// Shifts the view horizontally by the given amount.
-(void)breakpad_shiftHorizontally:(CGFloat)offset;
@end

@interface NSWindow (ResizabilityExtentions)
// Adjusts the window height by heightDelta relative to its current height,
// keeping all the content at the same size.
-(void)breakpad_adjustHeight:(CGFloat)heightDelta;
@end

@interface NSTextField (ResizabilityExtentions)
// Grows or shrinks the height of the field to the minimum required to show the
// current text, preserving the existing width and origin.
// Returns the change in height.
-(CGFloat)breakpad_adjustHeightToFit;

// Grows or shrinks the width of the field to the minimum required to show the
// current text, preserving the existing height and origin.
// Returns the change in width.
-(CGFloat)breakpad_adjustWidthToFit;
@end

@interface NSButton (ResizabilityExtentions)
// Resizes to fit the label using IB-style size-to-fit metrics and enforcing a
// minimum width of 70, while preserving the right edge location.
// Returns the change in width.
-(CGFloat)breakpad_smartSizeToFit;
@end

