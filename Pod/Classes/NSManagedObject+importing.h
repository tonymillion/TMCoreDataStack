//
//  NSManagedObject+importing.h
//  tapkast
//
//  Created by Tony Million on 02/01/2015.
//  Copyright (c) 2015 Omnityke. All rights reserved.
//

@import CoreData;

@interface NSManagedObject (importing)

// This assumes your object will have a unique identifier
// override this in your NSManagedObject subclass to return the string
// identifier of your primary key e.g. @"id" or @"userid" etc.
//
// objectWithID will call this so it can find the object
//

+(NSString*)identityKey;

+(instancetype)importFromDictionary:(NSDictionary*)dict inContext:(NSManagedObjectContext*)context;
+(NSArray*)importFromArray:(NSArray*)array inContext:(NSManagedObjectContext*)context;

+(instancetype)objectWithID:(NSString*)id inContext:(NSManagedObjectContext*)context;

@end
