//
//  HighwayAlternateRoute.m
//  ScenicRoute
//
//  Created by Seb on 10-12-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HighwayDetourRouter.h"
#import "HighwayRedZoneOverlay.h"
#import "HighwayNamedExit.h"
#import "HighwayRampRect.h"
#import "HighwayDetour.h"
#import "HighwayDetourPoint.h"
#import "GoogleRouteLeg.h"
#import "GoogleRouteStep.h"
#import "GoogleDirectionsDataParser.h"
#import "RouteRequest.h"
#import "GenericParserErrorAlert.h"

#define kRAMPTYPE_ONRAMP	@"onramp"
#define kRAMPTYPE_OFFRAMP	@"offramp"

#pragma mark -
#pragma mark - RouteRequest private class





#pragma mark -
#pragma mark - NSString + NumericComparison

// This category for NSString adds a method that allows sorting strings
// as numeric values without having to pass a second parameter.  This is
// useful to sort arrays of strings with the method sortedArrayUsingSelector:

@interface NSString (NumericComparison)
@end

@implementation NSString (NumericComparison)

-(NSComparisonResult) compareAsNumericValues:(NSString *)string {
	return [self compare:string options:NSNumericSearch];
}

@end


#pragma mark -
#pragma mark HighwayDetourRouter class

@interface HighwayDetourRouter (private) 
- (NSArray*)findOfframpsAtExit:(NSString*)number type:(NSString*)type direction:(NSString*)direction;
- (void)buildDetourRoute;
- (RouteRequest*)addRouteRequestsForOrigin:(CLLocationCoordinate2D)origin destination:(CLLocationCoordinate2D)destination step:(NSNumber*)step;
- (void)requestRouteFromOrigin:(CLLocationCoordinate2D)origin toDestination:(CLLocationCoordinate2D)destination step:(NSNumber*)step avoidHighways:(BOOL)avoidHighways;
- (void)requestCachedRouteFromRamp:(HighwayRamp*)startRamp toRamp:(HighwayRamp*)endRamp step:(NSNumber*)step;
- (void)checkIfRoutingIsComplete;
- (void)routingIsComplete;
- (void)routeIsReady;
@end

@implementation HighwayDetourRouter

@dynamic mapView;
@synthesize delegate;
@synthesize route;
@synthesize redZones;
@synthesize	detourPoints;
@synthesize finalRoute;

#pragma mark -
#pragma mark Inits and show starters

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)dbContext {
	if (self = [super init]) {
		// Initialize
		context = [dbContext retain];
	}
	return self;
}

-(void)findAlternateRoute {
	[self detectHighwayAccess];
	//[self detectIfRouteStartsOrEndsOnHighway
	[self detectIntersectionWithRedZones];
	[self buildDetourRoute];
}

#pragma mark -
#pragma mark Routing tasks

// Walks through the route and detects if it uses the highway at all
// Returns an NSArray of NSArrays. The inner arrays contain exactly two objects; a HighwayNamedExit
// instance, one for each end of the leg that goes on the highway.
-(void)detectHighwayAccess {

	// Keep a reference to the start and end points
	startPosition = [[self.route.legs objectAtIndex:0] startLocation];
	endPosition = [[self.route.legs lastObject] endLocation];
	
	// Get all the ramp rects within within the database
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:@"HighwayRampRect" inManagedObjectContext:context]];
	
	NSError *error = nil;
	NSArray *rampRects = [context executeFetchRequest:request error:&error];
	[request release];
	
	// Walk through each point on the route (turns only) and detect if they go on any of these onramp/offramps
	// TODO: This loop is awesome! Find a way to make it a little less "awesome"..  
	// Ideas:
	//   - Draw a rect around the route and see if it overlaps a highway, then only test those highways
	//   - Draw a rect around the red zones and see if it overlaps..
	//   - We might be able to only test the first 10 or so points in a step, the rest will be the 
	//     road between the next turn instruction
	//   - We might also be able to skip every second point
	//   - Sort the points and the rects so that we can eliminate some based on that
	//   - Cheap, but we can test the htmlInstructions for wording that might indicate the use of an on/off ramp
	if (accessedRamps) {
		[accessedRamps removeAllObjects];
	}
	else {
		accessedRamps = [NSMutableDictionary dictionary];
	}
	for (GoogleRouteLeg *leg in self.route.legs) {
		for (GoogleRouteStep *step in leg.steps) {
			for (int i=0; i < step.polyline.pointCount; i++) {
				CLLocationCoordinate2D coord = MKCoordinateForMapPoint(step.polyline.points[i]);
				for (HighwayRampRect *rampRect in rampRects) {
					if (coord.latitude < [rampRect.topLeftLat doubleValue] &&
						coord.latitude > [rampRect.bottomRightLat doubleValue] &&
						coord.longitude > [rampRect.topLeftLng doubleValue] &&
						coord.longitude < [rampRect.bottomRightLng doubleValue]) 
					{
						NSMutableArray *matchedRamps = [accessedRamps valueForKey:rampRect.ramp.highway.name];
						if (!matchedRamps) {
							matchedRamps = [NSMutableArray array];
							[accessedRamps setValue:matchedRamps forKey:rampRect.ramp.highway.name];
						}
						if (![matchedRamps containsObject:rampRect.ramp]) {
							[matchedRamps addObject:rampRect.ramp];
						}
						break;
					}
				}					
			}
		}	
	}
	
	// log the used exits
	for (NSString *highwayName in accessedRamps) {
		NSArray *matchedRects = [accessedRamps valueForKey:highwayName];
		for (HighwayRamp *ramp in matchedRects) {
			NSLog(@"Detected use of ramp number: %@, name: %@, type: %@", ramp.number, ramp.name, ramp.type);
		}
	}
}

