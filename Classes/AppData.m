//
//  AppData.m
//  ScenicRoute
//
//  Created by Seb on 10-12-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AppData.h"


@implementation AppData

@synthesize model, coordinator, documentsDirectory;

#pragma mark -
#pragma mark Initialization

- (id)initWithDocumentsDirectory:(NSString*)docsDirectory {
	if (self = [super init]) {
		documentsDirectory = [docsDirectory retain];
		model = nil;
		coordinator = nil;
	}
	return self;
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *)context {
    
    if (context != nil) {
        return context;
    }
    
	if (self.coordinator != nil) {
        context = [[NSManagedObjectContext alloc] init];
        [context setPersistentStoreCoordinator:self.coordinator];
    }
    return context;
}


/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created from the application's model.
 */
- (NSManagedObjectModel *)model {
    
    if (model != nil) {
        return model;
    }
    NSString *modelPath = [[NSBundle mainBundle] pathForResource:@"ScenicRoute" ofType:@"mom"];
    NSURL *modelURL = [NSURL fileURLWithPath:modelPath];
    model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];    
    return model;
}


/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)coordinator {
    
    if (coordinator != nil) {
        return coordinator;
    }
	
	// We don't need to copy the database since it is currently read only.  Just use it directly from the bundle.
	NSURL *bundleStoreURL = [[NSBundle mainBundle] URLForResource:@"metadata" withExtension:@"sqlite"];
    NSError *error = nil;
    coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self model]];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:bundleStoreURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter: 
         [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES],NSMigratePersistentStoresAutomaticallyOption, [NSNumber numberWithBool:YES], NSInferMappingModelAutomaticallyOption, nil];
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }    
    
    return coordinator;
}

-(void) dealloc {
	[documentsDirectory release];
	[model release];
	[context release];
	[coordinator release];
	
	[super dealloc];
}

@end
