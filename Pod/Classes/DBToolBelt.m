//
//  DBToolBelt.m
//
//
//  Created by Nick Chavez on 11/1/14.
//
//

#import <UIKit/UIKit.h>

#import "DBToolBelt.h"

static DBToolBelt *_sharedBelt;

@interface DBToolBelt ()

@property (strong, nonatomic) NSBundle *mInternalBundle;

@end

@implementation DBToolBelt

+ (DBToolBelt *)sharedInstance {
    
    if(!_sharedBelt)
        _sharedBelt = [[DBToolBelt alloc] init];
    
    return _sharedBelt;
}

- (NSBundle *)internalBundle {
    
    if(self.mInternalBundle)
        return self.mInternalBundle;
    
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[[NSBundle mainBundle] bundlePath] error:NULL];
    
    for (NSString *fileName in files) {
        
        NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
        NSURL *url = [NSURL fileURLWithPath:path];
        
        if([[url lastPathComponent] isEqual:@"JBDropboxSDK.bundle"]){
            
            self.mInternalBundle = [NSBundle bundleWithPath:url.path];
        }
    }
    
    return self.mInternalBundle;
}

@end
