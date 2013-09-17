//
//  HighwayDetourLoader.m
//  ScenicRoute
//
//  Created by Seb on 10-12-10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "HighwayDetourLoader.h"
#import "HighwayRamp+Utility.h"
#import "HighwayDetour+Utility.h"
#import "HighwayDetourPoint.h"
#import "GoogleDirectionsDataParser.h"
#import "GoogleRoute.h"
#import "GoogleRouteLeg.h"
#import "GoogleRouteStep.h"
#import "GenericParserErrorAlert.h"

@interface HighwayDetourLoader (private)
- (void)queueRouteCalculationFromRamp:(HighwayRamp*)startRamp toRamp:(HighwayRamp*)endRamp;
- (void)processRouteCalculations;
- (void)didFinishCalculatingRoutes;
@end


@implementation HighwayDetourLoader

@synthesize mapView;
@synthesize context;

@synthesize endPoints, partialRoutes;

- (id)init {
	if (self = [super init]) {
		endPoints = [NSMutableArray new];
		partialRoutes = [NSMutableDictionary new];
	}
	return self;
}

// TODO: Remove this when the DataParserDelegate class gets cleaned up
- (id)mapView {
	return nil;
}

- (void)loadFromURL:(NSURL*)url intoContext:(NSManagedObjectContext*)dbContext {
	context = [dbContext retain];
	

	[[self class] deleteAllObjectsInEntityNamed:@"HighwayDetour" context:context];
	[[self class] deleteAllObjectsInEntityNamed:@"HighwayDetourPoint" context:context];
	
	// Fetch each ramp and compute the best path between each (avoiding highways)
	NSError *error = nil;
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:@"HighwayRamp" inManagedObjectContext:context]];
	[request setPropertiesToFetch:[NSArray arrayWithObjects: @"number", @"direction", @"latitude", @"longitude", nil]];
	//[request setReturnsDistinctResults:YES];
	
	[request setPredicate: [NSPredicate predicateWithFormat:@"(highway.name == 'ON-417') AND (direction == 'asc')"]];
	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES]]];
	NSArray *ascResults = [context executeFetchRequest:request error:&error];
	
	[request setPredicate: [NSPredicate predicateWithFormat:@"(highway.name == 'ON-417') AND (direction == 'desc')"]];
	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:NO]]];
	NSArray *descResults = [context executeFetchRequest:request error:&error];
	
	// TEMP TEMP FOR SPLITTING THE LOAD
	//NSString *startRampNumber = @"0";
	//NSString *endRampNumber = @"999";
	// TEMP TEMP FOR SPLITTING THE LOAD
	
	// Iterate through each exit, in both directions and calculate the best routes
	for (NSArray *directionResults in [NSArray arrayWithObjects: ascResults, descResults, nil]) {
		
		for (int offRampIndex = 0; offRampIndex < [directionResults count]; offRampIndex++) {
			
			HighwayRamp *offRamp = [directionResults objectAtIndex:offRampIndex];
			
			// TEMP TEMP FOR SPLITTING THE LOAD
			//if ([offRamp.number caseInsensitiveCompare:startRampNumber] != NSOrderedDescending) {
			//	continue;
			//}
			// TEMP TEMP FOR SPLITTING THE LOAD
			
			// For now we just want the routes that detours to the highway (avoiding)
			// So, only offramps to onramps
			if ([offRamp.type caseInsensitiveCompare:@"offramp"] != NSOrderedSame) {
				continue;
			}
			
			// Iterate only the ramps that are beyond the off ramp (no need to go backwards on the highway!)
			for (int onRampIndex = offRampIndex + 1; onRampIndex < [directionResults count]; onRampIndex++) {
				HighwayRamp *onRamp = [directionResults objectAtIndex:onRampIndex];
				
				if ([onRamp.type caseInsensitiveCompare:offRamp.type] == NSOrderedSame 
					// TODO:We want to allow the off and on at the same exit in case they place two pins
					//   on the same exit.  We don't have time to tweak the UI to avoid this right now.
					// || [onRamp.number caseInsensitiveCompare:offRamp.number] == NSOrderedSame
					) 
				{
					continue;
				}
				
				// Queue this onramp/offramp combo to have the best route calculated
				[self queueRouteCalculationFromRamp:offRamp toRamp:onRamp];
			}
			
			// TEMP TEMP FOR SPLITTING THE LOAD
			//if ([offRamp.number caseInsensitiveCompare:endRampNumber] == NSOrderedDescending) {
			//	exit;
			//}
			// TEMP TEMP FOR SPLITTING THE LOAD
		}
	}
	
	[self performSelectorOnMainThread:@selector(processRouteCalculations) withObject:nil waitUntilDone:NO];
}

