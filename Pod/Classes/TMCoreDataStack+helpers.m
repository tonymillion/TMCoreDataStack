//
//  NSManagedObject+helpers.m
//
//  Created by Tony Million on 6/17/14.
//  Copyright (c) 2014 OmniTyke. All rights reserved.
//
#import <UIKit/UIKit.h>

#import "TMCoreDataStack+helpers.h"


#if DEBUG
#	define CDLog(_format, ...) NSLog(_format, ##__VA_ARGS__)
#else
#	define CDLog(_format, ...)
#endif


#pragma mark - NSManagedObject Helpers

@implementation NSManagedObject (helpers)

+(NSString *)entityName
{
    return NSStringFromClass(self);
}

+(NSEntityDescription *)entityDescriptionInContext:(NSManagedObjectContext *)context
{
    if(!context)
        return nil;

    NSString *entityName = [self entityName];

    NSEntityDescription * entDesc = nil;

    @try {
        entDesc =  [NSEntityDescription entityForName:entityName
                               inManagedObjectContext:context];
    }
    @catch (NSException *exception) {
        //TMCDLog(@"A Coredata exception happened - this is not good and probably iClouds fault :(");
    }

    return entDesc;
}

#pragma mark - creating

+(instancetype)createInContext:(NSManagedObjectContext *)context
{
    return [NSEntityDescription insertNewObjectForEntityForName:[self entityName]
                                         inManagedObjectContext:context];
}

-(void)deleteManagedObject
{
    [self.managedObjectContext performBlockAndWait:^{
        [self.managedObjectContext deleteObject:self];
    }];
}

#pragma mark - context<>context

-(instancetype)inContext:(NSManagedObjectContext *)otherContext
{
    NSError *error = nil;

    if([[self objectID] isTemporaryID])
    {
        BOOL success = [self.managedObjectContext obtainPermanentIDsForObjects:@[self]
                                                                         error:&error];
        if (!success && error)
        {
            CDLog(@"obtainPermanentIDsForObjects - error: %@", error);
        }
    }

    NSManagedObject *inContext = [otherContext existingObjectWithID:[self objectID]
                                                              error:&error];

    if(!inContext)
    {
        CDLog(@"inContext fails: %@", error);
    }

    return inContext;
}


#pragma mark - fetching

+(NSFetchRequest *)createFetchRequest
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];

    return request;
}


+(NSFetchRequest *)requestWithPredicate:(NSPredicate *)predicate
                               sortedBy:(NSString *)sortTerm
{
    NSFetchRequest *request = [self createFetchRequest];

    if(predicate)
    {
        [request setPredicate:predicate];
    }

    if(sortTerm)
    {
        NSMutableArray* sortDescriptors = [[NSMutableArray alloc] init];
        NSArray* sortKeys = [sortTerm componentsSeparatedByString:@","];
        for(NSString* sortKey in sortKeys)
        {
            BOOL ascending = YES;

            // remove any leading whitespace
            NSString * theKey = [sortKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];

            if ([theKey hasPrefix:@"+"])
            {
                ascending = YES;
                theKey = [theKey substringFromIndex:1];
            }
            else if([theKey hasPrefix:@"-"])
            {
                ascending = NO;
                theKey = [theKey substringFromIndex:1];
            }
            else
            {
                ascending = NO;
            }

            NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:theKey
                                                                           ascending:ascending];
            [sortDescriptors addObject:sortDescriptor];
        }

        [request setSortDescriptors:sortDescriptors];
    }

    [request setFetchBatchSize:20];

    return request;
}

+(NSArray*)allObjectsInContext:(NSManagedObjectContext *)context
{
    __block NSError * err = nil;
    __block NSArray * results = nil;

    [context performBlockAndWait:^{
        results = [context executeFetchRequest:[self createFetchRequest]
                                                   error:&err];
    }];

    if(err)
    {
        return nil;
    }

    return results;
}

+(NSArray*)allObjectsWithPredicate:(NSPredicate *)predicate
                          sortedBy:(NSString *)sortTerm
                         inContext:(NSManagedObjectContext *)context
{
    __block NSError * err = nil;
    __block NSArray * results = nil;

    [context performBlockAndWait:^{
        NSFetchRequest * req = [self requestWithPredicate:predicate
                                                 sortedBy:sortTerm];

        results = [context executeFetchRequest:req
                                         error:&err];
    }];

    if(err)
    {
        return nil;
    }
    return results;
}

+(instancetype)firstObjectWithPredicate:(NSPredicate *)predicate
                               sortedBy:(NSString *)sortTerm
                              inContext:(NSManagedObjectContext *)context
{
    __block NSError * err = nil;
    __block NSArray * results = nil;


    NSFetchRequest * req = [[self class] requestWithPredicate:predicate
                                                     sortedBy:sortTerm];

    [req setFetchLimit:1];


    [context performBlockAndWait:^{
        results = [context executeFetchRequest:req
                                         error:&err];
    }];

    if(err)
    {
        return nil;
    }

    return [results firstObject];
}



