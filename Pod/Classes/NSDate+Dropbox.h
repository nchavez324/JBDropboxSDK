//
//  NSDate+Dropbox.h
//  Jukeboxx
//
//  Created by Nick Chavez on 6/20/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (Dropbox)

+ (NSDate *)dateFromDropboxString:(NSString *)string;

@end