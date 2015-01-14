//
//  NSManagedObject+helpers.m
//  Pods
//
//  Created by Tony Million on 14/01/2015.
//
//

#import "NSManagedObject+helpers.h"
#import "TMCoreDataStack.h"

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
        CDLog(@"A Coredata exception happened - this is not good and probably iClouds fault :(");
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
