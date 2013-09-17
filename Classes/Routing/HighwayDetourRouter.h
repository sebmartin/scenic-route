//
//  HighwayDetourRouter.h
//  ScenicRoute
//
//  Created by Seb on 10-12-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "DataParserDelegate.h"
#import "BasicRoute.h"
#import "GoogleRoute.h"

/**
 * This class will calculate an alternate route to avoid the highway
 * zones that are identified by the redZones property.  This property
 * is an array containing an inner array for each zone to avoid.  The 
 * inner array contains exactly two HighwayNamedExit objects; one for each
 * end of the zone to avoid.
 *
 * NOTE: this class only supports one red zone at the moment and only
 *   supports highway 417 in Ottawa.
 */
@interface HighwayDetourRouter : NSObject<DataParserDelegate> {

	id						 delegate;
	NSManagedObjectContext	*context;

	GoogleRoute				*route;			// The route to find an alternative for
	NSDictionary			*redZones;      // Array of zones to avoid
	
	// Used for detecting red zone overlap
	CLLocationCoordinate2D	 startPosition;
	CLLocationCoordinate2D	 endPosition;
	NSMutableArray			*detourPoints;
	NSMutableDictionary		*accessedRamps;		// Key is the highway name, objects are arrays of HighwayRamp instances
	
	// Used for routing alternatives
	BOOL					 avoidEntireHighway;		// This is a temp solution for detecting when we need to avoid an entire high
														// TODO: It will have to be re-evaluated when we add multi highway support
	NSMutableArray			*detourRouteLegs;			// Array of DetourRoute for each leg of the final route
														// This also includes duplicate legs that need to be compared
	NSMutableArray			*detourRoutesInProgress;	// Array of DetourRoute objects that are currently being routed
	volatile BOOL			 didQueueAllRouteRequests;  // Set to YES once all DetourRoute objects have been added to the arrays
	
	// The final route polyline
	BasicRoute				*finalRoutePolyline;
}

@property (nonatomic, retain) id				 delegate;
@property (nonatomic, retain) GoogleRoute		*route;
@property (nonatomic, retain) NSDictionary		*redZones;
@property (nonatomic, retain) NSMutableArray	*detourPoints;
@property (nonatomic, retain) BasicRoute		*finalRoute;

- (id)initWithManagedObjectContext:(NSManagedObjectContext*)dbContext;
- (void)findAlternateRoute;
- (void)detectHighwayAccess;
- (void)detectIntersectionWithRedZones;

@end