#pragma mark - Obliteration

+(void)truncateInContext:(NSManagedObjectContext*)context
{
    NSFetchRequest * freq = [self createFetchRequest];
    freq.includesPropertyValues = NO;
    freq.includesSubentities    = NO;
    freq.returnsObjectsAsFaults = YES;


    [context performBlockAndWait:^{
        NSError * error = nil;
        NSArray * objects = [context executeFetchRequest:freq
                                                   error:&error];
        //error handling goes here
        for (NSManagedObject * obj in objects)
        {
            [context deleteObject:obj];
        }
    }];
}

#pragma mark - helpers

-(NSArray*)allKeys
{
    // returns an array of strings of the keys this property supports
    NSDictionary *attributes = [[self entity] attributesByName];
    return attributes.allKeys;
}

// given a dictionary and a key, if the dictionary and the NSManagedObject both support/contain
// said key then compare them, and copy if they are different
// in addition if the value in the NSDictionary is NSNull, set the corresponding value on the
// NSManagedObject to NIL
-(void)copyKey:(NSString*)key fromDict:(NSDictionary*)dict
{
    [self copyKey:key fromDict:dict deleteMissing:YES];
}

-(void)copyKey:(NSString*)key fromDict:(NSDictionary*)dict deleteMissing:(BOOL)deleteMissing
{
    if(![self.allKeys containsObject:key])
    {
        return;
    }

    id val = [dict objectForKey:key];

    if(val && ![val isKindOfClass:[NSNull class]])
    {
        id ourval = [self valueForKey:key];

        if(![ourval isEqual:val])
        {
            //CDLog(@"Setting %@ to %@", key, val);
            [self setValue:val
                    forKey:key];
        }
    }
    else if ([val isKindOfClass:[NSNull class]])
    {
        //CDLog(@"Setting %@ to %@", key, val);
        [self setValue:nil
                forKey:key];
    }
    else if(deleteMissing)
    {
        // if the key was not in the dictionary, then we should set the NSManagedObject
        // version to nil
        [self setValue:nil
                forKey:key];
    }
}


@end


#pragma mark - NSManagedObjectContext Helpers


@implementation NSManagedObjectContext (helpers)

#pragma mark - Saving Helpers
-(BOOL)save
{
    __block BOOL result = YES;

    [self performBlockAndWait:^{
        NSError* error = nil;

        if(![self save:&error])
        {

#ifdef DEBUG
            //ERROR
            CDLog(@"Failed to save to data store: %@", [error localizedDescription]);
            NSArray* detailedErrors = [[error userInfo] objectForKey:NSDetailedErrorsKey];
            if(detailedErrors != nil && [detailedErrors count] > 0) {
                for(NSError* detailedError in detailedErrors) {
                    CDLog(@"  DetailedError: %@", [detailedError userInfo]);
                }
            }
            else {
                CDLog(@"  %@", [error userInfo]);
            }
#endif

            result = NO;
        }

    }];

    return result;
}

-(void)recursiveSave
{
    [self performBlockAndWait:^{

        if([self hasChanges])
        {
            if(![self save])
            {
                //An error happened :(
            }
            else
            {
                if(self.parentContext)
                {
                    [self.parentContext recursiveSave];
                }
            }
        }
    }];
}

#pragma mark - update helpers

-(void)performBlockAndSave:(void (^)(NSManagedObjectContext *context))block
{
    [self performBlock:^{
        block(self);
        [self recursiveSave];
    }];
}

-(void)performBlockAndWaitAndSave:(void (^)(NSManagedObjectContext *context))block
{
    [self performBlockAndWait:^{
        block(self);
        [self recursiveSave];
    }];
}

#pragma mark - changes helpers

-(void)observeChangesFromParent:(BOOL)observe
{
    if(observe)
    {
        // This will pull down changes made into the parent context into this context.
        // its a bad idea to use this on the main thread as new objects you save will bounce up
        // to the save context and then be reflected back down, this may cause "duplicate" objects to
        // appear in the main thread context - upon restarting the app the duplicates will disappear
        // this is because the save context gives the 'new' objects a permenent ID which is not
        // reflected into the main thread contextx temporary id
        // I have no idea why.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(contextDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.parentContext];
    }
    else
    {
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    }
}

- (void)contextDidSave:(NSNotification *)notification
{
    NSManagedObjectContext * notificationContext = notification.object;

    if(notificationContext == self)
    {
        // we dont need to run on ourselves
        return;
    }

    // only do this if the notification came from our direct parent please
    // we need this as if you have more than one TMCoreDataStack instance it will
    // seriously mess up trying to import from another store!
    if( notification.object == self.parentContext )
    {
        [self performBlock:^{
            //CDLog(@"Merging changes from parent: %@", notification);
            [self mergeChangesFromContextDidSaveNotification:notification];
        }];
    }
}

@end