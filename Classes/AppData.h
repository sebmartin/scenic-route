//
//  AppData.h
//  ScenicRoute
//
//  Created by Seb on 10-12-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>


@interface AppData : NSObject {
	
@private
	NSString	*documentsDirectory;
    NSManagedObjectContext *context;
    NSManagedObjectModel *model;
    NSPersistentStoreCoordinator *coordinator;
}

-(id)initWithDocumentsDirectory:(NSString *)docsDirectory;

// Core Data
@property (nonatomic, retain, readonly) NSString *documentsDirectory;
@property (nonatomic, retain, readonly) NSManagedObjectModel *model;
@property (nonatomic, retain, readonly) NSManagedObjectContext *context;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *coordinator;

@end