- (void)detectIntersectionWithRedZones {
	// Detect if the route intersects any red zones
	avoidEntireHighway = NO;
	self.detourPoints = [NSMutableArray array];
	for (NSString *highwayName in self.redZones) {
		
		// Get a reference to the red zone exits
		// TODO: these should be highway specific
		HighwayRedZoneOverlay *overlay = [self.redZones objectForKey:highwayName];
		HighwayNamedExit *lowRedZoneExit = overlay.lowAnnotation.namedExit;
		HighwayNamedExit *highRedZoneExit = overlay.highAnnotation.namedExit;
		
		// Make sure the annotations are in the correct order
		if ([lowRedZoneExit.number caseInsensitiveCompare:highRedZoneExit.number] == NSOrderedDescending) {
			id temp = lowRedZoneExit;
			lowRedZoneExit = highRedZoneExit;
			highRedZoneExit = temp;
		}
		
		// Skip this highway if not used in route
		// TODO: Handle the case where there is only one exit (ie, the starting point is on the highway)
		//   also, consider the cas where both start and end points are on the highway
		
		//***** TEMP ***** This is a cheap quick fix
		BOOL usesHighway = NO;
		BOOL ascending;
		NSString *hwyNameEast = [NSString stringWithFormat:@"%@ E", highwayName];
		NSString *hwyNameWest = [NSString stringWithFormat:@"%@ W", highwayName];
		for (GoogleRouteLeg *leg in route.legs) {
			for (GoogleRouteStep *step in leg.steps) {
				// See if the highway name is in the instructions
				NSRange range = [step.htmlInstructions rangeOfString:hwyNameEast];
				if (range.location != NSNotFound) {
					usesHighway = YES;
					ascending = NO;
					break;
				}
				range = [step.htmlInstructions rangeOfString:hwyNameWest];
				if (range.location != NSNotFound) {
					usesHighway = YES;
					ascending = YES;
					break;
				}
			}
			if (usesHighway) {
				break;
			}
		}
		//***** TEMP ***** End of quick fix
		
		UIAlertView *alert =  [[UIAlertView alloc] initWithTitle:@"Highway Detection" 
														 message:@"Unable to detect which parts of the highway are used by the requested route.  The highway zone might not be avoided.  Try keeping your route within the city limits."
														delegate:self
											   cancelButtonTitle:@"OK" otherButtonTitles:nil];
		
		NSArray *ramps = [accessedRamps valueForKey:highwayName];
		if (!ramps || [ramps count] == 0) {
			// TODO: We don't yet handle the case when onramp and offramps are not balanced
			// TODO: At least show a pop up warning the user that the route is imperfect
			
			// TEMP FIX : If we get here and the highway use was detected, we assume that the
			//   whole trip spans over the area we are covering.  So, avoid the red zone completely
			
			if (!usesHighway) {
				continue;
			}
			/*
			if (ascending) {
				[self.detourPoints addObject: [self findOfframpsAtExit:lowRedZoneExit.number type:kRAMPTYPE_OFFRAMP direction:(ascending ? @"asc" : @"desc")]];
				[self.detourPoints addObject: [self findOfframpsAtExit:highRedZoneExit.number type:kRAMPTYPE_ONRAMP direction:(ascending ? @"asc" : @"desc")]];
			}
			else {
				[self.detourPoints addObject: [self findOfframpsAtExit:highRedZoneExit.number type:kRAMPTYPE_OFFRAMP direction:(ascending ? @"asc" : @"desc")]];
				[self.detourPoints addObject: [self findOfframpsAtExit:lowRedZoneExit.number type:kRAMPTYPE_ONRAMP direction:(ascending ? @"asc" : @"desc")]];
			}*/
			
			// We can't tell the difference whether the two start and end ramps of the route are
			// on each end of the red zone (ie. span over it) of it they are both on the same side
			// of the red zone (ie, no red zone overlap).  So, we just show a warning to say that 
			// the red zones might not be respected.
			// TODO: Fix this, or in the least make the warning less intrusive.
			[alert show];

			continue;
		}
		else if ([ramps count] == 1) {
			// If we only found one ramp, the route probably starts or ends beyond the ramps that 
			// we track
			NSLog(@"*** ROUTE WARNING: Detected only one ramp, looking for a possible ramp to pair.");
			HighwayRamp *ramp = [ramps objectAtIndex:0];
			
			BOOL isOnRamp = [ramp.type caseInsensitiveCompare:@"onramp"] == NSOrderedSame;
			BOOL isWithin = [ramp.number caseInsensitiveCompare:lowRedZoneExit.number] != NSOrderedAscending &&
							[ramp.number caseInsensitiveCompare:highRedZoneExit.number] != NSOrderedDescending;
			BOOL isHigher = [ramp.number caseInsensitiveCompare:highRedZoneExit.number] == NSOrderedDescending;
			BOOL isLower = [ramp.number caseInsensitiveCompare:lowRedZoneExit.number] == NSOrderedAscending;

			ascending = [ramp.direction caseInsensitiveCompare:@"asc"] == NSOrderedSame;
			
			// Check if the ramp is between the two red zone markers
			if (isWithin) 
			{
				NSString *type = isOnRamp ? kRAMPTYPE_ONRAMP : kRAMPTYPE_OFFRAMP;
				NSString *exitNumber = (ascending && isOnRamp || !ascending && !isOnRamp) ? highRedZoneExit.number : lowRedZoneExit.number;
				[self.detourPoints addObject: [self findOfframpsAtExit:exitNumber type:type direction:(ascending ? @"asc" : @"desc")]];
			}
			// Check if it's before the red zone and ascending
			else if (ascending && (isLower && isOnRamp || isHigher && !isOnRamp)) 
			{
				[self.detourPoints addObject: [self findOfframpsAtExit:lowRedZoneExit.number type:kRAMPTYPE_OFFRAMP direction:(ascending ? @"asc" : @"desc")]];
				[self.detourPoints addObject: [self findOfframpsAtExit:highRedZoneExit.number type:kRAMPTYPE_ONRAMP direction:(ascending ? @"asc" : @"desc")]];
			}
			// Check if it's after the red zone and descending
			else if(!ascending && (isLower && !isOnRamp || isHigher && isOnRamp)) {
				[self.detourPoints addObject: [self findOfframpsAtExit:highRedZoneExit.number type:kRAMPTYPE_OFFRAMP direction:(ascending ? @"asc" : @"desc")]];
				[self.detourPoints addObject: [self findOfframpsAtExit:lowRedZoneExit.number type:kRAMPTYPE_ONRAMP direction:(ascending ? @"asc" : @"desc")]];
			}
			else {
				[alert show];
			}
			
			continue;
		}
		[alert release];
		alert = nil;
		
		// Order the exits for the route and the red zones in the same direction
		HighwayRamp *routeOnRamp = [ramps objectAtIndex:0];
		HighwayRamp *routeOffRamp = [ramps objectAtIndex:1];
		BOOL routeExitsAscending = [routeOnRamp.number caseInsensitiveCompare:routeOffRamp.number] == NSOrderedAscending;
		BOOL redZoneExitsAscending = [overlay.lowAnnotation.namedExit.number caseInsensitiveCompare:overlay.highAnnotation.namedExit.number] == NSOrderedAscending;
		if (redZoneExitsAscending != routeExitsAscending) {
			lowRedZoneExit = overlay.highAnnotation.namedExit;
			highRedZoneExit = overlay.lowAnnotation.namedExit;
			redZoneExitsAscending = routeExitsAscending;
		}
		NSString *travelDirection = (routeExitsAscending ? @"asc" : @"desc");
		
		// Modify the variables to be direction agnostic
		NSInteger orderModifier = (routeExitsAscending ? 1 : -1);
		
		// If both onramp and offramp are within the red zone, we skip it entirely
		if ([routeOnRamp.number caseInsensitiveCompare:lowRedZoneExit.number] != orderModifier * NSOrderedAscending &&
			[routeOffRamp.number caseInsensitiveCompare:highRedZoneExit.number] != orderModifier * NSOrderedDescending) 
		{
			avoidEntireHighway = YES;
			continue;
		}
		/*
		// TODO: if both RedZone Exits are the same, we need to find the previous and next exits to get around it.
		// LOW PRIORITY -- we might not want this, we should maybe avoid landing on the same exit
		else if () {
		 
		}
		*/
		// Otherwise, if they overlap, we need to find onramps and offramps to avoid the red zone
		// -- ASCENDING
		else if ([routeOnRamp.number caseInsensitiveCompare:highRedZoneExit.number] == orderModifier * NSOrderedAscending &&
				 [lowRedZoneExit.number caseInsensitiveCompare:routeOffRamp.number] == orderModifier * NSOrderedAscending) 
		{
			// If the route crosses the entire redzone, we need to get off and back on
			if ([routeOnRamp.number caseInsensitiveCompare:lowRedZoneExit.number] == orderModifier * NSOrderedAscending &&
				[routeOffRamp.number caseInsensitiveCompare:highRedZoneExit.number] == orderModifier * NSOrderedDescending)
			{
				// TODO: this could be merged with the same block
				[self.detourPoints addObject: [self findOfframpsAtExit:lowRedZoneExit.number type:kRAMPTYPE_OFFRAMP direction:travelDirection]];
				[self.detourPoints addObject: [self findOfframpsAtExit:highRedZoneExit.number type:kRAMPTYPE_ONRAMP direction:travelDirection]];
			}
			else {
				
				// Partial coverage, either the on-ramp or the off-ramp is within the red zone
				if ([routeOnRamp.number caseInsensitiveCompare:lowRedZoneExit.number] == orderModifier * NSOrderedAscending) {
					[self.detourPoints addObject: [self findOfframpsAtExit:lowRedZoneExit.number type:kRAMPTYPE_OFFRAMP direction:travelDirection]];
				}
				else {
					[self.detourPoints addObject: [self findOfframpsAtExit:highRedZoneExit.number type:kRAMPTYPE_ONRAMP direction:travelDirection]];
				}
				
			}
		}
	}
	
	for (id point in self.detourPoints) {
		NSLog(@"-- POINT");
		
		// Wrap each point into an array, if not one already
		NSArray *pointArray = nil;
		if (![point isKindOfClass:[NSArray class]]) {
			pointArray = [NSArray arrayWithObject:point];
		}
		else {
			pointArray = point;
		}
		
		for (id pointAlternative in pointArray) {
			if ([pointAlternative isKindOfClass:[HighwayRamp class]]) {
				HighwayRamp *exit = pointAlternative;
				NSLog(@"   -- Exit Name: %@, Number: %@, type: %@", exit.name, exit.number, exit.type);
			}
			else if ([pointAlternative isKindOfClass:[NSValue class]]) {
				// TODO: We might add the start and end locations to this array, so we might need
				//   to detect if a CLLocationCoordinate2D struct is in the array, but it would be
				//   wrapped in an NSValue object...
				//CLLocationCoordinate2D coord = [(NSValuepointAlternative;
				//NSLog(@"   -- Coordinate: %f, %f", coord.latitude, coord.longitude);
			}
		}
	}
}

