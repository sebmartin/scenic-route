//
//  HighwayExitAnnotation.m
//  ScenicRoute
//
//  Created by Seb on 10-12-17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "HighwayExitAnnotation.h"
#import "ScenicRouteAppDelegate.h"
#import "HighwayNamedExit.h"

@interface HighwayExitAnnotation (private)
-(void)coordinateDidChange;
@end

@implementation HighwayExitAnnotation

@synthesize namedExit;

-(MKAnnotationView *) viewForMapView:(MKMapView *)map {
	MKAnnotationView *view = [super viewForMapView:map];
	
	if ([view isKindOfClass:[MKPinAnnotationView class]]) {
		[(MKPinAnnotationView*)view setPinColor:MKPinAnnotationColorRed];
	}
	view.draggable = YES;
	
	return view;
}

-(NSString*)viewIdentifier {
	return @"HighwayExitAnnotation";
}

/**
 * If exact == NO then the pin will be placed on the exit that is closest to 'coord'
 */
-(void) setCoordinate:(CLLocationCoordinate2D)coord exact:(BOOL)exact {
	if (exact) {
		[super setCoordinate:coord];
	}
	else {
		[self setCoordinate:coord];
	}
	[self coordinateDidChange];
}

-(void) setCoordinate:(CLLocationCoordinate2D)coord {

	// Find the closest exit
	// For now, we'll fetch each exit and test them one at a time.  
	// TODO: We can later improve this to fetch any exit within a given RECT.  If none found, make the rect bigger and repeat until
	//   we get some matches
	ScenicRouteAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *context = appDelegate.database.context;
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:@"HighwayNamedExit" inManagedObjectContext:context]];

	NSError *error = nil;
	NSArray *exits = [context executeFetchRequest:request error:&error];
	if (error) {
		// TODO: handle error
		return;
	}
	HighwayNamedExit *closestExit = nil;
	CLLocationDegrees shortestDistanceToExit = -1;
	for (HighwayNamedExit *exit in exits) {
		CLLocationDegrees distanceToExit = 
			sqrt(
				 pow(coord.latitude - [exit.latitude doubleValue], 2) + 
				 pow(coord.longitude - [exit.longitude doubleValue], 2)
				 );
		if (shortestDistanceToExit < 0 || distanceToExit < shortestDistanceToExit) {
			shortestDistanceToExit = distanceToExit;
			closestExit = exit;
		}
	}
	
	self.namedExit = closestExit;
	CLLocationCoordinate2D newCoord = CLLocationCoordinate2DMake([closestExit.latitude doubleValue], 
																 [closestExit.longitude doubleValue]);
	[self coordinateDidChange];
	
	NSLog(@"Dropping pin at exit: %@", self.namedExit.number);
	[super setCoordinate:newCoord];
}

-(void)coordinateDidChange {
	[[NSNotificationCenter defaultCenter] postNotificationName:kHighwayExitAnnotation_CoordinateDidChange object:self];
}

-(void) dealloc {
	self.namedExit = nil;
	
	[super dealloc];
}

@end
