    //
//  DataViewController.m
//  ScenicRoute
//
//  Created by Seb on 10-12-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import <MapKit/MapKit.h>
#import "DataViewController.h"
#import "DataUtilityAppDelegate.h"
#import "HighwayRampRect.h"
#import "AppData.h"


@implementation DataViewController

@synthesize mapView;

- (void)awakeFromNib {
	// Listen for event when data is updated
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(didFinishLoadingMetaData:)
												 name:@"didFinishLoadingMetaData" 
											   object:nil];

	// Center the map around Ottawa
	// -- These values are taken from google maps, just generate a static URL and look at the parameters
	MKCoordinateRegion ottawaRegion;
	ottawaRegion.center.latitude = 45.38109;
	ottawaRegion.center.longitude = -75.698547;
	ottawaRegion.span.latitudeDelta = 0.271048;
	ottawaRegion.span.longitudeDelta = 0.435333;
	mapView.region = ottawaRegion;	
}

- (void)didFinishLoadingMetaData:(NSNotification*)notification {
	[self performSelectorInBackground:@selector(addOverlays) withObject:nil];
}

- (void)addOverlays {
	NSAutoreleasePool *pool = [NSAutoreleasePool new];
	
	DataUtilityAppDelegate *delegate = (DataUtilityAppDelegate*)[[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *context = delegate.database.context;
	
	NSError *error = nil;
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:@"HighwayRampRect" inManagedObjectContext:context]];

	// TEMP -- this will only load 10 rects.. the 10 that are the most towards the west
	[request setFetchLimit:10];
	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"topLeftLng" ascending:YES]]];
	// END TEMP, TODO: make this so that the user can click on an exit to get only the info for that exit
	
	NSArray *rects = [context executeFetchRequest:request error:&error];
	if (!error) {
		for (HighwayRampRect *rect in rects) {
			[self performSelectorOnMainThread:@selector(addOverlayForRect:) withObject:rect waitUntilDone:YES];
		}
	}
	
	[pool drain];
	
}

- (void)addOverlayForRect:(HighwayRampRect*)rect {

	CLLocationCoordinate2D coords[5];
	coords[0].latitude = coords[4].latitude = [rect.topLeftLat doubleValue];
	coords[0].longitude = coords[4].longitude = [rect.topLeftLng doubleValue];
	coords[1].latitude = [rect.topLeftLat doubleValue];
	coords[1].longitude = [rect.bottomRightLng doubleValue];
	coords[2].latitude = [rect.bottomRightLat doubleValue];
	coords[2].longitude = [rect.bottomRightLng doubleValue];
	coords[3].latitude = [rect.bottomRightLat doubleValue];
	coords[3].longitude = [rect.topLeftLng doubleValue];
	
	MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coords count:5];
	
	[self.mapView addOverlay:polyline];
}

- (MKOverlayView *) mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	if ([overlay isKindOfClass:[MKPolyline class]]) {
		MKPolylineView *view = [[[MKPolylineView alloc] initWithPolyline:overlay] autorelease];
		view.strokeColor = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:0.6];
		view.lineWidth = 2;
		return view;
	}
	return nil;
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}


@end
