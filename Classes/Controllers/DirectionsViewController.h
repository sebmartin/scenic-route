//
//  DirectionsViewController.h
//  ScenicRoute
//
//  Created by Seb on 10-10-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import	"MapViewBaseViewController.h"
#import	"DataParserDelegate.h"
#import "MapStateViewController.h"
#import "RouteEndAnnotation.h"
#import "RouterDelegate.h"

@class DetourOverlay;
@class GoogleRoute;

@interface DirectionsViewController : MapViewBaseViewController<DataParserDelegate, UITextFieldDelegate, RouterDelegate> {
	IBOutlet MapStateViewController *mapStateController;
	DetourOverlay *currentRoute;
	
	UITextField *originTextField;
	UITextField *destinationTextField;
	
	RouteEndAnnotation	*originAnnotation;
	RouteEndAnnotation	*destinationAnnotation;
	DetourOverlay		*routeOverlay;
	
	BOOL			 redZonesEnabled;
	NSMutableDictionary *redZones;
}

@property (nonatomic, retain) DetourOverlay *currentRoute;
@property (nonatomic, retain) MapStateViewController *mapStateController;

@property (nonatomic, assign) IBOutlet UITextField *originTextField;
@property (nonatomic, assign) IBOutlet UITextField *destinationTextField;

@property (nonatomic, retain) RouteEndAnnotation *originAnnotation;
@property (nonatomic, retain) RouteEndAnnotation *destinationAnnotation;
@property (nonatomic, retain) DetourOverlay *routeOverlay;

@property (nonatomic, assign) BOOL redZonesEnabled;
@property (nonatomic, readonly) NSArray *redZoneAnnotations;
@property (nonatomic, retain) NSMutableDictionary *redZones;

- (IBAction)swapDestinations:(id)sender;
- (IBAction)editingDidStart:(id)sender;

- (void)directionsFrom:(NSString*)origin to:(NSString*)destination;
- (void)setHighwayOverlay:(DetourOverlay*)overlay centerMap:(BOOL)centerMap;
- (void)showRedZoneForHighwayNamed:(NSString*)highwayName;
- (void)highwayExitAnnotationCoordinateDidChange:(NSNotification*)notification;
- (void)hideKeyboard:(NSNotification*)notification;

- (void)setOriginText: (NSString*)address;
- (void)setDestinationText: (NSString*)address;
- (void)routerDidFinish:(HighwayDetourRouter*)router;

@end
