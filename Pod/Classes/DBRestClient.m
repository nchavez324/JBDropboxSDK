//
//  DBRestClient.m
//  Jukeboxx
//
//  Created by Nick Chavez on 6/16/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import "DBRestClient.h"
#import "DBSession.h"
#import "DBMetadata.h"
#import "NSDate+Dropbox.h"
#import "DBJsonKeys.h"
#import "DBCoreDataManager.h"

#import "AFHTTPRequestOperationManager.h"

static NSString * const kBaseRestUrl = @"https://api.dropbox.com/1/";
static NSString * const kBaseContentUrl = @"https://api-content.dropbox.com/1/";
static NSString * const kDropboxRoot = @"dropbox";

@interface DBRestClient ()

@property (strong, nonatomic) DBSession *session;
@property (strong, nonatomic) AFHTTPRequestOperationManager *reqOpManager;

@end

@implementation DBRestClient

- (id)initWithSession:(DBSession *)session {
    if(self = [super init]){
        self.session = session;
        [self initialize];
    }
    return self;
        
}

- (void)dealloc {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initialize {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate) name:UIApplicationWillTerminateNotification object:nil];
    
    self.reqOpManager = [AFHTTPRequestOperationManager manager];
}

- (void)applicationWillTerminate {
    
    //cancel all downloads!
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"%@ == YES", kJsonIsDownloading];
    NSArray *results = [DBMetadata fetchMetadataWithPredicate:pred inContext:[DBCoreDataManager mainContext]];
    
    for (DBMetadata *metadata in results) {
        
        metadata.isDownloading = NO;
    }
    
    [DBCoreDataManager saveMainContext];
}


/**
 Check if data in store,
    if so
        return that
    if not
        pull remotely using hash
 forceRemoteUpdate overrides this
 **/
- (void)loadMetadata:(NSString *)path forceRemoteUpdate:(BOOL)forceRemoteUpdate {
    
    __block DBMetadata *metadata = nil;
    metadata = [DBMetadata fetchMetadataCompleteWithPath:path inContext:[DBCoreDataManager mainContext]];
    
    //If no cached data, or forced
    if(!metadata || forceRemoteUpdate){
        
        NSDictionary *parameters = @{
                                     @"access_token": self.session.accessToken
                                     };
        
        //Build request URL
        NSString *urlString = [DBRestClient urlForEndpoint:[NSString stringWithFormat:@"metadata/auto/%@", path] content:NO];
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        //AFNetworking to make HTTP request
        self.reqOpManager.responseSerializer = [AFJSONResponseSerializer serializer];
        [self.reqOpManager GET:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
            //Inform delegate, save in cache
            if(self.delegate){
                if(responseObject == nil){
                    if([self.delegate respondsToSelector:@selector(restClient:loadMetadataFailedWithError:)]){
                        NSError *error = [NSError errorWithDomain:[self.class description] code:1 userInfo:nil];
                        [self.delegate restClient:self loadMetadataFailedWithError:error];
                    }
                }else{
                    if([self.delegate respondsToSelector:@selector(restClient:loadedMetadata:)]){
                        metadata = [DBMetadata insertMetadataWithJSON:responseObject inContext:[DBCoreDataManager mainContext]];
                        //TODO: async
                        [DBCoreDataManager saveMainContext];
                        [self.delegate restClient:self loadedMetadata:metadata];
                    }
                }
            }
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            if(self.delegate && [self.delegate respondsToSelector:@selector(restClient:loadMetadataFailedWithError:)]){
                [self.delegate restClient:self loadMetadataFailedWithError:error];
            }
        }];
    }else{
        if([self.delegate respondsToSelector:@selector(restClient:loadedMetadata:)]){
            [self.delegate restClient:self loadedMetadata:metadata];
        }
    }
}

/**
 * Takes in a Dropbox path, e.g. "/Music/J. Cole/Welcome.mp3" and calls back
 * to a delegate a streamable url and an expiration date.
 */
- (void)loadMediaStreamUrl:(NSString *)path {
    
    //check if song has been saved for offline use
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"path == %@", path];
    NSArray *results = [DBMetadata fetchMetadataWithPredicate:pred inContext:[DBCoreDataManager mainContext]];
    if(results > 0 && [results[0] isKindOfClass:[DBMetadata class]]) {
        
        DBMetadata *metadata = results[0];
        //check if saved for offline use
        if(metadata.localPath != nil && metadata.localPath.length != 0) {
            
            //offline use!
            NSURL *localURL = [NSURL URLWithString:metadata.localPath relativeToURL:nil];
            //for now ---..
            [self.delegate restClient:self loadedMediaStreamUrl:localURL expiration:nil path:path];
        }
    }
    
    //locale
    NSDictionary *parameters = @{
        @"access_token": self.session.accessToken
    };
    //Build URL
    NSString *urlString = [DBRestClient urlForEndpoint:[NSString stringWithFormat:@"media/auto/%@", path] content:NO];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //AFNetworking make HTTP request
    self.reqOpManager.responseSerializer = [AFJSONResponseSerializer serializer];
    [self.reqOpManager GET:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        //Inform delegate, if any
        if(self.delegate){
            NSError *error = [NSError errorWithDomain:[self.class description] code:2 userInfo:nil];
            if(responseObject == nil){
                if([self.delegate respondsToSelector:@selector(restClient:loadMediaStreamUrlFailedWithError:path:)]){
                    [self.delegate restClient:self loadMediaStreamUrlFailedWithError:error path:path];
                }
            }else{
                if([self.delegate respondsToSelector:@selector(restClient:loadedMediaStreamUrl:expiration:path:)]){
                    NSDictionary *jsonDict = (NSDictionary *)responseObject;
                    NSArray *keys = jsonDict.allKeys;
                    
                    //Unpack response
                    if([keys containsObject:kJsonUrlKey] && [keys containsObject:kJsonExpiresKey]){
                        NSURL *url = [NSURL URLWithString:jsonDict[kJsonUrlKey]];
                        NSDate *expires = [NSDate dateFromDropboxString:jsonDict[kJsonExpiresKey]];
                        [self.delegate restClient:self loadedMediaStreamUrl:url expiration:expires path:path];
                    }else{
                        if([self.delegate respondsToSelector:@selector(restClient:loadMediaStreamUrlFailedWithError:path:)]){
                            [self.delegate restClient:self loadMediaStreamUrlFailedWithError:error path:path];
                        }
                    }
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(restClient:loadMediaStreamUrlFailedWithError:path:)]){
            [self.delegate restClient:self loadMediaStreamUrlFailedWithError:error path:path];
        }
    }];
    
}

