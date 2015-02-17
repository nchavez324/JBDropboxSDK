//
//  DBRestClient.h
//  Jukeboxx
//
//  Created by Nick Chavez on 6/16/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//
/*
 Use to access Dropbox API, for:
 
 1. File/folder metadata and contents
 2. Requesting a media stream URL
 */

#import <Foundation/Foundation.h>
#import "DBRestClientDelegate.h"

@class DBSession;

@interface DBRestClient : NSObject

@property (weak, nonatomic) id<DBRestClientDelegate> delegate;

//Start with a DBSession
- (id)initWithSession:(DBSession *)session;

//Loads metadata for path, can force a remote update
- (void)loadMetadata:(NSString *)path forceRemoteUpdate:(BOOL)forceRemoteUpdate;

//Request a media stream URL for given path
- (void)loadMediaStreamUrl:(NSString *)path;

//Save a file by path
- (void)downloadFile:(NSString *)path;

@end