- (NSArray*)findOfframpsAtExit:(NSString*)number type:(NSString*)type direction:(NSString*)direction {

	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:@"HighwayRamp" inManagedObjectContext:context]];
	[request setPredicate:[NSPredicate predicateWithFormat:@"number = %@ AND type = %@ AND direction = %@", 
						   number, type, direction, nil]];
	
	NSError *error = nil;
	NSArray *result = [context executeFetchRequest:request error:&error];
	// TODO handle error!
	
	[request release];
	return result;
}

- (void)buildDetourRoute {
	
	didQueueAllRouteRequests = NO;

	if ([self.detourPoints count] == 0) 
	{
		// TODO: This might be redundant with the original route!!
		/*if (!avoidEntireHighway) {
			self.finalRoute = [BasicRoute new];
			self.finalRoute.polyline = route.overviewPolyline;
			
			self.finalRoute.duration = 0;
			self.finalRoute.distance = 0;
			for (GoogleRouteLeg *leg in route.legs) {
				self.finalRoute.duration += leg.duration;
				self.finalRoute.distance += leg.distance;
			}
			
			[self routeIsReady];
		}
		else {*/
			[self requestRouteFromOrigin:startPosition 
						   toDestination:endPosition 
									step:[NSNumber numberWithInt:0] 
						   avoidHighways:avoidEntireHighway];
		//}
	}
	else {
		// Request the full route avoiding highways completely.. this might be quicker than the detour
		[self requestRouteFromOrigin:startPosition toDestination:endPosition step:[NSNumber numberWithInt:0] avoidHighways:YES];
		
		// Build the route from the route origin to the first detour point
		int step = 1;
		for (HighwayRamp *ramp in (NSArray*)[self.detourPoints objectAtIndex:0]) {
			CLLocationCoordinate2D rampPosition = CLLocationCoordinate2DMake([ramp.latitude doubleValue], [ramp.longitude doubleValue]);
			// TODO: consider the situation where the start position is on the highway!

			// If the ramp is an onramp, we avoid highways completely.  The inverse is true for offramps.
			BOOL avoidHighways = ([ramp.type caseInsensitiveCompare:@"onramp"] == NSOrderedSame); 
			[self requestRouteFromOrigin:startPosition toDestination:rampPosition step:[NSNumber numberWithInt:step] avoidHighways:avoidHighways];
		}
		step++;
		
		// Build the route between each detour point
		id lastDetourPoint = nil;
		for (NSArray *detourPoint in self.detourPoints) {
			if (lastDetourPoint == nil) {
				lastDetourPoint = detourPoint;
				continue;
			}
			
			// Each detour point is an array since there could be more than on on/off ramp for the same exit.  
			// Since we're pulling these routes from a cache (DB) we already know the optimal route between the two
			// exits and so we know which on/off ramp is the one to use in this case. So we just pull out the first
			// object in each array, the core data query will figure it out.
			HighwayRamp *ramp1 = (HighwayRamp*)[lastDetourPoint objectAtIndex:0];
			HighwayRamp *ramp2 = (HighwayRamp*)[detourPoint objectAtIndex:0];
			[self requestCachedRouteFromRamp:ramp1 toRamp:ramp2 step:[NSNumber numberWithInt:step]];
			lastDetourPoint = detourPoint;
			step++;
		}
		
		// Build the route from the last detour point to the route destination
		for (HighwayRamp *ramp in (NSArray*)[self.detourPoints lastObject]) {
			CLLocationCoordinate2D rampPosition = CLLocationCoordinate2DMake([ramp.latitude doubleValue], [ramp.longitude doubleValue]);
			// TODO: consider the situation where the end position is on the highway!
			
			// Avoid the highway only if it's an offramp.  In the case where the end destination is beyond the part of the highway that we track,
			// this last point will be an onramp.  In this case we want to use the highway up until the final destination.
			BOOL avoidHighways = ([ramp.type caseInsensitiveCompare:@"offramp"] == NSOrderedSame); 
			[self requestRouteFromOrigin:rampPosition toDestination:endPosition step:[NSNumber numberWithInt:step] avoidHighways:avoidHighways];
		}
		step++;	
	}
	
	didQueueAllRouteRequests = YES;
	
	[self checkIfRoutingIsComplete];
}

