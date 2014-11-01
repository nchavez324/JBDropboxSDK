//
//  DBMetadata.m
//  Jukeboxx
//
//  Created by Nick Chavez on 6/29/14.
//  Copyright (c) 2014 Nick Chavez. All rights reserved.
//

#import "DBMetadata.h"
#import "NSDate+Dropbox.h"
#import "DBJsonKeys.h"
#import "DBCoreDataManager.h"

//Expensive, so keep one around
static NSDateFormatter *_dateFormatter;

@implementation DBMetadata

@dynamic bytes;
@dynamic filename;
@dynamic icon;
@dynamic completed;
@dynamic isDirectory;
@dynamic modified;
@dynamic path;
@dynamic rev;
@dynamic root;
@dynamic size;
@dynamic thumbExists;
@dynamic mimeType;
@dynamic clientModified;
@dynamic hash_db;
@dynamic contents;
@dynamic parent;

- (instancetype)initWithJSON:(id)JSON asSubMetadata:(BOOL)isSub insertIntoManagedObjectContext:(NSManagedObjectContext *)context {
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:NSStringFromClass([DBMetadata class]) inManagedObjectContext:context];
    if(self = [super initWithEntity:entityDesc insertIntoManagedObjectContext:context]){
        [self inflateWithJSON:JSON asSubMetadata:isSub];
    }
    return self;
}

- (void)inflateWithJSON:(id)JSON asSubMetadata:(BOOL)isSub {
    
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    NSArray *keys = jsonDict.allKeys;
    
    if([keys containsObject:kJsonBytesKey])
        self.bytes = (int32_t)[jsonDict[kJsonBytesKey] integerValue];
    
    if([keys containsObject:kJsonIsDirectoryKey])
        self.isDirectory = [jsonDict[kJsonIsDirectoryKey] boolValue];
    
    if([keys containsObject:kJsonHashKey])
        self.hash_db = jsonDict[kJsonHashKey];
    
    if([keys containsObject:kJsonIconKey])
        self.icon = jsonDict[kJsonIconKey];
    
    if([keys containsObject:kJsonPathKey])
        self.path = jsonDict[kJsonPathKey];
    
    if([keys containsObject:kJsonRootKey])
        self.root = jsonDict[kJsonRootKey];
    
    if([keys containsObject:kJsonSizeKey])
        self.size = jsonDict[kJsonSizeKey];
    
    if([keys containsObject:kJsonThumbExistsKey])
        self.thumbExists = [jsonDict[kJsonThumbExistsKey] boolValue];
    
    if([keys containsObject:kJsonRevKey])
        self.rev = jsonDict[kJsonRevKey];
    
    if([keys containsObject:kJsonFilenameKey])
        self.filename = jsonDict[kJsonFilenameKey];
    if(!self.filename && self.path){
        NSArray *components = [self.path componentsSeparatedByString:@"/"];
        if(components && components.count > 0)
            self.filename = components[components.count - 1];
    }
    
    if([keys containsObject:kJsonModifiedKey])
        self.modified = [NSDate dateFromDropboxString:jsonDict[kJsonModifiedKey]].timeIntervalSince1970;
    
    
    if([keys containsObject:kJsonMimeTypeKey])
        self.mimeType = jsonDict[kJsonMimeTypeKey];
    
    if([keys containsObject:kJsonClientModifiedKey])
        self.clientModified = [NSDate dateFromDropboxString:jsonDict[kJsonClientModifiedKey]].timeIntervalSince1970;
    
    if([keys containsObject:kJsonContentsKey]){
        NSArray *contents = jsonDict[kJsonContentsKey];
        NSMutableSet *subMetadata = [[NSMutableSet alloc] init];
        if(!contents || contents.count == 0){
            self.contents = nil;
        }else{
            for(id innerJson in contents){
                
                //Add incomplete metadata for contents
                DBMetadata *subMetadatum = [DBMetadata insertMetadataWithJSON:innerJson asSubMetadata:YES inContext:self.managedObjectContext];
                if(subMetadatum)
                    [subMetadata addObject:subMetadatum];
            }
            self.contents = subMetadata;
        }
    }else{
        if(!isSub)
            self.contents = nil;
    }
    
    //if all info is here
    if(!self.completed)
        self.completed = !isSub || !self.isDirectory;
}

+ (DBMetadata *)insertMetadataWithJSON:(id)JSON asSubMetadata:(BOOL)isSub inContext:(NSManagedObjectContext *)context {
    
    NSString *path = nil;
    NSDictionary *jsonDict = (NSDictionary *)JSON;
    if([jsonDict.allKeys containsObject:kJsonPathKey])
        path = jsonDict[kJsonPathKey];
    
    DBMetadata *metadata = nil;
    if(path){
        //Update existing metadata, if exists
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"path == %@", path];
        NSArray *metadatum = [DBMetadata fetchMetadataWithPath:path withPredicate:pred inContext:context];
        if(metadatum && metadatum.count > 0)
            metadata = metadatum[0];
        
        if(metadata){
            //Update record in database
            [metadata inflateWithJSON:JSON asSubMetadata:isSub];
        }else{
            //Insert into database
            metadata = [[DBMetadata alloc] initWithJSON:JSON asSubMetadata:isSub insertIntoManagedObjectContext:context];
        }
        
        //TODO: async
        [DBCoreDataManager saveMainContext];
        
    }else{
        NSLog(@"Error in %s, line %d ... got invalid JSON.", __func__, __LINE__);
    }
    
    return metadata;
}

+ (DBMetadata *)insertMetadataWithJSON:(id)JSON inContext:(NSManagedObjectContext *)context {
    return [DBMetadata insertMetadataWithJSON:JSON asSubMetadata:NO inContext:context];
}

+ (NSArray *)fetchMetadataWithPath:(NSString *)path withPredicate:(NSPredicate *)predicate inContext:(NSManagedObjectContext *)context {
    NSFetchRequest *fetchReq = [[NSFetchRequest alloc] init];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:NSStringFromClass([DBMetadata class]) inManagedObjectContext:context];
    [fetchReq setEntity:entityDesc];
    
    [fetchReq setPredicate:predicate];
    
    NSArray *fetched = nil;
    NSError *error = nil;
    fetched = [context executeFetchRequest:fetchReq error:&error];
    
    if(error){
        NSLog(@"Error in %s, line %d ... got %@", __func__, __LINE__, error.debugDescription);
    }
    
    return fetched;
}

//Ensures metadata is complete with contents
+ (DBMetadata *)fetchMetadataCompleteWithPath:(NSString *)path inContext:(NSManagedObjectContext *)context {
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"path == %@ && completed == YES", path];
    NSArray *metadatum = [DBMetadata fetchMetadataWithPath:path withPredicate:predicate inContext:context];
    if(metadatum && metadatum.count > 0)
        return metadatum[0];
    else
        return nil;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<DBMetadata>{\n\tisDir: %@\n\tpath: %@\n\tsize: %@\n\tmodified: %@\n\tcompleted: %@\n}", self.isDirectory?@"YES":@"NO", self.path, self.size, [NSDate dateWithTimeIntervalSince1970:self.modified], self.completed?@"YES":@"NO"];
}

- (NSArray *)arrayFromContents {
    //Set to array
    return [self.contents allObjects];
}

@end
