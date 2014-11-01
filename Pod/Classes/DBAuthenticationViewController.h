//
//  DBAuthenticationViewController.h
//  JBDropboxSDK
//
//  Created by Nick Chavez on 6/11/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DBAuthenticationDelegate.h"

/*
 Lets user authenticate with Dropbox, via UIWebView
 */

@interface DBAuthenticationViewController : UIViewController <UIWebViewDelegate>

@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (weak, nonatomic) id<DBAuthenticationDelegate> delegate;

@end