- (RouteRequest*)addRouteRequestsForOrigin:(CLLocationCoordinate2D)origin destination:(CLLocationCoordinate2D)destination step:(NSNumber*)step {
	// Initialize the request array if it isn't already
	if (!detourRouteLegs) {
		detourRouteLegs = [NSMutableArray new];
	}
	
	// Add the request to the array 
	RouteRequest *routeRequest = [RouteRequest new];
	routeRequest.startCoordinate = origin;
	routeRequest.endCoordinate = destination;
	routeRequest.step = step;
	routeRequest.polyline = nil;
	[detourRouteLegs addObject: routeRequest];
	return [routeRequest autorelease];
}

- (void)requestRouteFromOrigin:(CLLocationCoordinate2D)origin toDestination:(CLLocationCoordinate2D)destination step:(NSNumber*)step avoidHighways:(BOOL)avoidHighways
{
	NSLog(@"requestRouteFromOrigin:[%f,%f] toDestination:[%f,%f] step:%@ avoidHighways:%d", origin.latitude, origin.longitude, destination.latitude, destination.longitude, step, avoidHighways);
	
	// Add to the list of requests
	RouteRequest *routeRequest = [self addRouteRequestsForOrigin:origin destination:destination step:step];
	
	// Instantiate a parser and send request for processing
	GoogleDirectionsDataParser *gDirParser = [GoogleDirectionsDataParser new];
	gDirParser.delegate = self;
	gDirParser.context = routeRequest;
	NSString *originStr = [NSString stringWithFormat:@"%f,%f", origin.latitude, origin.longitude];
	NSString *destinationStr = [NSString stringWithFormat:@"%f,%f", destination.latitude, destination.longitude];
	[gDirParser fetchDataForOrigin:originStr destination:destinationStr avoidHighways:avoidHighways];
	
	@synchronized(detourRoutesInProgress) {
		if (!detourRoutesInProgress) {
			detourRoutesInProgress = [NSMutableArray new];
		}
		[detourRoutesInProgress addObject:gDirParser];
	}
}

