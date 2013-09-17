//
//  HighwayRampLoader.m
//  ScenicRoute
//
//  Created by Seb on 10-12-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreLocation/CoreLocation.h>

#import "JSON.h"
#import "HighwayRampLoader.h"

#import "Highway.h"
#import	"HighwayRamp.h"
#import "HighwayRampRect.h"
#import "HighwayNamedExit.h"

@interface HighwayRampLoader (private)
+ (void)deleteAllObjectsInEntityNamed:(NSString*)entityName context:(NSManagedObjectContext*)context;
@end

@implementation HighwayRampLoader

+ (void)loadFromURL:(NSURL*)url intoContext:(NSManagedObjectContext*)context {
	
	// Fetch the JSON source data
	NSString *resPath = [[NSBundle mainBundle] pathForResource:@"HighwayRamps" ofType:@"json"];
	NSString *data = [NSString stringWithContentsOfFile:resPath encoding:NSUTF8StringEncoding error:nil];
	
	// Deserialize and store in the database
	NSError *error = nil;
	SBJsonParser *parser = [[SBJsonParser alloc] init];
	id jsonData = [parser objectWithString:data error:&error];
	if (error) {
		NSLog(@"%@", error);
		return;
	}

	[self deleteAllObjectsInEntityNamed:@"Highway" context:context];
	[self deleteAllObjectsInEntityNamed:@"HighwayRamp" context:context];
	[self deleteAllObjectsInEntityNamed:@"HighwayRampRect" context:context];
	
	// Load the ramps
	Highway *highway = [NSEntityDescription insertNewObjectForEntityForName:@"Highway" inManagedObjectContext:context];
	highway.name = @"ON-417";
	
	for (NSDictionary *rampInfo in jsonData) {
		HighwayRamp *ramp = [NSEntityDescription insertNewObjectForEntityForName:@"HighwayRamp" inManagedObjectContext:context];
		
		// Copy the basic properties from the JSON object
		[self setBasicPropertiesFromDict:rampInfo 
								toObject:ramp 
							  ignoreKeys:[NSArray arrayWithObjects:@"highway", nil]];
		ramp.highway = highway;
		
		NSArray *rampRects = [rampInfo objectForKey:@"rampRects"];
		if (rampRects) {
			for (NSDictionary* rampRectInfo in rampRects) {
				HighwayRampRect *rampRect = [NSEntityDescription 
											 insertNewObjectForEntityForName:@"HighwayRampRect" 
											 inManagedObjectContext:context];
				[self setBasicPropertiesFromDict:rampRectInfo toObject:rampRect];
				rampRect.ramp = ramp;
			}
		}
	}
	
	// Calculate the named exits (one per ramp number)
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:@"HighwayRamp" inManagedObjectContext:context]];
	[request setSortDescriptors:[NSArray arrayWithObjects:
								 [NSSortDescriptor sortDescriptorWithKey:@"highway" ascending:YES],
								 [NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES],
								 nil]];
	error = nil;
	NSString *lastNumber = nil;
	Highway *lastHighway = nil;
	NSMutableArray *exitCoordinates = [NSMutableArray new];
	NSArray *ramps = [context executeFetchRequest:request error:&error];
	for (HighwayRamp *ramp in ramps) {
		BOOL processArray = NO;
		if (!highway    || [ramp.highway.name caseInsensitiveCompare:lastHighway.name] != NSOrderedSame ||
			!lastNumber || [ramp.number caseInsensitiveCompare:lastNumber] != NSOrderedSame ||
			ramp == [ramps lastObject]) 
		{
			processArray = YES;
		}
		
		// To calculate the location of the exit, we just use the average of all of its ramps
		if (processArray && [exitCoordinates count] > 0) {
			double lat = 0;
			double lng = 0;
			for (NSDictionary *coord in exitCoordinates) {
				lat += [[coord objectForKey:@"latitude"] doubleValue];
				lng += [[coord objectForKey:@"longitude"] doubleValue];
			}
			lat /= [exitCoordinates count];
			lng /= [exitCoordinates count];
			[exitCoordinates removeAllObjects];
			
			HighwayNamedExit *exit = [NSEntityDescription insertNewObjectForEntityForName:@"HighwayNamedExit"
																   inManagedObjectContext:context];
			exit.highway = lastHighway;
			exit.number = lastNumber;
			exit.latitude = [NSNumber numberWithDouble:lat];
			exit.longitude = [NSNumber numberWithDouble:lng];
		}
		
		// Add the coordinates
		NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
			 ramp.latitude, @"latitude", 
			 ramp.longitude, @"longitude",
							  nil];
		[exitCoordinates addObject:dict];
		lastHighway = ramp.highway;		
		lastNumber = ramp.number;
	}
	
	[exitCoordinates release];
	[request release];
}

+ (void)deleteAllObjectsInEntityNamed:(NSString*)entityName context:(NSManagedObjectContext*)context {
	NSFetchRequest * allObjects = [[NSFetchRequest alloc] init];
	[allObjects setEntity:[NSEntityDescription entityForName:entityName inManagedObjectContext:context]];
	[allObjects setIncludesPropertyValues:NO]; //only fetch the managedObjectID
	
	NSError * error = nil;
	NSArray * objects = [context executeFetchRequest:allObjects error:&error];
	[allObjects release];
	//error handling goes here
	for (NSManagedObject * object in objects) {
		[context deleteObject:object];
	}	
}

+ (void)setBasicPropertiesFromDict:(NSDictionary*)dict toObject:(id)object {
	[self setBasicPropertiesFromDict:dict toObject:object ignoreKeys:nil];
}

+ (void)setBasicPropertiesFromDict:(NSDictionary*)dict toObject:(id)object ignoreKeys:(NSArray*)ignoreKeys {
	for (NSString *propName in [dict allKeys]) {	
		id property = [dict objectForKey:propName];
		if ([property isKindOfClass:[NSArray class]] || [property isKindOfClass:[NSDictionary class]]) {
			continue;  // Skip dictionaries and arrays, we need to handle these manually
		}
		if (ignoreKeys && [ignoreKeys containsObject:propName]) {
			BOOL ignoreIt = NO;
			for (NSString *key in ignoreKeys) {
				if ([key isEqualToString:propName]) {
					ignoreIt = YES;
					break;
				}
			}
			if (ignoreIt) {
				continue;
			}
		}
		[object setValue:[dict objectForKey:propName] forKey:propName];
	}
}

@end