- (void)queueRouteCalculationFromRamp:(HighwayRamp*)startRamp toRamp:(HighwayRamp*)endRamp {
	// Just add it to a stack
	@synchronized(endPoints) {
		[endPoints addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							  startRamp, @"startRamp", 
							  endRamp, @"endRamp", nil]];
	}
}

- (void)processRouteCalculations {
		
	NSDictionary *currentEndPoints = nil;
	@synchronized(endPoints) {
		if ([endPoints count] == 0) {
			NSLog(@"Finished fetching %d routes between each highway on/off ramp", [partialRoutes count]);
			
			[self didFinishCalculatingRoutes];
			
			return;
		}
		currentEndPoints = [[endPoints lastObject] retain];
		[endPoints removeLastObject];
	}
	
	GoogleDirectionsDataParser *parser = [GoogleDirectionsDataParser new];
	parser.delegate = self;
	parser.context = currentEndPoints;  // Keep these around until after the route is calculated.
	
	HighwayRamp *startRamp = [currentEndPoints objectForKey:@"startRamp"];
	HighwayRamp	*endRamp = [currentEndPoints objectForKey:@"endRamp"];
	NSString *origin = [NSString stringWithFormat:@"%@,%@", startRamp.latitude, startRamp.longitude];
	NSString *destination = [NSString stringWithFormat:@"%@,%@", endRamp.latitude, endRamp.longitude];
	
	// Avoid highways if the first ramp is an off ramp (ie. offramp to onramp), otherwise, we're
	// routing the path on the highway
	NSLog(@"-=-=-= FETCHING PARTIAL ROUTE: %@:%@ (%@,%@) -> %@:%@ (%@,%@)", 
		  startRamp.number, startRamp.name, startRamp.type, startRamp.direction, 
		  endRamp.number, endRamp.name, endRamp.type, endRamp.direction);
	BOOL avoidHighways = ([startRamp.type caseInsensitiveCompare:@"offramp"] == NSOrderedSame);
	[parser fetchDataForOrigin:origin destination:destination avoidHighways:avoidHighways];
	
	[currentEndPoints release];
}

- (void)didFinishCalculatingRoutes {
	
	// Save the routes
	for (NSString *routeKey in partialRoutes) {
		NSDictionary *route = [partialRoutes valueForKey:routeKey];
		HighwayDetour *detour = [NSEntityDescription insertNewObjectForEntityForName:@"HighwayDetour" 
															  inManagedObjectContext:context];
		detour.startRamp = [route objectForKey:@"startRamp"];
		detour.endRamp = [route	objectForKey:@"endRamp"];
		detour.duration = 0;
		detour.distance = 0;
		
		NSLog(@"-=-=-=-=-=-= SAVING PARTIAL ROUTE: %@:%@ (%@) -> %@:%@ (%@)",
			  detour.startRamp.number, detour.startRamp.name, detour.startRamp.type,
			  detour.endRamp.number, detour.endRamp.name, detour.endRamp.type, nil);
		
		GoogleRoute *gRoute = [route objectForKey:@"route"];
		detour.polyline = gRoute.overviewPolylineEncoded;
		int pointOrder = 0;
		for (GoogleRouteLeg *gLeg in gRoute.legs) {
			detour.duration = [NSNumber numberWithInt: [detour.duration intValue] + gLeg.duration];
			detour.distance = [NSNumber numberWithInt: [detour.distance intValue] + gLeg.distance];
			
			for (GoogleRouteStep *gStep in gLeg.steps) {
				for (int pointIndex = 0; pointIndex < gStep.polyline.pointCount; pointIndex++) {
					MKMapPoint mapPoint = gStep.polyline.points[pointIndex];
					CLLocationCoordinate2D coord = MKCoordinateForMapPoint(mapPoint);
					HighwayDetourPoint * point = [NSEntityDescription 
												  insertNewObjectForEntityForName:@"HighwayDetourPoint" 
												  inManagedObjectContext:context];
					point.detour = detour;
					point.order = [NSNumber numberWithInteger:pointOrder++];
					point.latitude =[NSNumber numberWithDouble:coord.latitude];
					point.longitude = [NSNumber numberWithDouble:coord.longitude];
				}
			}
		}
	}
	
	// All done, publish the event
	[[NSNotificationCenter defaultCenter] 
	 postNotification:[NSNotification notificationWithName:@"didFinishLoadingMetaDataStep" object:nil]];
}

