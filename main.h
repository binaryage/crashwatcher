// the code originally taken from breakpad codebase (Google)

@interface Reporter : NSObject {
 @public
  IBOutlet NSWindow* alertWindow_;

  IBOutlet NSTextField* dialogTitle_;
  IBOutlet NSTextField* dialogNote_;
  IBOutlet NSTextField* dialogExplanation_;
  IBOutlet NSTextField* commentMessage_;
  IBOutlet NSButton* sendButton_;
  IBOutlet NSButton* cancelButton_;
  IBOutlet NSTextField* countdownLabel_;
  IBOutlet NSProgressIndicator* progressIndicator_;

  // text field bindings, for user input
  NSString* countdownMessage_;  // message indicating time left for input.
  NSString* targetApp_;         // TotalTerminal or TotalFinder
    
 @private
  NSDictionary* parameters_;            // key value pairs of data
  NSTimeInterval remainingDialogTime_;  // keeps track of how long we have until we cancel the dialog
  NSTimer* messageTimer_;               // timer we use to update the dialog
}

- (IBAction)sendReport:(id)sender;
- (IBAction)cancel:(id)sender;

- (NSString*)countdownMessage;
- (void)setCountdownMessage:(NSString*)value;

@end