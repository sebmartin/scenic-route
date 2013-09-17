//
//  MapStateViewController.m
//  ScenicRoute
//
//  Created by Seb on 10-10-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MapStateViewController.h"
#import "MapViewBaseViewController.h"
#import "AnnotationViewController.h"
#import "POIAnnotation.h"

enum {
	kMAPVIEWSEGMENT_SEARCH_INDEX		= 0,
	kMAPVIEWSEGMENT_DIRECTIONS_INDEX	= 1
};

typedef struct {
	MapViewBaseViewController *incomingViewController;
	MapViewBaseViewController *outgoingViewController;
	float seconds;
} ViewSwitchContext;

static const int kTOPBAR_VERT_BASELINE	= 0;		// defines the y position for sliding the top bars in and out.

static const int kMAPVIEW_INDEX_ARRAY[] = {0, 1};


@implementation MapStateViewController

@synthesize mapView;
@synthesize navBar;
@synthesize navBarTitleItem;
@synthesize viewSegmentControl;
@synthesize searchViewController;
@synthesize directionsViewController;
@synthesize gpsButton;
@synthesize waitView;
@synthesize waitViewSpinner;

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	
	// Center the map around Ottawa
	// -- These values are taken from google maps, just generate a static URL and look at the parameters
	MKCoordinateRegion ottawaRegion;
	ottawaRegion.center.latitude = 45.38109;
	ottawaRegion.center.longitude = -75.698547;
	ottawaRegion.span.latitudeDelta = 0.249691;
	ottawaRegion.span.longitudeDelta = 0.570602;
	mapView.region = ottawaRegion;
	
	// Set Default state of GPS button (0=off, 1=on)
	gpsButton.tag = 0;
	
	self.title = @"Map";
	
	// Add Event Listener
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(EnableDirectionFromHere:) 
												 name:@"AnnotationDirectionFromHere" 
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(EnableDirectionToHere:) 
												 name:@"AnnotationDirectionToHere" 
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(showWaitView:)
												 name:@"ShowWaitView"
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(searchBecameFirstResponder:) 
												 name:@"searchBecameFirstResponder"
											   object:nil];

	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(hideKeyboard:) 
												 name:@"hideKeyboard"
											   object:nil];
	
	// Place the top bar views
	_lastSelectedViewIndex = -1;
	[self repositionTopBarViews];
	[self activateMapView: kMAPVIEWSEGMENT_SEARCH_INDEX animated:NO];
	
    [super viewDidLoad];
}

// Creates an Annotation View Controller and pushes it on the Navigation Controller
// stack
-(void)createPOIAnnotationView:(POIAnnotation*)poi { 
	AnnotationViewController *newView = [[AnnotationViewController alloc] initWithAnnotation:poi];
	[self.navigationController pushViewController:newView animated:YES];
	[newView release];
}

// Handle incoming event from Annotation Controller 
- (void) EnableDirectionFromHere: (NSNotification *)notification {
	NSString *address = [[notification userInfo] valueForKey:@"address"];
	NSLog(@"Received Event from Annotation FROM HERE: %@", address);
	
	viewSegmentControl.selectedSegmentIndex = 1;	
	[self clearAnnotations];
	
	if ([directionsViewController respondsToSelector:@selector(setOriginText:)]) {
		[directionsViewController performSelector:@selector(setOriginText:) withObject:address];
	}
	if ([directionsViewController respondsToSelector:@selector(setDestinationText:)]) {
		[directionsViewController performSelector:@selector(setDestinationText:) withObject:@""];
	}

}

// Handle incoming event from Annotation Controller
- (void) EnableDirectionToHere: (NSNotification *)notification {
	NSString *address = [[notification userInfo] valueForKey:@"address"];
	NSLog(@"Received Event from Annotation TO HERE: %@", address);	
	
	viewSegmentControl.selectedSegmentIndex = 1;
	[self clearAnnotations];
	if ([directionsViewController respondsToSelector:@selector(setDestinationText:)]) {
		[directionsViewController performSelector:@selector(setDestinationText:) withObject:address];
	}
	if ([directionsViewController respondsToSelector:@selector(setOriginText:)]) {
		[directionsViewController performSelector:@selector(setOriginText:) withObject:@""];
	}
	
}

- (void)hideKeyboard:(NSNotification*)notification {
	waitView.hidden = YES;
}

#pragma mark -
#pragma mark Acive view manipulation

- (MapViewBaseViewController*) viewControllerForSegmentIndex:(NSInteger)index {
	switch (index) {
		case kMAPVIEWSEGMENT_SEARCH_INDEX:
			return [self searchViewController];

		case kMAPVIEWSEGMENT_DIRECTIONS_INDEX:
			return [self directionsViewController];
	}
	return nil;
}

- (UIView*) topBarViewForSegmentIndex:(NSInteger)index {
	return [[self viewControllerForSegmentIndex:index] view];
}

- (void) repositionTopBarViews {
	// Position the nav bar that is used in multiple map views
	if (navBar) {
		NSInteger yOffset = kTOPBAR_VERT_BASELINE - 1 * self.navBar.bounds.size.height;
		CGSize frameSize = self.navBar.frame.size;
		self.navBar.frame = CGRectMake(0, yOffset, frameSize.width, frameSize.height);
		self.navBar.alpha = 0.0;
	}
	
	// Position top bars
	for (NSInteger i=0; i < sizeof(kMAPVIEW_INDEX_ARRAY)/sizeof(int); i++) {
		UIView *topBarView = [self topBarViewForSegmentIndex:i];
		
		NSInteger yOffset = kTOPBAR_VERT_BASELINE;
		if (_lastSelectedViewIndex == -1 || topBarView != [self topBarViewForSegmentIndex:_lastSelectedViewIndex]) {
			yOffset = kTOPBAR_VERT_BASELINE - 1 * topBarView.bounds.size.height;
		}
		CGSize frameSize = topBarView.frame.size;
		topBarView.frame = CGRectMake(0, yOffset, frameSize.width, frameSize.height);
	}
}

