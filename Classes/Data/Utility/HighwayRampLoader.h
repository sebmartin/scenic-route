//
//  HighwayRampLoader.h
//  ScenicRoute
//
//  Created by Seb on 10-12-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import	<CoreData/CoreData.h>

/**
 This class is a utility class for loading a JSON formatted list of highway ramps
 and serializing them into a sqlite database.
 */
@interface HighwayRampLoader : NSObject {

}

+ (void)loadFromURL:(NSURL*)url intoContext:(NSManagedObjectContext*)context;

+ (void)setBasicPropertiesFromDict:(NSDictionary*)dict toObject:(id)object;
+ (void)setBasicPropertiesFromDict:(NSDictionary*)dict toObject:(id)object ignoreKeys:(NSArray*)ignoreKeys;

@end
