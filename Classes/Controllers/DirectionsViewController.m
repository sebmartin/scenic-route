//
//  DirectionsViewController.m
//  ScenicRoute
//
//  Created by Seb on 10-10-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DirectionsViewController.h"
#import "ScenicRouteAppDelegate.h"
#import "MapStateViewController.h"
#import "BasicRoute.h"
#import "HighwayNamedExit.h"
#import "HighwayExitAnnotation.h"
#import "HighwayDetourRouter.h"
#import "HighwayRedZoneOverlay.h"
#import "DetourOverlay.h"
#import "GenericParserErrorAlert.h"

// TEMP FOR TESTING
#import "DetourOverlay.h"
#import "GoogleDirectionsDataParser.h"
#import "GoogleRoute.h"
#import "GoogleRouteLeg.h"
#import "RouteEndAnnotation.h"

@interface DirectionsViewController (private)

+(void) string:(NSString*)string toCoordinates:(CLLocationCoordinate2D**)coordsOut count:(NSUInteger*)coordsLenOut;

@end


@implementation DirectionsViewController

// Here for the protocol, but this is declared in the parent class
@dynamic mapView;

@synthesize currentRoute;
@synthesize mapStateController;
@synthesize redZoneAnnotations;

@synthesize originTextField;
@synthesize destinationTextField;

@synthesize originAnnotation;
@synthesize destinationAnnotation;
@synthesize routeOverlay;
@synthesize redZonesEnabled;
@synthesize redZones;

#pragma mark -
#pragma mark View life cycle and controller methods

-(void)awakeFromNib {
	self.redZonesEnabled = YES;
	self.redZones = [NSMutableDictionary dictionary];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(highwayExitAnnotationCoordinateDidChange:)
												 name:kHighwayExitAnnotation_CoordinateDidChange
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(hideKeyboard:)
												 name:@"hideKeyboard"
											   object:nil];	
	
	// Set search bar background image
	UIColor *background = [[UIColor alloc] initWithPatternImage:[UIImage imageNamed:@"destination-bg.png"]];
	self.view.backgroundColor = background;
	[background release];
	
}

- (void)viewDidUnload {
    [super viewDidUnload];
	
    self.originTextField = nil;
	self.destinationTextField = nil;
	self.mapStateController = nil;
}

- (void)hideKeyboard:(NSNotification*)notification {	
	[originTextField resignFirstResponder];
	[destinationTextField resignFirstResponder];
}

-(NSArray*)redZoneAnnotations {
	NSMutableArray *annotations = [NSMutableArray array];
	for (HighwayRedZoneOverlay *redZone in self.redZones) {
		for (HighwayExitAnnotation *annotation in redZone.annotations) {
			[annotations addObject:annotation];
		}
	}
	return annotations;
}

#pragma mark -
#pragma mark Map and directions methods

- (void)setOriginText: (NSString*)address {
	if(address == nil) return;
	self.originTextField.text = address;	
}

- (void)setDestinationText: (NSString*)address {
	if(address == nil) return;
	self.destinationTextField.text = address;
}

- (IBAction)swapDestinations:(id)sender {
    NSLog(@"Swap button was pressed");	
	NSString *tempString = originTextField.text;
	originTextField.text = destinationTextField.text;
	destinationTextField.text = tempString;
	
	// Trigger Search
	if([originTextField.text compare:@""] != NSOrderedSame && 
	   [destinationTextField.text compare:@""] != NSOrderedSame)
		[self textFieldShouldReturn: originTextField];
	
}

- (void)directionsFrom:(NSString*)origin to:(NSString*)destination {
	// Call the google directions API.
	NSLog(@"Getting directions from: [%@] to [%@]", origin, destination);
	GoogleDirectionsDataParser *gDirParser = [[GoogleDirectionsDataParser alloc] init];
	gDirParser.delegate = self;
	[gDirParser fetchDataForOrigin:origin destination:destination];
	
	// Show the wait view
	[[NSNotificationCenter defaultCenter] postNotification:
	 [NSNotification notificationWithName:@"ShowWaitView" object:self userInfo:
	  [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"show", nil]]];
}

