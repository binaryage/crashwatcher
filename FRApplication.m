/*
 * Copyright 2008, Torsten Curdt
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#import "FRApplication.h"
#import "FRConstants.h"

@implementation FRApplication

+(NSString*) applicationVersion {
    NSString* applicationVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleLongVersionString"];

    if (!applicationVersion) {
        applicationVersion = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    }

    return applicationVersion;
}

+(NSString*) applicationName {
    return @"Finder"; // HACK
    // NSString *applicationName = [[[NSBundle mainBundle] localizedInfoDictionary] valueForKey: @"CFBundleExecutable"];
    //
    // if (!applicationName) {
    // applicationName = [[[NSBundle mainBundle] infoDictionary] valueForKey: @"CFBundleExecutable"];
    // }
    //
    // return applicationName;
}

+(NSString*) applicationIdentifier {
    NSString* applicationIdentifier = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleIdentifier"];

    return applicationIdentifier;
}

+(NSString*) feedbackURL {
    NSString* target = [[[NSBundle mainBundle] infoDictionary] valueForKey:PLIST_KEY_LOGHOURS];

    if (target == nil) {
        return nil;
    }

    return [NSString stringWithFormat:target, [FRApplication applicationName]];
}

@end
