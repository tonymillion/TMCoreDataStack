//
//  ADCoreDataStack.m
//  adventures
//
//  Created by Tony Million on 6/27/14.
//  Copyright (c) 2014 OmniTyke. All rights reserved.
//
#import <UIKit/UIKit.h>
#import "TMCoreDataStack.h"

@interface TMCoreDataStack ()

@property(assign, nonatomic) BOOL canDeleteOnFail;
@property(assign, nonatomic) BOOL isCacheData;

@end

@implementation TMCoreDataStack

-(BOOL)removeDatabaseWithName:(NSString*)databaseName error:(NSError **)error
{
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:databaseName];

    return [[NSFileManager defaultManager] removeItemAtURL:storeURL
                                                     error:nil];
}

-(void)setupWithManagedObjectModel:(NSManagedObjectModel *)mom databaseName:(NSString *)databaseName
{
    NSError *error = nil;

    NSURL *storeURL = nil;

    if(_isCacheData)
    {
        storeURL = [self applicationSupportDirectory];
        storeURL = [storeURL URLByAppendingPathComponent:databaseName];
    }
    else
    {
        storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:databaseName];
    }

    // clear the persistent Store Coordinator
    _persistentStoreCoordinator = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];


    _persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                 configuration:nil
                                                                           URL:storeURL
                                                                       options:@{NSMigratePersistentStoresAutomaticallyOption:@YES,
                                                                                 NSInferMappingModelAutomaticallyOption:@YES,
                                                                                 NSPersistentStoreTimeoutOption: @(4)}
                                                                         error:&error];
    if(_persistentStore == nil)
    {
        if(self.canDeleteOnFail)
        {
            // there was an error creating the persistent store, try deleting it and recreating the file
            [[NSFileManager defaultManager] removeItemAtURL:storeURL
                                                      error:nil];

            _persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType
                                                                         configuration:nil
                                                                                   URL:storeURL
                                                                               options:@{NSMigratePersistentStoresAutomaticallyOption:@YES,
                                                                                         NSInferMappingModelAutomaticallyOption:@YES,
                                                                                         NSPersistentStoreTimeoutOption: @(4)}
                                                                                 error:&error];
            if(!_persistentStore)
            {
                // Ok we couldn't delete / recreate the file, lets create an IN MEMORY store
                _persistentStore = [_persistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                                             configuration:nil
                                                                                       URL:nil
                                                                                   options:nil
                                                                                     error:&error];
                if(!_persistentStore)
                {
                    // ok SRSLY we are fucked
                }
            }
        }
    }

    //TODO: create this dynamically
    _backgroundSaveObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_backgroundSaveObjectContext setPersistentStoreCoordinator:_persistentStoreCoordinator];
    [_backgroundSaveObjectContext setStalenessInterval:0];

    //TODO: also create this dynamically
    _mainThreadObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_mainThreadObjectContext setParentContext:_backgroundSaveObjectContext];
    [_mainThreadObjectContext setStalenessInterval:0];
}

-(id)initWithManagedObjectModelName:(NSString*)momName databaseName:(NSString*)databaseName canDeleteOnFail:(BOOL)deletable
{
    self = [super init];
    if(self)
    {
        NSURL *modelURL = [[NSBundle mainBundle] URLForResource:momName
                                                  withExtension:@"momd"];
        _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];

        _canDeleteOnFail = deletable;
        if(deletable)
            _isCacheData = YES;


        [self setupWithManagedObjectModel:_managedObjectModel databaseName:databaseName];
    }
    return self;
}

-(id)initWithManagedObjectModel:(NSManagedObjectModel*)model databaseName:(NSString*)databaseName canDeleteOnFail:(BOOL)deletable
{
    self = [super init];
    if(self)
    {
        _managedObjectModel = model;
        _canDeleteOnFail = deletable;
        if(deletable)
            _isCacheData = YES;

        [self setupWithManagedObjectModel:_managedObjectModel databaseName:databaseName];
    }
    return self;
}



#pragma mark - helpers

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

// Returns the URL to the application's Documents directory.
-(NSURL *)supportFilesDirectoryURL
{
    NSURL       *result                         = nil;
    NSURL       *applicationSupportDirectoryURL = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSString    *bundleName                     = [[NSBundle bundleForClass:[self class]] bundleIdentifier];

    result = [applicationSupportDirectoryURL URLByAppendingPathComponent:bundleName
                                                             isDirectory:YES];

    return result;
}

-(NSURL *)applicationSupportDirectory
{
    NSError             *error                  = nil;
    NSFileCoordinator   *coordinator            = nil;
    __block BOOL        didCreateDirectory      = NO;
    NSURL               *supportDirectoryURL    = [self supportFilesDirectoryURL];
    NSURL               *storeDirectoryURL      = [supportDirectoryURL URLByAppendingPathComponent:@"ApplicationData" isDirectory:YES];

    coordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];

    [coordinator coordinateWritingItemAtURL:storeDirectoryURL
                                    options:NSFileCoordinatorWritingForDeleting
                                      error:&error
                                 byAccessor:^(NSURL *writingURL)
    {
        NSFileManager   *fileManager    = [[NSFileManager alloc] init];
        NSError         *fileError      = nil;

        if (![fileManager createDirectoryAtURL:writingURL
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:&fileError])
        {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                // Handle the error
            }];
        }
        else
        {
            // Setting NSURLIsExcludedFromBackupKey on the directory will exclude all items in this directory
            // from backups. It will also prevent them from being purged in low space conditions. Because of this,
            // the files inside this directory should be purged by the application.
            [writingURL setResourceValue:@YES
                                  forKey:NSURLIsExcludedFromBackupKey
                                   error:&fileError];
            didCreateDirectory = YES;
        }
    }];

    // See NSFileCoordinator.h for an explanation.
    if (didCreateDirectory == NO)
    {
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            // Handle the error.
        }];
    }

    return storeDirectoryURL;
}

#pragma mark - changeObservation

-(void)setMainThreadObservesChanges:(BOOL)mainThreadObservesChanges
{
    _mainThreadObservesChanges = mainThreadObservesChanges;
    [_mainThreadObjectContext observeChangesFromParent:self.mainThreadObservesChanges];
}

@end
