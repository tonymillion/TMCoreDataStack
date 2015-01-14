//
//  NSManagedObjectContext+helpers.h
//  Pods
//
//  Created by Tony Million on 14/01/2015.
//
//

#import <CoreData/CoreData.h>

@interface NSManagedObjectContext (helpers)

-(BOOL)save;
-(void)recursiveSave;

-(void)observeChangesFromParent:(BOOL)observe;


-(void)performBlockAndSave:(void (^)(NSManagedObjectContext *context))block;
-(void)performBlockAndWaitAndSave:(void (^)(NSManagedObjectContext *context))block;

@end
