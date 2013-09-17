//
//  MapStateViewController.h
//  ScenicRoute
//
//  Created by Seb on 10-10-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "POIAnnotation.h"

@class MapViewBaseViewController;

@interface MapStateViewController : UIViewController {
	IBOutlet MKMapView *mapView;
	IBOutlet UINavigationBar *navBar;
	IBOutlet UINavigationItem *navBarTitleItem;
	IBOutlet UISegmentedControl *viewSegmentControl;
	IBOutlet MapViewBaseViewController *searchViewController;
	IBOutlet MapViewBaseViewController *directionsViewController;
	IBOutlet UIBarButtonItem *gpsButton;
	IBOutlet UINavigationBar *mainNavBar;
	IBOutlet UIView *waitView;
	IBOutlet UIActivityIndicatorView *waitViewSpinner;
	
	NSInteger _lastSelectedViewIndex;
}

@property(nonatomic, assign)	MKMapView *mapView;
@property(nonatomic, assign)	UINavigationBar *navBar;
@property(nonatomic, assign)	UINavigationItem *navBarTitleItem;
@property(nonatomic, assign)	UISegmentedControl *viewSegmentControl;
@property(nonatomic, assign)	MapViewBaseViewController *searchViewController;
@property(nonatomic, assign)	MapViewBaseViewController *directionsViewController;
@property(nonatomic, assign)    UIBarButtonItem *gpsButton;
@property(nonatomic, assign)    UIView *waitView;
@property(nonatomic, assign)	UIActivityIndicatorView *waitViewSpinner;

- (void) createPOIAnnotationView:(POIAnnotation*)poi;

// View manipulation
- (MapViewBaseViewController*) viewControllerForSegmentIndex:(NSInteger)index;
- (UIView*) topBarViewForSegmentIndex:(NSInteger)index;
- (void) repositionTopBarViews;
- (void) activateMapView:(NSInteger)mapViewIndex animated:(BOOL)animated;
- (void) clearAnnotations;

// Actions
- (IBAction)viewSegmentAction:(id)sender;
- (IBAction)toggleUserLocation:(id)sender;

// Events
- (void) EnableDirectionFromHere: (NSNotification *)notification;
- (void) EnableDirectionToHere: (NSNotification *)notification;
- (void) showWaitView:(NSNotification*)notification;
- (void) hideKeyboard:(NSNotification*)notification;

@end