- (void)recalculateCurrentRoute {
	if (!self.currentRoute) {
		return;
	}
	
	NSString *origin =		[NSString stringWithFormat:@"%f,%f", 
							 self.currentRoute.firstCoordinate.latitude, self.currentRoute.firstCoordinate.longitude];
	NSString *destination = [NSString stringWithFormat:@"%f,%f", 
							 self.currentRoute.lastCoordinate.latitude, self.currentRoute.lastCoordinate.longitude];
	[self directionsFrom:origin to:destination];
}

- (void)setHighwayOverlay:(DetourOverlay*)overlay centerMap:(BOOL)centerMap {
	
	// Clear existing overlay and annotations (if any)
	if (self.routeOverlay) {
		[self.mapView removeOverlay:self.routeOverlay];
		self.routeOverlay = nil;
	}
	if (self.originAnnotation) {
		[self.mapView removeAnnotation:self.originAnnotation];	
		self.originAnnotation = nil;
	}
	if (self.destinationAnnotation) {
		[self.mapView removeAnnotation:self.destinationAnnotation];	
		self.destinationAnnotation = nil;
	}
	
	// Add the polyline(s) to the map
	self.routeOverlay = overlay;
	[self.mapView addOverlay:overlay];
	
	// Add an annotation to start of the route
	RouteEndAnnotation *startAnnotation = [[RouteEndAnnotation alloc] init];
	startAnnotation.endType = RouteEndAnnotationOrigin;
	NSInteger startPointIndex = [overlay pointCount]-1;
	CLLocationCoordinate2D startCoord = MKCoordinateForMapPoint(overlay.points[startPointIndex]);
	startAnnotation.coordinate = startCoord;
	self.originAnnotation = startAnnotation;
	[self.mapView addAnnotation:startAnnotation];
	
	// Add an annotation to the end of the route
	RouteEndAnnotation *endAnnotation = [[RouteEndAnnotation alloc] init];
	startAnnotation.endType = RouteEndAnnotationDestination;
	NSInteger endPointIndex = 0;
	CLLocationCoordinate2D endCoord = MKCoordinateForMapPoint(overlay.points[endPointIndex]);
	endAnnotation.coordinate = endCoord;
	self.destinationAnnotation = endAnnotation;
	[self.mapView addAnnotation:endAnnotation];
	
	// Center the map on the overlay
	if (centerMap == YES) {
		[self.mapView setVisibleMapRect:[overlay boundingMapRect]];
	}
}

-(void)showRedZoneForHighwayNamed:(NSString*)highwayName {
	// If annotations already exist for this highway, we'll simply display it
	HighwayRedZoneOverlay *overlay = [self.redZones objectForKey:highwayName];
	if (overlay != nil) {
		for (HighwayExitAnnotation *annotation in overlay.annotations) {
			[self.mapView addAnnotation:annotation];
		}
		return;
	}
	
	// Get the longest end points
	ScenicRouteAppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *context = appDelegate.database.context;
	NSFetchRequest *request = [NSFetchRequest new];
	[request setEntity:[NSEntityDescription entityForName:@"HighwayNamedExit" inManagedObjectContext:context]];
	NSError *error = nil;
	
	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:YES]]];
	HighwayNamedExit *lowExit = [[context executeFetchRequest:request error:&error] objectAtIndex:0];
	if (error) {
		// TODO: handle error
	}
	[request setSortDescriptors:[NSArray arrayWithObject:[NSSortDescriptor sortDescriptorWithKey:@"number" ascending:NO]]];
	HighwayNamedExit *highExit = [[context executeFetchRequest:request error:&error] objectAtIndex:0];
	if (error) {
		// TODO: handle error
	}
	
	// Add an annotation for each exit
	HighwayExitAnnotation *lowAnnotation = [[HighwayExitAnnotation alloc] init];
	[lowAnnotation setCoordinate:CLLocationCoordinate2DMake([lowExit.latitude doubleValue], [lowExit.longitude doubleValue]) exact:YES];
	lowAnnotation.namedExit = lowExit; 
	HighwayExitAnnotation *highAnnotation = [[HighwayExitAnnotation alloc] init];
	[highAnnotation setCoordinate:CLLocationCoordinate2DMake([highExit.latitude doubleValue], [highExit.longitude doubleValue]) exact:YES];
	highAnnotation.namedExit = highExit;
	
	// Add the annotations to an overlay
	HighwayRedZoneOverlay *newOverlay = [[HighwayRedZoneOverlay alloc] initWithLowAnnotation:lowAnnotation highAnnotation:highAnnotation];
	[self.redZones setObject:newOverlay forKey:highwayName];
	
	// Add the annotations to the map
	[self.mapView addAnnotation: lowAnnotation];
	[self.mapView addAnnotation: highAnnotation];
	
	[lowAnnotation release];
	[highAnnotation release];
	[overlay release];
	[request release];
}

