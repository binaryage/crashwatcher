#import "main.h"

#import "CrashLogFinder.h"

#ifdef DEBUG
#define DLOG(...) NSLog(__VA_ARGS__)
#else
#define DLOG(...)
#endif

#define WATCHED_PATH "~/Library/Logs/DiagnosticReports"
static NSString* gTargetApp = @"UnknownApp";  // will be set to TotalTerminal, TotalFinder, etc.

@implementation Reporter
// =============================================================================
- (id)init {
  if ((self = [super init])) {
    remainingDialogTime_ = 0;
  }

  // Because the reporter is embedded in the framework (and many copies
  // of the framework may exist) its not completely certain that the OS
  // will obey the com.apple.PreferenceSync.ExcludeAllSyncKeys in our
  // Info.plist. To make sure, also set the key directly if needed.
  NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
  if (![ud boolForKey:@"com.apple.PreferenceSync.ExcludeAllSyncKeys"]) {
    [ud setBool:YES forKey:@"com.apple.PreferenceSync.ExcludeAllSyncKeys"];
  }

  return self;
}

// =============================================================================
- (BOOL)readConfigurationData {
  parameters_ = [[NSBundle mainBundle] infoDictionary];
  return YES;
}

// =============================================================================
- (BOOL)askUserPermissionToSend {
  // Initialize Cocoa, needed to display the alert
  NSApplicationLoad();

  // Get the timeout value for the notification.
  NSTimeInterval timeout = [self messageTimeout];

  NSInteger buttonPressed = NSAlertAlternateReturn;

  // Determine whether we should create a text box for user feedback.
  static NSArray* holdNibObjects;
  NSArray* nibObjects;
  BOOL nibOk = [[NSBundle bundleForClass:[self class]] loadNibNamed:@"CrashWatcher" owner:self topLevelObjects:&nibObjects];
  if (!nibOk) {
    NSLog(@"unexpected error: loadNibNamed failed to load %@", @"CrashWatcher");
    return NO;
  }
  holdNibObjects = nibObjects;

  [self configureAlertWindow];

  buttonPressed = [self runModalWindow:alertWindow_ withTimeout:timeout];
  if (buttonPressed == NSAlertDefaultReturn) {
    [cancelButton_ setHidden:YES];
    [progressIndicator_ setUsesThreadedAnimation:YES];
    [progressIndicator_ setFrameOrigin:NSOffsetRect([sendButton_ frame], -24, 10).origin];
    [progressIndicator_ setHidden:NO];
    [progressIndicator_ startAnimation:self];
    [alertWindow_ display];
  }
  return buttonPressed == NSAlertDefaultReturn;
}

- (void)hideAlertWindow {
  [alertWindow_ orderOut:self];
}

- (void)configureAlertWindow {
  // Swap in localized values, making size adjustments to impacted elements as
  // we go. Remember that the origin is in the bottom left, so elements above
  // "fall" as text areas are shrunk from their overly-large IB sizes.

  [dialogTitle_ setStringValue:NSLocalizedString(@"crashDialogHeader", @"")];
  [commentMessage_ setStringValue:NSLocalizedString(@"crashDialogMsg", @"")];
  [dialogNote_ setStringValue:NSLocalizedString(@"crashDialogNote", @"")];
  [dialogExplanation_ setStringValue:NSLocalizedString(@"crashDialogExplanation", @"")];

  // Localize the buttons, and keep the cancel button at the right distance.
  [sendButton_ setTitle:NSLocalizedString(@"sendReportButton", @"")];
  [cancelButton_ setTitle:NSLocalizedString(@"cancelButton", @"")];
}

