//
//  MapViewBaseViewController.h
//  ScenicRoute
//
//  Created by Seb on 10-10-20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

#import "POIAnnotation.h"

/*!
 This is the base class for the SearchViewController and the DirectionsViewController.  It handles
 scenerios that are common to both views.  For instance, when the user touches the map, we need to 
 dismiss the keyboard if it's visible. 
 */
@interface MapViewBaseViewController : UIViewController <MKMapViewDelegate> {
	IBOutlet MKMapView *_mapView;
}

@property (nonatomic, retain) MKMapView *mapView;

-(void)viewWillActivate:(NSTimeInterval)seconds;
-(void)viewWillDeactivate:(NSTimeInterval)seconds;
-(void)viewDidActivate;
-(void)viewDidDeactivate;

@end