-(void)displayRouteOnMap:(BasicRoute*)route {
	// Add the results as an overlay on the map

	if (route) {
		// Add new route
		self.currentRoute = [DetourOverlay detourOverlayWithPoints:route.polyline.points count:route.polyline.pointCount];
		[self setHighwayOverlay:self.currentRoute centerMap:NO];
	}
	else {
		// Could not find a route
		// TODO: update the parser to look for a NOT_FOUND response.  Also: OVER_QUERY_LIMIT and others.
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Directions Not Available"
														message:@"Directions could not be found between these locations."
													   delegate:nil 
											  cancelButtonTitle:@"OK"
											  otherButtonTitles:nil];
		[alert show];
	}
}

-(void)highwayExitAnnotationCoordinateDidChange:(NSNotification*)notification {
	// Update the red zone overlay
	for (NSString *highwayName in self.redZones) {
		HighwayRedZoneOverlay *overlay = [self.redZones objectForKey:highwayName];
		if ([overlay.annotations containsObject:notification.object]) {
			[overlay coordinateDidChangeForAnnotation:notification.object];
		}
	}
	
	// Recalculate the route
	[self recalculateCurrentRoute];
}

#pragma mark -
#pragma mark RouterDelegate

- (void)routerDidFinish:(HighwayDetourRouter*)router {
	
	[self displayRouteOnMap:router.finalRoute];
	
	// Hide the wait view
	[[NSNotificationCenter defaultCenter] postNotification:
	 [NSNotification notificationWithName:@"ShowWaitView" object:self userInfo:
	  [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"show", nil]]];
}

#pragma mark -
#pragma mark Overrides

-(void) viewDidActivate {
	
	[self showRedZoneForHighwayNamed:@"ON-417"];
	self.redZonesEnabled = YES;
	
	if (self.currentRoute) {
		[self recalculateCurrentRoute];
	}
	
	// TEMP TEMP TEMP
	//[self directionsFrom:@"1840 D'amour Cres" to:@"165 Wellington, Gatineau"];
	//GoogleDirectionsDataParser *gDirParser = [[GoogleDirectionsDataParser alloc] init];
	//gDirParser.delegate = self;
	//[gDirParser fetchDataFromResource:@"hwy-walkley-vanier" ofType:@"xml"];
	// TEMP TEMP TEMP
}

-(void) viewWillDeactivate:(NSTimeInterval)seconds {
	// remove the overlays and annotations
	[self.mapView removeOverlays:[self.mapView overlays]];
	
	[self.mapView removeAnnotations:[self.mapView annotations]];
}

#pragma mark -
#pragma mark MKMapViewDelegate implementation

- (MKOverlayView *) mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	
	if ([overlay respondsToSelector:@selector(view)]) {
		return [overlay performSelector:@selector(view)];
	}
	return nil;
}

- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	if ([annotation respondsToSelector:@selector(viewForMapView:)]) {
		return [annotation performSelector:@selector(viewForMapView:) withObject:theMapView];
	}
	return nil;
}

