//
//  NSManagedObject+importing.m
//  tapkast
//
//  Created by Tony Million on 02/01/2015.
//  Copyright (c) 2015 Omnityke. All rights reserved.
//

#import "NSManagedObject+importing.h"
#import "NSManagedObject+helpers.h"

@implementation NSManagedObject (importing)

+(instancetype)importFromDictionary:(NSDictionary*)dict inContext:(NSManagedObjectContext*)context
{
    return nil;
}

+(NSArray*)importFromArray:(NSArray*)array inContext:(NSManagedObjectContext*)context
{
    NSMutableArray * returnArray = [NSMutableArray arrayWithCapacity:array.count];
    for (NSDictionary * dict in array) {

        id imported = [self importFromDictionary:dict
                                       inContext:context];
        if (imported) {
            [returnArray addObject:imported];
        }
    }
    return returnArray;
}

+(NSString*)identityKey
{
    return @"id";
}

+(instancetype)objectWithID:(NSString*)objectid inContext:(NSManagedObjectContext*)context
{
    __block id retobj = nil;

    [context performBlockAndWait:^{
        // @"%K == %@", [self identityKey], objectid
        NSString * identity = [self identityKey];
        retobj = [self firstObjectWithPredicate:[NSPredicate predicateWithFormat:@"%K == %@", identity, objectid]
                                       sortedBy:nil
                                      inContext:context];
    }];

    return retobj;
}

@end
