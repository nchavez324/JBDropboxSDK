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

- (void)initialize {
    self.reqOpManager = [AFHTTPRequestOperationManager manager];
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
        NSString *urlString = [DBRestClient urlForEndpoint:[NSString stringWithFormat:@"metadata/auto/%@", path]];
        urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        //AFNetworking to make HTTP request
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
    //locale
    NSDictionary *parameters = @{
        @"access_token": self.session.accessToken
    };
    //Build URL
    NSString *urlString = [DBRestClient urlForEndpoint:[NSString stringWithFormat:@"media/auto/%@", path]];
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    
    //AFNetworking make HTTP request
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

//Builds URL to ask for media stream URL
+ (NSString *)urlForEndpoint:(NSString *)endpoint {
    return [NSString stringWithFormat:@"%@%@", kBaseRestUrl, endpoint];
}

@end
