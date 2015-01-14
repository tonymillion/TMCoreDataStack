//
//  ADCoreDataStack.h
//  adventures
//
//  Created by Tony Million on 6/27/14.
//  Copyright (c) 2014 OmniTyke. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

#if DEBUG
#	define CDLog(_format, ...) NSLog(_format, ##__VA_ARGS__)
#else
#	define CDLog(_format, ...)
#endif

#import "NSManagedObject+helpers.h"
#import "NSManagedObject+importing.h"
#import "NSManagedObjectContext+helpers.h"

@interface TMCoreDataStack : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext          *backgroundSaveObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectContext          *mainThreadObjectContext;

@property (readonly, strong, nonatomic) NSManagedObjectModel            *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator    *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSPersistentStore               *persistentStore;

-(id)initWithManagedObjectModelName:(NSString*)momName databaseName:(NSString*)databaseName canDeleteOnFail:(BOOL)deletable;
-(id)initWithManagedObjectModel:(NSManagedObjectModel*)model databaseName:(NSString*)databaseName canDeleteOnFail:(BOOL)deletable;

-(BOOL)removeDatabaseWithName:(NSString*)databaseName error:(NSError **)error;

@end
