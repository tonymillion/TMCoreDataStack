//
//  NSManagedObjectContext+helpers.m
//  Pods
//
//  Created by Tony Million on 14/01/2015.
//
//

#import "NSManagedObjectContext+helpers.h"
#import "TMCoreDataStack.h"

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