- (NSInteger)runModalWindow:(NSWindow*)window withTimeout:(NSTimeInterval)timeout {
  // Queue a |stopModal| message to be performed in |timeout| seconds.
  if (timeout > 0.001) {
    remainingDialogTime_ = timeout;
    SEL updateSelector = @selector(updateSecondsLeftInDialogDisplay:);
    messageTimer_ = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:updateSelector userInfo:nil repeats:YES];
  }

  // Run the window modally and wait for either a |stopModal| message or a button click.
  [self updateSecondsLeftInDialogDisplay:messageTimer_];
  [NSApp activateIgnoringOtherApps:YES];
  NSInteger returnMethod = [NSApp runModalForWindow:window];

  return returnMethod;
}

// UI Button Actions
// =============================================================================
- (IBAction)sendReport:(id)sender {
  // Use NSAlertDefaultReturn so that the return value of |runModalWithWindow|
  // matches the AppKit function NSRunAlertPanel()
  [NSApp stopModalWithCode:NSAlertDefaultReturn];
}

- (IBAction)cancel:(id)sender {
  // Use NSAlertDefaultReturn so that the return value of |runModalWithWindow|
  // matches the AppKit function NSRunAlertPanel()
  [NSApp stopModalWithCode:NSAlertAlternateReturn];
}

- (void)updateSecondsLeftInDialogDisplay:(NSTimer*)theTimer {
  remainingDialogTime_ -= 1;

  NSString* countdownMessage;
  NSString* formatString;

  int displayedTimeLeft;  // This can be either minutes or seconds.

  if (remainingDialogTime_ > 59) {
    // calculate minutes remaining for UI purposes
    displayedTimeLeft = (int)(remainingDialogTime_ / 60);

    if (displayedTimeLeft == 1) {
      formatString = NSLocalizedString(@"countdownMsgMinuteSingular", @"");
    } else {
      formatString = NSLocalizedString(@"countdownMsgMinutesPlural", @"");
    }
  } else {
    displayedTimeLeft = (int)remainingDialogTime_;
    if (displayedTimeLeft == 1) {
      formatString = NSLocalizedString(@"countdownMsgSecondSingular", @"");
    } else {
      formatString = NSLocalizedString(@"countdownMsgSecondsPlural", @"");
    }
  }
  countdownMessage = [NSString stringWithFormat:formatString, displayedTimeLeft];
  if (remainingDialogTime_ <= 30) {
    [countdownLabel_ setTextColor:[NSColor redColor]];
  }
  [self setCountdownMessage:countdownMessage];
  if (remainingDialogTime_ <= 0) {
    [messageTimer_ invalidate];
    [NSApp stopModal];
  }
}

#pragma mark Accessors
#pragma mark -
// =============================================================================

- (NSString*)countdownMessage {
  return countdownMessage_;
}

- (void)setCountdownMessage:(NSString*)value {
  if (countdownMessage_ != value) {
    countdownMessage_ = [value copy];
  }
}

#pragma mark -

- (NSTimeInterval)messageTimeout {
  NSTimeInterval timeout = [parameters_[@"ConfirmTimeout"] floatValue];

  return timeout;
}

