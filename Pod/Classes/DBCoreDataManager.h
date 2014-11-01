//
//  DBCoreDataManager.h
//  Jukeboxx
//
//  Created by Nick Chavez on 6/29/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface DBCoreDataManager : NSObject

+ (void)setupSharedManager;

+ (NSManagedObjectContext *)mainContext;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+ (void)saveMainContext;

- (NSURL *)applicationDocumentsDirectory;

@end
