//
//  JBDropboxSDK.m
//  JBDropboxSDK
//
//  Created by Nick Chavez on 6/11/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import "DBSession.h"

#import "DBAuthenticationViewController.h"
#import "DBCoreDataManager.h"
#import "DBToolBelt.h"

NSString * const kDBRootDropbox   = @"Dropbox";
NSString * const kDBRootAppFolder = @"AppFolder";

NSString * const kAuthorizeBaseUrl = @"https://www.dropbox.com/1/oauth2/authorize";
NSString * const kRedirectUrl      = @"https://nchavez324.github.io/Jukeboxx/app/";

//Used to cache access token, UID
NSString * const kAccessTokenDefaultsKey = @"AccessToken";
NSString * const kUIDDefaultsKey          = @"UID";

BOOL const kShouldCheckDefaults = YES;

static DBSession *_sharedSession = nil;

@interface DBSession ()

@property (strong, nonatomic) NSString *appKey;
@property (strong, nonatomic) NSString *appSecret;
@property (strong, nonatomic) NSString *appRoot;

@property (strong, nonatomic) NSString *accessToken;
@property (strong, nonatomic) NSString *uid;

@property (assign, nonatomic) BOOL isLinked;

@end

@implementation DBSession

//Mimics actual Dropbox iOS SDK
- (id)initWithAppKey:(NSString *)appKey appSecret:(NSString *)appSecret root:(NSString *)appRoot {
    if(self = [super init]){
        if([DBSession isInputInvalid:appKey appSecret:appSecret root:appRoot])
            return nil;
        self.appKey = appKey;
        self.appSecret = appSecret;
        self.appRoot = appRoot;
        self.isLinked = false;
        
        [DBCoreDataManager setupSharedManager];
        
        //check if access token and uid are in userdefaults
        if(kShouldCheckDefaults)
            [self checkDefaults];
    }
    return self;
}

- (void)checkDefaults {
    //Check defaults for access token, UID
    NSString *accessToken = [[NSUserDefaults standardUserDefaults] objectForKey:kAccessTokenDefaultsKey];
    NSString *uid = [[NSUserDefaults standardUserDefaults] objectForKey:kUIDDefaultsKey];
    if(uid != nil && accessToken != nil){
        self.accessToken = accessToken;
        self.uid = uid;
        self.isLinked = YES;
    }
}

+ (BOOL)isInputInvalid:(NSString *)appKey appSecret:(NSString *)appSecret root:(NSString *)appRoot {
    return (appKey == nil || appKey.length == 0 || appSecret == nil || appSecret.length == 0);
}

+ (void)setSharedSession:(DBSession *)sharedSession {
    _sharedSession = sharedSession;
}

- (NSURLRequest *)authRequest {
    NSURL *baseUrl = [NSURL URLWithString:kAuthorizeBaseUrl];
    NSString *parameters = [NSString stringWithFormat:@"?response_type=token&client_id=%@&redirect_uri=%@", self.appKey, kRedirectUrl];
    //@TODO: Eventually add state parameter to prevent CSRF
    NSURLRequest *req = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:parameters relativeToURL:baseUrl]];
    return req;
}

+ (DBSession *)sharedSession {
    return _sharedSession;
}

- (BOOL)isLinked {
    return _isLinked;
}

- (void)linkFromController:(UIViewController *)viewController {
    //try to open a webview and then on success/error return to given controller
    
    self.authVC = [[DBAuthenticationViewController alloc] initWithNibName:NSStringFromClass([DBAuthenticationViewController class]) bundle:[[DBToolBelt sharedInstance] internalBundle]];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:self.authVC];
    
    self.authVC.delegate = self;
    [viewController presentViewController:navVC animated:YES completion:nil];
}

- (void)authenticationViewControllerSuccess:(NSString *)accessToken uid:(NSString *)uid {
    self.accessToken = accessToken;
    self.uid = uid;
    self.isLinked = YES;
    
    [[NSUserDefaults standardUserDefaults] setObject:accessToken forKey:kAccessTokenDefaultsKey];
    [[NSUserDefaults standardUserDefaults] setObject:uid forKey:kUIDDefaultsKey];
    
    [self.authVC.presentingViewController dismissViewControllerAnimated:YES completion:^{
        self.authVC = nil;
    }];
}
- (void)authenticationViewControllerError:(NSError *)error {
    NSLog(@"Yikes: %@", error.description);
    self.isLinked = NO;
    [self.authVC.presentingViewController dismissViewControllerAnimated:YES completion:^{
        self.authVC = nil;
    }];
    
}

- (NSString *)accessToken {
    return _accessToken;
}

- (void)saveCache {
    
    [DBCoreDataManager saveMainContext];
}


@end