- (NSString*)runRubyCommand:(NSString*)name withCrashFile:(NSString*)cfile {
  NSTask* task = [[NSTask alloc] init];

  [task setLaunchPath:@"/usr/bin/ruby"];
  NSArray* args = @[ [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rb"], cfile ];
  [task setArguments:args];

  NSPipe* pipe;
  pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];

  NSFileHandle* file;
  file = [pipe fileHandleForReading];

  [task launch];

  NSString* string;
  string = [[NSString alloc] initWithData:[file readDataToEndOfFile] encoding:NSUTF8StringEncoding];

  [task waitUntilExit];

  return string;
}

// http://vgable.com/blog/2008/03/05/calling-the-command-line-from-cocoa/
- (int)askRubyCommand:(NSString*)name withCrashFile:(NSString*)cfile {
  NSTask* task = [[NSTask alloc] init];

  [task setLaunchPath:@"/usr/bin/ruby"];
  NSArray* args = @[ [[NSBundle bundleForClass:[self class]] pathForResource:name ofType:@"rb"], cfile ];
  [task setArguments:args];

  NSPipe* pipe;
  pipe = [NSPipe pipe];
  [task setStandardOutput:pipe];

  [pipe fileHandleForReading];

  [task launch];
  [task waitUntilExit];

  return [task terminationStatus];
}

- (void)report:(NSString*)lastCrash {
  NSString* gistUrl = @"";
  NSString* extraInfo = @"";

  if (lastCrash) {
    NSLog(@"Uploading crash report to gist.github.com: %@", lastCrash);
    gistUrl = [self runRubyCommand:@"upload-gist" withCrashFile:lastCrash];
    NSLog(@"  => %@", gistUrl);
    if (gistUrl) {
      extraInfo = [self runRubyCommand:@"extract-crash-info" withCrashFile:lastCrash];
      if (!extraInfo) {
        extraInfo = @"";
      }
    }
  }

  if (!gistUrl || [gistUrl isEqualToString:@""]) {
    NSAlert* alert = [NSAlert new];
    [alert setMessageText:NSLocalizedString(@"failDialogHeader", @"")];
    if (!lastCrash) {
      [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"failDialogMsg1", @"")]];
    } else {
      [alert setInformativeText:[NSString stringWithFormat:NSLocalizedString(@"failDialogMsg2", @""), lastCrash]];
    }
    [alert addButtonWithTitle:NSLocalizedString(@"failDialogOK", @"")];
    [alert runModal];
    return;
  }
  NSString* email = @"crash-reports@binaryage.com";
  NSString* subjectString = [NSString stringWithFormat:@"%@", extraInfo];
  NSString* emailBody = [NSString stringWithFormat:NSLocalizedString(@"emailTemplate", @""), gTargetApp, gistUrl];

  NSString* mailto = [NSString stringWithFormat:@"mailto:%@?SUBJECT=%@&BODY=%@", email, subjectString, emailBody];
  NSString* encodedURLString = [mailto stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
  if (encodedURLString) {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:encodedURLString]];
    [NSThread sleepForTimeInterval:1.0];
    NSArray* apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.mail"];
    if ([apps count] > 0) {
      DLOG(@"activating ... %@", apps);
      [(NSRunningApplication*)apps[0] activateWithOptions:NSApplicationActivateAllWindows];
    }
  }
}

@end

bool dialogInProgress = false;

void mycallback(ConstFSEventStreamRef streamRef,
                void* clientCallBackInfo,
                size_t numEvents,
                void* eventPaths,
                const FSEventStreamEventFlags eventFlags[],
                const FSEventStreamEventId eventIds[]) {
  DLOG(@"Reporter awaken");
  if (dialogInProgress) {
    DLOG(@"Dialog still open - ignoring");
    return;
  }
  // discovered a suprising info from chromium sources:
  // The NSApplication-based run loop only drains the autorelease pool at each
  // UI event (NSEvent).  The autorelease pool is not drained for each
  // CFRunLoopSource target that's run.  Use a local pool for any autoreleased
  // objects if the app is not currently handling a UI event to ensure they're
  // released promptly even in the absence of UI events.
  @autoreleasepool {
    dialogInProgress = true;
    Reporter* reporter = (__bridge Reporter*)clientCallBackInfo;

    NSArray* crashFiles =
        [CrashLogFinder findCrashLogsIn:[@WATCHED_PATH stringByStandardizingPath] since:[[NSDate date] dateByAddingTimeInterval:-10]];  // 10 seconds ago
    NSString* lastCrash = NULL;
    if ([crashFiles count] > 0) {
      for (NSString* crash in crashFiles) {
        int status = [reporter askRubyCommand:@"related-crash-report" withCrashFile:crash];
        if (status == 1) {
          NSLog(@"'%@' crash report was related to the target app -> open Crash Reporting Dialog", crash);
          lastCrash = crashFiles[[crashFiles count] - 1];
          break;
        } else {
          NSLog(@"'%@' crash report was not related to the target app", crash);
        }
      }
    } else {
      DLOG(@"no fresh crash files found...");
    }

    if (lastCrash) {
      BOOL okayToSend = [reporter askUserPermissionToSend];
      if (okayToSend) {
        DLOG(@"Show Report Dialog");
        [reporter report:lastCrash];
        DLOG(@"Report Sent!");
      } else {
        DLOG(@"Not sending crash report okayToSend=%d", okayToSend);
      }
      [reporter hideAlertWindow];
    }

    dialogInProgress = false;
  }
}