- (void)downloadFile:(NSString *)path {

    //check if already downloading
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"path == %@", path];
    NSArray *results = [DBMetadata fetchMetadataWithPredicate:pred inContext:[DBCoreDataManager mainContext]];
    __block DBMetadata *metadata = nil;
    if(results > 0 && [results[0] isKindOfClass:[DBMetadata class]]) {
        
        metadata = results[0];
        //check if saved for offline use
        if(metadata.isDownloading)
            return;
        else {
            
            metadata.isDownloading = YES;
            [DBCoreDataManager saveMainContext];
        }
    }

    NSDictionary *parameters =
        @{
          @"access_token": self.session.accessToken
        };
        
    //Build request URL
    NSString *urlString = [DBRestClient urlForEndpoint:[NSString stringWithFormat:@"files/auto/%@", path] content:YES];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    self.reqOpManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    //AFNetworking to make HTTP request
    [self.reqOpManager GET:urlString parameters:parameters success:^(AFHTTPRequestOperation *operation, id responseObject) {
            
        //Inform delegate, save in cache
        if(self.delegate){
            if(responseObject == nil){
                if([self.delegate respondsToSelector:@selector(restClient:downloadFileFailedWithError:path:)]){
                    
                    if (metadata != nil) {
                        metadata.isDownloading = NO;
                        [DBCoreDataManager saveMainContext];
                    }
                    
                    NSError *error = [NSError errorWithDomain:[self.class description] code:3 userInfo:nil];
                    [self.delegate restClient:self downloadFileFailedWithError:error path:path];
                }
            }else{
                if([self.delegate respondsToSelector:@selector(restClient:downloadedFileTo:path:)]){
                    NSData *data = responseObject;
                    //TODO: async
                    
                    //save file
                    
                    [self saveDownload:data path:path completion:^(NSString *localPath, NSError *error) {
                       
                        if (metadata != nil) {
                            metadata.isDownloading = NO;
                            metadata.localPath = localPath;
                            [DBCoreDataManager saveMainContext];
                        }
                        
                        if(!error)
                            [self.delegate restClient:self downloadedFileTo:localPath path:path];
                        
                        else if([self.delegate respondsToSelector:@selector(restClient:downloadFileFailedWithError:path:)])
                            [self.delegate restClient:self downloadFileFailedWithError:error path:path];
                    }];
                }
            }
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if(self.delegate && [self.delegate respondsToSelector:@selector(restClient:downloadFileFailedWithError:path:)]){
            
            if (metadata != nil) {
                metadata.isDownloading = NO;
                [DBCoreDataManager saveMainContext];
            }
            
            NSError *error = [NSError errorWithDomain:[self.class description] code:4 userInfo:nil];
            [self.delegate restClient:self downloadFileFailedWithError:error path:path];
        }
    }];
}

- (void)saveDownload:(NSData *)data path:(NSString *)path completion:(void(^)(NSString *localPath, NSError *error))completion {
    
    //make folder if it doesnt exist
    NSError *dirError = nil;
    
    NSString *dirPath = [[self applicationDocumentsDirectory].path
                      stringByAppendingPathComponent:@"Downloads"];
    
    [[NSFileManager defaultManager] createDirectoryAtPath:dirPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&dirError];
    if (dirError)
        completion(nil, dirError);
    
    //save file
    
    
    //timestamp  + original filename
    
    NSString *timestamp = @([[NSDate date] timeIntervalSince1970]).stringValue;
    NSString *filename = [timestamp stringByAppendingString:path.lastPathComponent];
    NSString *filePath = [dirPath stringByAppendingPathComponent:filename];
    NSError *writeError = nil;
    
    [data writeToFile:filePath options:NSDataWritingAtomic error:&writeError];
    
    if (writeError)
        completion(nil, writeError);
    
    completion(filePath, nil);
}

//Builds URL to ask for media stream URL
+ (NSString *)urlForEndpoint:(NSString *)endpoint content:(BOOL)isContent {
    return [NSString stringWithFormat:@"%@%@", isContent?kBaseContentUrl:kBaseRestUrl, endpoint];
}

/**
 Returns the URL to the application's Documents directory.
 */
- (NSURL *)applicationDocumentsDirectory {
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

@end
