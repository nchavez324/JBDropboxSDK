//
//  DBToolBelt.h
//  
//
//  Created by Nick Chavez on 11/1/14.
//
//

#import <Foundation/Foundation.h>

@interface DBToolBelt : NSObject

+ (DBToolBelt *)sharedInstance;
- (NSBundle *)internalBundle;

@end