static volatile BOOL caughtSIGINT = NO;
void handle_SIGINT(int signum) {
  caughtSIGINT = YES;
  CFRunLoopStop(CFRunLoopGetCurrent());
}

void handle_SIGUSR1(int signum) { mycallback(NULL, NULL, 0, NULL, 0, 0); }

static int lock = 0;

static NSString* lockPath() {
  static NSString* cachedLockPath = nil;

  if (!cachedLockPath) {
    cachedLockPath = [[NSString stringWithFormat:@"~/Library/Application Support/.%@CrashWatcher.lock", gTargetApp] stringByStandardizingPath];
  }
  return cachedLockPath;
}

static bool acquireLock() {
  const char* path = [lockPath() fileSystemRepresentation];

  lock = open(path, O_CREAT | O_RDWR, S_IRWXU);
  if (flock(lock, LOCK_EX | LOCK_NB) != 0) {
    NSLog(@"Unable to obtain lock '%s' - exiting to prevent multiple CrashWatcher instances", path);
    close(lock);
    return false;
  }
  return true;
}

static void releaseLock() {
  if (!lock)
    return;

  flock(lock, LOCK_UN | LOCK_NB);
  close(lock);
  unlink([lockPath() fileSystemRepresentation]);
}

static void initTargetApp() {
  gTargetApp = [[NSBundle mainBundle] infoDictionary][@"TargetApp"];
  if (!gTargetApp || ![gTargetApp isKindOfClass:[NSString class]]) {
    NSLog(@"TargetApp key is missing in Info.plist");
    gTargetApp = @"UnknownApp";
  }
}

// =============================================================================
int main(int argc, const char* argv[]) {
  @autoreleasepool {

    initTargetApp();

    // prevent multiple instances
    if (!acquireLock()) {
      exit(1);
    }

    signal(SIGHUP, SIG_IGN);
    signal(SIGUSR1, handle_SIGUSR1);
    signal(SIGUSR2, SIG_IGN);
    signal(SIGINT, handle_SIGINT);

    DLOG(@"Reporter Launched, argc=%d", argc);

    Reporter* reporter = [[Reporter alloc] init];

    // gather the configuration data
    if (![reporter readConfigurationData]) {
      DLOG(@"reporter readConfigurationData failed");
      releaseLock();
      exit(10);
    }

    NSString* watchedPath = [@WATCHED_PATH stringByStandardizingPath];
    NSArray* pathsToWatch = @[ watchedPath ];
    NSLog(@"Watching '%@' for new crash reports with prefix '%@'", watchedPath, [CrashLogFinder crashLogPrefix]);
    CFAbsoluteTime latency = 1.0;
    FSEventStreamContext context;
    memset(&context, 0, sizeof(context));
    context.info = (void*)CFBridgingRetain(reporter);  // keep reporter alive forever

    FSEventStreamRef stream = FSEventStreamCreate(NULL, &mycallback, &context, (__bridge CFArrayRef)pathsToWatch, kFSEventStreamEventIdSinceNow, latency,
                                                  kFSEventStreamCreateFlagNone);

    FSEventStreamScheduleWithRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
    FSEventStreamStart(stream);

    DLOG(@"looping...");
    // note: we need this loop because closing cocoa dialog ends our run loop
    while (!caughtSIGINT) {
      CFRunLoopRun();
    }
    DLOG(@"finished looping...");
    if (caughtSIGINT) {
      NSLog(@"caught SIGINT - exiting...");
    }

    FSEventStreamStop(stream);
    FSEventStreamUnscheduleFromRunLoop(stream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);

    releaseLock();
  }

  return 0;
}