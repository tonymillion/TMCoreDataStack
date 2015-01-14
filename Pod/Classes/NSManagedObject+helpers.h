//
//  NSManagedObject+helpers.h
//  Pods
//
//  Created by Tony Million on 14/01/2015.
//
//

#import <CoreData/CoreData.h>

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
