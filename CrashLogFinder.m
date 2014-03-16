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

#import "CrashLogFinder.h"

@implementation CrashLogFinder

+ (NSString*)crashLogPrefix {
  static NSString* cachedPrefix = nil;

  cachedPrefix = [[NSBundle mainBundle] infoDictionary][@"CrashLogPrefix"];
  if (!cachedPrefix || ![cachedPrefix isKindOfClass:[NSString class]]) {
    NSLog(@"CrashLogPrefix key is missing in Info.plist");
    cachedPrefix = @"XXX";
  }

  return cachedPrefix;
}

+ (BOOL)file:(NSString*)path isNewerThan:(NSDate*)date {
  NSFileManager* fileManager = [NSFileManager defaultManager];

  if (![fileManager fileExistsAtPath:path]) {
    return NO;
  }

  if (!date) {
    return YES;
  }

  NSError* error = nil;
  NSDate* fileDate = [[fileManager attributesOfItemAtPath:path error:&error] fileCreationDate];
  if (error) {
    NSLog(@"Error while fetching file attributes: %@", [error localizedDescription]);
    return NO;
  }

  if (!fileDate) {
    NSLog(@"Error while fetching fileCreationDate: nil returned");
    return NO;
  }

  if ([date compare:fileDate] == NSOrderedDescending) {
    return NO;
  }

  return YES;
}

+ (NSArray*)findCrashLogsIn:(NSString*)folder since:(NSDate*)date {
  NSMutableArray* files = [NSMutableArray array];
  NSFileManager* fileManager = [NSFileManager defaultManager];

  NSDirectoryEnumerator* enumerator;
  NSString* file;

  if ([fileManager fileExistsAtPath:folder]) {
    enumerator = [fileManager enumeratorAtPath:folder];
    while ((file = [enumerator nextObject])) {
      if ([file hasSuffix:@".crash"] && [file hasPrefix:[self crashLogPrefix]]) {
        file = [[folder stringByAppendingPathComponent:file] stringByExpandingTildeInPath];

        if ([self file:file isNewerThan:date]) {
          [files addObject:file];
        }
      }
    }
  }

  return files;
}

@end
