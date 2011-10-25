#import "ResizabilityExtensions.h"

@implementation NSView (ResizabilityExtentions)
-(void) breakpad_shiftVertically:(CGFloat)offset {
    NSPoint origin = [self frame].origin;

    origin.y += offset;
    [self setFrameOrigin:origin];
}

-(void) breakpad_shiftHorizontally:(CGFloat)offset {
    NSPoint origin = [self frame].origin;

    origin.x += offset;
    [self setFrameOrigin:origin];
}

@end

@implementation NSWindow (ResizabilityExtentions)
-(void) breakpad_adjustHeight:(CGFloat)heightDelta {
    [[self contentView] setAutoresizesSubviews:NO];

    NSRect windowFrame = [self frame];
    windowFrame.size.height += heightDelta;
    [self setFrame:windowFrame display:YES];
    // For some reason the content view is resizing, but not adjusting its origin,
    // so correct it manually.
    [[self contentView] setFrameOrigin:NSMakePoint(0, 0)];

    [[self contentView] setAutoresizesSubviews:YES];
}

@end

@implementation NSTextField (ResizabilityExtentions)
-(CGFloat) breakpad_adjustHeightToFit {
    NSRect oldFrame = [self frame];
    // Starting with the 10.5 SDK, height won't grow, so make it huge to start.
    NSRect presizeFrame = oldFrame;

    presizeFrame.size.height = MAXFLOAT;
    // sizeToFit will blow out the width rather than making the field taller, so
    // we do it manually.
    NSSize newSize = [[self cell] cellSizeForBounds:presizeFrame];
    NSRect newFrame = NSMakeRect(oldFrame.origin.x, oldFrame.origin.y,
            NSWidth(oldFrame), newSize.height);
    [self setFrame:newFrame];

    return newSize.height - NSHeight(oldFrame);
}

-(CGFloat) breakpad_adjustWidthToFit {
    NSRect oldFrame = [self frame];

    [self sizeToFit];
    return NSWidth([self frame]) - NSWidth(oldFrame);
}

@end

@implementation NSButton (ResizabilityExtentions)
-(CGFloat) breakpad_smartSizeToFit {
    NSRect oldFrame = [self frame];

    [self sizeToFit];
    NSRect newFrame = [self frame];
    // sizeToFit gives much worse results that IB's Size to Fit option. This is
    // the amount of padding IB adds over a sizeToFit, empirically determined.
    const float kExtraPaddingAmount = 12;
    const float kMinButtonWidth = 70; // The default button size in IB.
    newFrame.size.width = NSWidth(newFrame) + kExtraPaddingAmount;
    if (NSWidth(newFrame) < kMinButtonWidth) {
        newFrame.size.width = kMinButtonWidth;                                       // Preserve the right edge location.
    }
    newFrame.origin.x = NSMaxX(oldFrame) - NSWidth(newFrame);
    [self setFrame:newFrame];
    return NSWidth(newFrame) - NSWidth(oldFrame);
}

@end
