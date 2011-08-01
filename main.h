// Copyright (c) 2006, Google Inc.
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//
// * Redistributions of source code must retain the above copyright
// notice, this list of conditions and the following disclaimer.
// * Redistributions in binary form must reproduce the above
// copyright notice, this list of conditions and the following disclaimer
// in the documentation and/or other materials provided with the
// distribution.
// * Neither the name of Google Inc. nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// This component uses the HTTPMultipartUpload of the breakpad project to send
// the minidump and associated data to the crash reporting servers.
// It will perform throttling based on the parameters passed to it and will
// prompt the user to send the minidump.

#include <Foundation/Foundation.h>

@interface Reporter : NSObject {
    @public
    IBOutlet NSWindow* alertWindow_;      // The alert window

    IBOutlet NSTextField* dialogTitle_;
    IBOutlet NSTextField* dialogNote_;
    IBOutlet NSTextField* commentMessage_;
    IBOutlet NSButton* sendButton_;
    IBOutlet NSButton* cancelButton_;
    IBOutlet NSTextField* countdownLabel_;

    // Text field bindings, for user input.
    NSString* countdownMessage_;           // Message indicating time left for input.
    NSString* targetApp_;                  // TotalTerminal or TotalFinder
    @private
    NSDictionary* parameters_;             // Key value pairs of data
    NSTimeInterval remainingDialogTime_;   // Keeps track of how long we have until we cancel the dialog
    NSTimer* messageTimer_;                // Timer we use to update the dialog
}

// Stops the modal panel with an NSAlertDefaultReturn value. This is the action
// invoked by the "Send Report" button.
-(IBAction)sendReport:(id)sender;
// Stops the modal panel with an NSAlertAlternateReturn value. This is the
// action invoked by the "Cancel" button.
-(IBAction)cancel:(id)sender;

-(NSString*)countdownMessage;
-(void)setCountdownMessage:(NSString*)value;

@end

@interface Reporter (PrivateMethods)
-(id)init;

-(BOOL)readConfigurationData;

// Shows UI to the user to ask for permission to send and any extra information
// we've been instructed to request. Returns YES if the user allows the report
// to be sent.
-(BOOL)askUserPermissionToSend;

// Returns the amount of time the UI should be shown before timing out.
-(NSTimeInterval)messageTimeout;

-(void)configureAlertWindow;

// Run an alert window with the given timeout. Returns
// NSRunStoppedResponse if the timeout is exceeded. A timeout of 0
// queues the message immediately in the modal run loop.
-(NSInteger)runModalWindow:(NSWindow*)window
               withTimeout:(NSTimeInterval)timeout;

// This method is used to periodically update the UI with how many
// seconds are left in the dialog display.
-(void)updateSecondsLeftInDialogDisplay:(NSTimer*)theTimer;

@end