- (void) activateMapView:(NSInteger)mapViewIndex animated:(BOOL)animated {
	[self clearAnnotations];
	
	MapViewBaseViewController *incomingViewController = [self viewControllerForSegmentIndex:mapViewIndex];
	MapViewBaseViewController *outgoingViewController = nil;
	if (_lastSelectedViewIndex > -1) {
		outgoingViewController = [self viewControllerForSegmentIndex:_lastSelectedViewIndex];
	}
	
	[self repositionTopBarViews];
	
	// Notify each controller that their view will be activated/deactivated
	NSTimeInterval seconds = 0.3;
	[incomingViewController viewWillActivate:seconds];
	[outgoingViewController viewWillDeactivate:seconds];
	
	// Animate the switching of search bars
	if (animated) {
		ViewSwitchContext contextData;
		contextData.incomingViewController = incomingViewController;
		contextData.outgoingViewController = outgoingViewController;
		contextData.seconds = seconds;
		NSValue *context = [NSValue value:&contextData withObjCType:@encode(ViewSwitchContext)];
		[context retain];
		
		[UIView beginAnimations:@"viewSwitchAnimation" context:context];
		[UIView	setAnimationDuration:seconds];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationWillStartSelector:@selector(viewAnimationWillStart:context:)];
		[UIView setAnimationDidStopSelector:@selector(viewAnimationDidStop:finished:context:)];
	}
	
	UIView *incomingView = [incomingViewController view];
	UIView *outgoingView = [outgoingViewController view];
	
	NSInteger yOffset = kTOPBAR_VERT_BASELINE;
	CGSize frameSize = incomingView.frame.size;
	[incomingView setFrame:	CGRectMake(0, yOffset, frameSize.width, frameSize.height)];
	[incomingView setAlpha:1.0];
	
	if (outgoingView) {
		yOffset = kTOPBAR_VERT_BASELINE - 1 * outgoingView.bounds.size.height;
		frameSize = outgoingView.frame.size;
		[outgoingView setFrame:	CGRectMake(0, yOffset, frameSize.width, frameSize.height)];
		[outgoingView setAlpha:0.0];
	}
	
	if (animated) {
		[UIView commitAnimations];
	}
	
	// Remember the new selection as the last selected view index
	_lastSelectedViewIndex = mapViewIndex;
	
	// Set the new view's controller as the delegate for the map control
	// -- any view controller that can be assigned here must implement the MKMapViewDelegate protocol!
	// -- consider creating a base class here
	mapView.delegate = (id<MKMapViewDelegate>)incomingViewController;
	navBarTitleItem.title = incomingViewController.title;
}

- (void)viewAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	ViewSwitchContext contextData;
	[(NSValue*)context getValue:&contextData];
	
	if (finished) {
		[contextData.incomingViewController viewDidActivate];
		[contextData.outgoingViewController viewDidDeactivate];
	}
	
	[(NSValue*)context release];
	
}

- (void)viewAnimationWillStart:(NSString *)animationID context:(void *)context {
	ViewSwitchContext contextData;
	[(NSValue*)context getValue:&contextData];	
	
	NSTimeInterval seconds = contextData.seconds;
	[contextData.incomingViewController viewWillActivate:seconds];
	[contextData.outgoingViewController viewWillDeactivate:seconds];
}

// Removes all annotations but the user location annotation
- (void) clearAnnotations {
	
	NSMutableArray *locs = [[NSMutableArray alloc] init];
	for (id <MKAnnotation> annot in [mapView annotations])
	{
		if ( [annot isKindOfClass:[ MKUserLocation class]] ) {
		}
		else {
			[locs addObject:annot];
		}
	}
	[mapView removeAnnotations:locs];
	[locs release];
	locs = nil;
	
}

- (void) showWaitView:(NSNotification*)notification {
	waitView.frame = waitView.superview.bounds;
	
	if ([notification userInfo]) {
		NSDictionary *userInfo = [notification userInfo];
		NSNumber *showFlag = [userInfo valueForKey:@"show"];
		if (showFlag) {
			if ([showFlag intValue] == 0) {
				waitView.hidden = YES;
				[waitViewSpinner stopAnimating];
			}
			else {
				waitView.hidden = NO;
				[waitViewSpinner startAnimating];
			}

		}
	}
}

- (void) searchBecameFirstResponder:(NSNotification*)notification {
	waitView.frame = waitView.superview.bounds;
	[waitViewSpinner stopAnimating];
	waitView.hidden = NO;
}

#pragma mark -
#pragma mark Actions

- (IBAction)viewSegmentAction:(id)sender {
	[self activateMapView:[sender selectedSegmentIndex] animated:YES];
}

// Toggle User Location on/off 
- (IBAction)toggleUserLocation:(id)sender {
	
	// Toggle User Location
	if (gpsButton.tag == 0) {
		// turn on location
		mapView.showsUserLocation = YES;
		gpsButton.style = UIBarButtonItemStyleDone;
		gpsButton.tag = 1;
	} else {
		mapView.showsUserLocation = NO;
		gpsButton.style = UIBarButtonItemStyleBordered;
		gpsButton.tag = 0;
	}
	
}

#pragma mark -
#pragma mark Memory management

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
