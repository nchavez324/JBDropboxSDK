//
//  DBMetadata.h
//  Jukeboxx
//
//  Created by Nick Chavez on 6/29/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/*
 Core Data NSManagedObject subclass for Dropbox metadata
 
 Can be complete/not complete -- has contents or not
 This is the difference between receving some info
 about a file/folder from inside another metadata's contents call
 or getting more detailed info on this one
 */

@class DBMetadata;

@interface DBMetadata : NSManagedObject

+ (DBMetadata *)insertMetadataWithJSON:(id)JSON inContext:(NSManagedObjectContext *)context;
+ (DBMetadata *)fetchMetadataCompleteWithPath:(NSString *)path inContext:(NSManagedObjectContext *)context;
+ (NSArray *)fetchMetadataWithPath:(NSString *)path withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context;

@property (nonatomic) int32_t bytes;
@property (nonatomic, retain) NSString * filename;
@property (nonatomic, retain) NSString * icon;
@property (nonatomic) BOOL completed;
@property (nonatomic) BOOL isDirectory;
@property (nonatomic) NSTimeInterval modified;
@property (nonatomic, retain) NSString * path;
@property (nonatomic, retain) NSString * rev;
@property (nonatomic, retain) NSString * root;
@property (nonatomic, retain) NSString * size;
@property (nonatomic) BOOL thumbExists;
@property (nonatomic, retain) DBMetadata *parent;

/**
 FOLDER PROPERTIES
 */
@property (nonatomic, retain) NSString * hash_db;
@property (nonatomic, retain) NSSet *contents;

/**
 FILE PROPERTIES
 */
@property (nonatomic, retain) NSString * mimeType;
@property (nonatomic) NSTimeInterval clientModified;

@end

@interface DBMetadata (CoreDataGeneratedAccessors)

- (void)addContentsObject:(DBMetadata *)value;
- (void)removeContentsObject:(DBMetadata *)value;
- (void)addContents:(NSSet *)values;
- (void)removeContents:(NSSet *)values;

- (NSArray *)arrayFromContents;

@end