- (void)requestCachedRouteFromRamp:(HighwayRamp*)startRamp toRamp:(HighwayRamp*)endRamp step:(NSNumber*)step
{
	NSLog(@"requestCachedRouteFromRamp:%@ toDestination:%@ step:%@", startRamp.number, endRamp.number, step);
	
	// Figure out the direction in which we're travelling
	NSString *direction = ([startRamp.number caseInsensitiveCompare:endRamp.number] == NSOrderedAscending ?
						   @"asc" : @"desc");
	
	// Fetch all possible routes
	NSFetchRequest *rampRequest = [NSFetchRequest new];
	[rampRequest setEntity:[NSEntityDescription entityForName:@"HighwayDetour" inManagedObjectContext:context]];
	[rampRequest setPredicate:[NSPredicate predicateWithFormat:
							   @"startRamp.highway.name = %@ AND "
							    "startRamp.number = %@ AND "
							    "startRamp.direction = %@ AND "
							    "startRamp.type = 'offramp' AND "
							    "endRamp.highway.name = %@ AND "
							    "endRamp.number = %@ AND "
							    "endRamp.direction = %@ AND "
							    "endRamp.type = 'onramp'",
							   startRamp.highway.name, startRamp.number, direction,
							   endRamp.highway.name, endRamp.number, direction,nil]];
	[rampRequest setFetchLimit:1];
	[rampRequest setSortDescriptors:[NSArray arrayWithObject:
									 [NSSortDescriptor sortDescriptorWithKey:@"duration" ascending:YES]]];
	NSError *error = nil;
	NSArray *results = [context executeFetchRequest:rampRequest error:&error];
	// TODO: handle errors
	[rampRequest release];
	
	// Add the request to the array 
	if ([results count] == 0) {
		NSLog(@"ERROR - Could not find a cached route between exits in the database.");
		return;
	}
	HighwayDetour *detour = [results objectAtIndex:0];
	NSArray *points = [detour.steps sortedArrayUsingDescriptors:[NSArray arrayWithObject:
					   [NSSortDescriptor sortDescriptorWithKey:@"order" ascending:YES]]];
	CLLocationCoordinate2D *coords = malloc([points count] * sizeof(CLLocationCoordinate2D));
	for (int i=0; i < [points count]; i++) {
		HighwayDetourPoint *detourPoint = [points objectAtIndex:i];
		coords[i] = CLLocationCoordinate2DMake([detourPoint.latitude doubleValue], [detourPoint.longitude doubleValue]);
	}
	RouteRequest *routeRequest = [self addRouteRequestsForOrigin:coords[0] 
													 destination:coords[[points count]-1]
															step:step];
	if ([points count] > 0) {
		HighwayDetourPoint *firstPoint = [points objectAtIndex:0];
		routeRequest.duration = [firstPoint.detour.duration intValue];
		routeRequest.distance = [firstPoint.detour.distance intValue];
	}
	routeRequest.polyline = [MKPolyline polylineWithCoordinates:coords count:[points count]];
	free(coords);
}

