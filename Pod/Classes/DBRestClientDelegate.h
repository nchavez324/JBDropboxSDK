//
//  DBRestClientDelegate.h
//  Jukeboxx
//
//  Created by Nick Chavez on 6/16/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DBRestClient, DBMetadata;

@protocol DBRestClientDelegate <NSObject>

@optional

//For callback events from rest cliend
- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata;

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error;

- (void)restClient:(DBRestClient *)client loadedMediaStreamUrl:(NSURL *)url expiration:(NSDate *)expires path:(NSString *)path;

- (void)restClient:(DBRestClient *)client loadMediaStreamUrlFailedWithError:(NSError *)error path:(NSString *)path;

- (void)restClient:(DBRestClient *)client downloadedFileTo:(NSString *)localPath path:(NSString *)path;

- (void)restClient:(DBRestClient *)client downloadFileFailedWithError:(NSError *)error path:(NSString *)path;

@end
