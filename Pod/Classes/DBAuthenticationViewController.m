//
//  DBAuthenticationViewController.m
//  JBDropboxSDK
//
//  Created by Nick Chavez on 6/11/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import "DBAuthenticationViewController.h"

#import "DBSession.h"

@interface DBAuthenticationViewController ()

@property (strong, nonatomic) UIActivityIndicatorView *loadingView;

@end

@implementation DBAuthenticationViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    self.loadingView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    [self.loadingView startAnimating];
    
    UIFont *navFont = [UIFont boldSystemFontOfSize:17];
    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(self.loadingView.frame.size.width * 2, 0, 150, 50)];
    [title setFont:navFont];
    [title setText:@"Sign In to Dropbox"];
    [title sizeToFit];
    
    UIView *titleView = [[UIView alloc] initWithFrame:CGRectMake(self.loadingView.frame.origin.x, title.frame.origin.y, title.frame.size.width + self.loadingView.frame.size.width * 3, title.frame.size.height)];
    
    [titleView addSubview:title];
    [titleView addSubview:self.loadingView];
    
    [self.navigationItem setTitleView:titleView];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
    [self.navigationItem setRightBarButtonItem:cancelButton];
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.loadingView startAnimating];
    [self.webView loadRequest:[[DBSession sharedSession] authRequest]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.loadingView stopAnimating];
    
    NSURL *url = webView.request.URL;
    NSString *urlStr = [url absoluteString];
    
    //Check if authentication has happened
    if([urlStr hasPrefix:kRedirectUrl]){
        //have been redirected!! :D
        NSArray *comps = [urlStr componentsSeparatedByString:@"#"];
        if(comps.count > 1){
            NSString *rawParams = comps[1];
            //get access_token, uid, and in future, state
            NSArray *kvs = [rawParams componentsSeparatedByString:@"&"];
            NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
            for (NSString *kv in kvs) {
                NSArray *a = [kv componentsSeparatedByString:@"="];
                if(a.count == 2){
                    params[a[0]] = a[1];
                }
            }
            NSString *accessToken, *uid;
            if(params[@"error"] != nil){
                //TODO: make constants for errors
                NSError *error = [NSError errorWithDomain:@"com.nickchavez.Jukeboxx" code:1 userInfo:@{}];
                [self reportError:error];
            }else{
                accessToken = params[@"access_token"];
                uid = params[@"uid"];
                if(accessToken == nil || uid == nil){
                    NSError *error = [NSError errorWithDomain:@"com.nickchavez.Jukeboxx" code:2 userInfo:@{}];
                    [self reportError:error];
                }else{
                    //Success!!
                    [self reportSuccess:accessToken uid:uid];
                }
            }
        }else{
            NSError *error = [NSError errorWithDomain:@"com.nickchavez.Jukeboxx" code:3 userInfo:@{}];
            [self reportError:error];
        }

    }else if([urlStr hasPrefix:kAuthorizeBaseUrl]){
        //waiting for user to sign in...
    }else{
        //Not at redirect or auth url wtf?
        NSError *error = [NSError errorWithDomain:@"com.nickchavez.Jukeboxx" code:4 userInfo:@{}];
        [self reportError:error];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [self.loadingView startAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [self.loadingView stopAnimating];
    [self reportError:error];
}

- (void)reportError:(NSError *)error {
    if(self.delegate)
        [self.delegate authenticationViewControllerError:error];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)reportSuccess:(NSString *)accessToken uid:(NSString *)uid {
    if(self.delegate)
        [self.delegate authenticationViewControllerSuccess:accessToken uid:uid];
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelButtonPressed:(id)sender {
    [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
}


@end
