//
//  HighwayDetourLoader.h
//  ScenicRoute
//
//  Created by Seb on 10-12-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataParserDelegate.h"


@interface HighwayDetourLoader : NSObject<DataParserDelegate> {
	NSMutableArray		*endPoints;
	NSMutableDictionary *partialRoutes;
	
	NSManagedObjectContext *context;
}

@property (nonatomic, readonly) NSMutableArray *endPoints;
@property (nonatomic, readonly) NSMutableDictionary *partialRoutes;
@property (nonatomic, readonly) NSManagedObjectContext *context;

- (void)loadFromURL:(NSURL*)url intoContext:(NSManagedObjectContext*)dbContext;

+ (void)deleteAllObjectsInEntityNamed:(NSString*)entityName context:(NSManagedObjectContext*)context;

@end