- (void) mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)annotationView 
								  didChangeDragState:(MKAnnotationViewDragState)newState 
										fromOldState:(MKAnnotationViewDragState)oldState 
{
	if ([annotationView.annotation isKindOfClass:[RouteEndAnnotation class]]) {
		RouteEndAnnotation *annotation = (RouteEndAnnotation*)annotationView.annotation;
		
		if (newState == MKAnnotationViewDragStateStarting) {
			// Remove the existing overlay when dragging starts
			[mapView removeOverlays: [mapView overlays]];
		}
		
		if (newState == MKAnnotationViewDragStateEnding) {
			// Get new directions
			NSString *origin;
			NSString *destination;
			CLLocationCoordinate2D newCoord = annotation.coordinate;

			if (annotation.endType == RouteEndAnnotationOrigin) {
				CLLocationCoordinate2D endCoord = self.currentRoute.lastCoordinate;
				
				origin = [NSString stringWithFormat:@"%f,%f", newCoord.latitude, newCoord.longitude];
				destination = [NSString stringWithFormat:@"%f,%f", endCoord.latitude, endCoord.longitude];
			}
			else if (annotation.endType == RouteEndAnnotationDestination) {
				CLLocationCoordinate2D startCoord = self.currentRoute.firstCoordinate;
				
				origin = [NSString stringWithFormat:@"%f,%f", startCoord.latitude, startCoord.longitude];
				destination = [NSString stringWithFormat:@"%f,%f", newCoord.latitude, newCoord.longitude];
			}
			
			[self directionsFrom:origin to:destination];
		}
	}
}

// Handle selection of annotation
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	// Make sure annotation is the user location
	if (view.annotation == mapView.userLocation) {
		NSLog(@"GPS Annotation Selected");
		CLLocationCoordinate2D userCoord = mapView.userLocation.location.coordinate;
		NSString *destination = [NSString stringWithFormat:@"%f,%f", userCoord.latitude, userCoord.longitude];
		[self setOriginText:destination];
	}
	
}

#pragma mark -
#pragma mark DataParserDelegate

-(void) parsingFinished:(id)parser {
	if ([parser isKindOfClass:[GoogleDirectionsDataParser class]]) {
		GoogleRoute *route = ((GoogleDirectionsDataParser*)parser).route;
		
		// See if we need to find an alternate route
		ScenicRouteAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
		HighwayDetourRouter *alternateRoute = [[HighwayDetourRouter alloc] initWithManagedObjectContext:delegate.database.context];
		alternateRoute.delegate = self;
		alternateRoute.route = route;
		alternateRoute.redZones = self.redZones;
		[alternateRoute findAlternateRoute];
	}
}

-(void) searchFinished {

}

-(void) parser:(id)parser didFailWithError:(NSError*)error {	
	// Hide the wait view
	[[NSNotificationCenter defaultCenter] postNotification:
	 [NSNotification notificationWithName:@"ShowWaitView" object:self userInfo:
	  [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"show", nil]]];
	
	[GenericParserErrorAlert showAlertForError:error];
}

#pragma mark - UITextFieldDelegate implementation

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	
	if ([self.originTextField.text length] == 0 || [self.destinationTextField.text length] == 0 ) {
		return NO;
	}
	
	// Find a route
	// TODO: This is a quickfix.. instead of appending Ottawa, Ontario, we can call the Google Geocoding API instead
	//   which will give us multiple results for a query.  We can then sort those by distance and default on the closest
	//   one to ottawa.
	NSString *origin = [self.originTextField.text stringByAppendingString: @", Ottawa, Ontario"];
	NSString *destination = [self.destinationTextField.text stringByAppendingString: @", Ottawa, Ontario"];
	[self directionsFrom:origin	to:destination];
	
	// Hide the keyboard
	[self.originTextField resignFirstResponder];
	[self.destinationTextField resignFirstResponder];
	return YES;
}

- (BOOL) textFieldShouldEndEditing:(UITextField *)textField {
	return YES;
}

- (IBAction)editingDidStart:(id)sender {
	[[NSNotificationCenter defaultCenter] postNotification:
	 [NSNotification notificationWithName:@"searchBecameFirstResponder" object:self]];
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[currentRoute release];
	[mapStateController release];
	[redZoneAnnotations release];
	
	[originAnnotation release];
	[destinationAnnotation release];
	[routeOverlay release];
	
	[redZones release];
	
    [super dealloc];
}

@end