#pragma mark -
#pragma mark DataParserDelegate implementation

- (void)searchFinished {
	// Nothing to do here
}

- (void)parsingFinished:(id)parser {
	NSTimeInterval pauseBetweenCalls = 5;
	
	GoogleDirectionsDataParser *gParser = (GoogleDirectionsDataParser*)parser;
	
	GoogleRoute *newRoute = gParser.route;
	
	if (newRoute == nil) {
		// Process the next route but pause for a bit so that we don't hammer google too hard
		NSLog(@"-=-= WARNING: FOUND A NIL ROUTE RESULT!");
		[self performSelector:@selector(processRouteCalculations) withObject:nil afterDelay:pauseBetweenCalls];
	}
	
	int newRouteDuration = 0;
	for (GoogleRouteLeg *leg in newRoute.legs) {
		newRouteDuration += leg.duration;
	}

	HighwayRamp *newStartRamp = [gParser.context objectForKey:@"startRamp"];
	HighwayRamp *newEndRamp = [gParser.context objectForKey:@"endRamp"];
	NSString *offOrOn = ([newStartRamp.type caseInsensitiveCompare:@"offramp"] == NSOrderedSame ?
						 @"off" : @"on");
	NSString *key = [NSString stringWithFormat:@"%@,%@,%@", newStartRamp.number, newEndRamp.number, offOrOn];
	
	@synchronized(partialRoutes) {
		NSDictionary *otherRouteDict = [partialRoutes valueForKey:key];
		BOOL newRouteIsBetter = NO;
		
		if (otherRouteDict != nil) {
			int otherRouteDuration = 0;
			GoogleRoute *otherRoute = [otherRouteDict objectForKey:@"route"];
			for (GoogleRouteLeg *leg in otherRoute.legs) {
				otherRouteDuration += leg.duration;
			}
			if (otherRouteDuration > newRouteDuration) {
				newRouteIsBetter = YES;
			}			
		}
		
		if (otherRouteDict == nil || newRouteIsBetter) {
			[partialRoutes setValue:[NSDictionary dictionaryWithObjectsAndKeys:
									 newRoute, @"route",
									 newStartRamp, @"startRamp",
									 newEndRamp, @"endRamp", nil]
							 forKey:key];
		}
		
		
		/*if ([partialRoutes count] > 0) {
			// If the last calculated ramp is for the same exits as this new one, then
			// keep only the route with the shortest duration.
			NSDictionary *dict = [partialRoutes lastObject];
			HighwayRamp *lastStartRamp = [dict objectForKey:@"startRamp"];
			HighwayRamp *lastEndRamp = [dict objectForKey:@"endRamp"];
			if ([lastStartRamp isForSameExitAsRamp:newStartRamp] &&
				[lastEndRamp isForSameExitAsRamp:newEndRamp]) 
			{
				int lastRouteDuration = 0;
				GoogleRoute *lastRoute = [dict objectForKey:@"route"];
				for (GoogleRouteLeg *leg in lastRoute.legs) {
					lastRouteDuration += leg.duration;
				}
				if (lastRouteDuration > newRouteDuration) {
					[partialRoutes removeLastObject];
				}
			}
		
		}
		// Add the route to an array to be processed once they are all in
		NSString *key = [NSString stringWithFormat:@"%@,%@", newStartRamp.number, newEndRamp.number];
		[partialRoutes setValue:<#(id)value#> forKey:key];];
		
		[partialRoutes addObject:[NSDictionary dictionaryWithObjectsAndKeys:
						   newRoute, @"route",
						   newStartRamp, @"startRamp",
						   newEndRamp, @"endRamp", nil]];*/
	}
	
	// Process the next route but pause for a bit so that we don't hammer google too hard
	[self performSelector:@selector(processRouteCalculations) withObject:nil afterDelay:pauseBetweenCalls];
}

-(void) parser:(id)parser didFailWithError:(NSError *)error {
	[GenericParserErrorAlert showAlertForError:error];
}

#pragma mark -
#pragma mark House cleaning

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

-(void) dealloc {
	[context release];
	[endPoints release];
	[partialRoutes release];
	
	[super dealloc];
}

@end
