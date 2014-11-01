//
//  NSDate+Dropbox.m
//  Jukeboxx
//
//  Created by Nick Chavez on 6/20/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import "NSDate+Dropbox.h"

@implementation NSDate (Dropbox)

+ (NSDate *)dateFromDropboxString:(NSString *)string{
    /*
     "Sat, 21 Aug 2010 22:31:20 +0000"
     "%a, %d %b %Y %H:%M:%S %z"
     */
    struct tm time;
    strptime([string UTF8String], "%a, %d %b %Y %H:%M:%S %z", &time);
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:mktime(&time)];
    return date;
}

@end