- (void)checkIfRoutingIsComplete {
	if (didQueueAllRouteRequests && [detourRoutesInProgress count] == 0) {
		[self performSelectorOnMainThread:@selector(routingIsComplete) withObject:nil waitUntilDone:NO];
	}
}

- (void)routingIsComplete {
	NSLog(@"detourRouteIsReady");
	
	// Do the final route comparison
	NSMutableDictionary *steps = [NSMutableDictionary new];
	for (RouteRequest *routeRequest in detourRouteLegs) {
		RouteRequest *existingRouteRequest = [steps valueForKey:[routeRequest.step stringValue]];
		if (existingRouteRequest == nil ||
			existingRouteRequest.duration > routeRequest.duration) 
		{
			[steps setValue:routeRequest forKey:[routeRequest.step stringValue]];
		}
	}
	
	// Remove the index zero item since it's the full route without highways
	RouteRequest *avoidAllRoute = [[steps valueForKey:@"0"] retain];
	[steps removeObjectForKey:@"0"];
	
	// Build the route from legs
	NSArray *sortedKeys = [[steps allKeys] sortedArrayUsingSelector:@selector(compareAsNumericValues:)];
	NSInteger coordCount = 0;
	NSInteger duration = 0;
	NSInteger distance = 0;
	for (NSString *key in sortedKeys) {
		RouteRequest *routeRequest = [steps objectForKey:key];
		coordCount += routeRequest.polyline.pointCount;
		duration += routeRequest.duration;
		distance += routeRequest.distance;
	}
	
	self.finalRoute = [BasicRoute new];
	[self.finalRoute release]; // retained by the property

	if ([steps count] == 0 || avoidAllRoute.duration < duration) {
		// Avoiding the highways completely is more efficient
		self.finalRoute.polyline = avoidAllRoute.polyline;
		self.finalRoute.duration = avoidAllRoute.duration;
		self.finalRoute.distance = avoidAllRoute.distance;
	}
	else {
		// Build the full polyline from each leg
		MKMapPoint *points = malloc(coordCount * sizeof(MKMapPoint));
		int baseCount = 0;
		for (NSString *key in sortedKeys) {
			RouteRequest *routeRequest = [steps objectForKey:key];
			for (int i=0; i < routeRequest.polyline.pointCount; i++) {
				points[baseCount + i] = routeRequest.polyline.points[i];
			}
			baseCount += routeRequest.polyline.pointCount;
		}
		self.finalRoute.polyline = [MKPolyline polylineWithPoints:points count:coordCount];
		self.finalRoute.duration = duration;
		self.finalRoute.distance = distance;
		free(points);
	}
	[steps release];
	
	[self routeIsReady];
}

