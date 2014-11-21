//
//  NSManagedObject+helpers.h
//
//  Created by Tony Million on 6/17/14.
//  Copyright (c) 2014 OmniTyke. All rights reserved.
//

#import <CoreData/CoreData.h>

#pragma mark - NSManagedObject Categories

@interface NSManagedObject (helpers)

+(NSString *)entityName;
+(instancetype)createInContext:(NSManagedObjectContext *)context;

-(void)deleteManagedObject;
-(instancetype)inContext:(NSManagedObjectContext *)otherContext;

+(NSFetchRequest *)createFetchRequest;
+(NSFetchRequest *)requestWithPredicate:(NSPredicate *)predicate
                               sortedBy:(NSString *)sortTerm;

+(NSArray*)allObjectsInContext:(NSManagedObjectContext *)context;

+(NSArray*)allObjectsWithPredicate:(NSPredicate *)predicate
                          sortedBy:(NSString *)sortTerm
                         inContext:(NSManagedObjectContext *)context;

+(instancetype)firstObjectWithPredicate:(NSPredicate *)predicate
                               sortedBy:(NSString *)sortTerm
                              inContext:(NSManagedObjectContext *)context;

+(void)truncateInContext:(NSManagedObjectContext*)context;


-(void)copyKey:(NSString*)key fromDict:(NSDictionary*)dict;
-(void)copyKey:(NSString*)key fromDict:(NSDictionary*)dict deleteMissing:(BOOL)deleteMissing;

@end



#pragma mark - NSManagedObjectContext Categories

@interface NSManagedObjectContext (helpers)

-(BOOL)save;
-(void)recursiveSave;

-(void)observeChangesFromParent:(BOOL)observe;


-(void)performBlockAndSave:(void (^)(NSManagedObjectContext *context))block;
-(void)performBlockAndWaitAndSave:(void (^)(NSManagedObjectContext *context))block;

@end