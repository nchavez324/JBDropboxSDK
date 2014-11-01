//
//  DBAuthenticationDelegate.h
//  JBDropboxSDK
//
//  Created by Nick Chavez on 6/11/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol DBAuthenticationDelegate <NSObject>

@required

//For listeners on authentication success/failure
- (void)authenticationViewControllerError:(NSError *)error;

- (void)authenticationViewControllerSuccess:(NSString *)accessToken uid:(NSString *)uid;

@end