- (void)routeIsReady {
	// Call the delegate
	SEL selector = @selector(routerDidFinish:);
	if ([delegate respondsToSelector:selector]) {
		[delegate performSelectorOnMainThread:selector withObject:self waitUntilDone:NO];
	}
}

#pragma mark -
#pragma mark - DataParserDelegate implementation

-(void) parsingFinished:(id)parser {
	// pop the stack
	GoogleDirectionsDataParser *gDirParser = (GoogleDirectionsDataParser*)parser;
	RouteRequest *routeRequest = gDirParser.context;
	routeRequest.duration = gDirParser.route.duration;
	routeRequest.distance = gDirParser.route.distance;
	routeRequest.polyline = gDirParser.route.overviewPolyline;
	@synchronized (detourRoutesInProgress) {
		[detourRoutesInProgress removeObject:gDirParser];
	}
	gDirParser = nil; // this might be dealloc'd now
	
	[self checkIfRoutingIsComplete];
}

-(void) searchFinished {
	// Nothing to do here
}

-(void) parser:(id)parser didFailWithError:(NSError *)error {
	[GenericParserErrorAlert showAlertForError:error];
}

#pragma mark -
#pragma mark Clean up

-(void) dealloc {
	// iVars
	[context release];
	[detourRouteLegs release];
	[detourRoutesInProgress release];
	
	// Properties
	self.delegate = nil;
	self.route = nil;
	self.redZones = nil;
	
	[super dealloc];
}

@end
