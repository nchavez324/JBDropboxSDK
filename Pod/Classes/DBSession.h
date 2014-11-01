//
//  JBDropboxSDK.h
//  JBDropboxSDK
//
//  Created by Nick Chavez on 6/11/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

/*
Object to handle a user signing into
 the Dropbox service and authenticating
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "DBAuthenticationDelegate.h"

//Root folder -- API reccomends using 'auto' however
extern NSString * const kDBRootDropbox;
extern NSString * const kDBRootAppFolder;
extern NSString * const kAuthorizeBaseUrl;
extern NSString * const kRedirectUrl;

@class DBAuthenticationViewController;

@interface DBSession : NSObject <DBAuthenticationDelegate>

@property (strong, nonatomic) DBAuthenticationViewController *authVC;

- (id) initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret root:(NSString *)appRoot;

//If session is valid or linked
- (BOOL)isLinked;

- (void)linkFromController:(UIViewController *)viewController;

//For use in browser to authenticate
- (NSURLRequest *)authRequest;
- (NSString *)accessToken;

//Manually save session cache
- (void)saveCache;

//Set pseudo-global session
+ (void)setSharedSession:(DBSession *)sharedSession;
+ (DBSession *)sharedSession;

@end
