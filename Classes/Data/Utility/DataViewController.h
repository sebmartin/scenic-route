//
//  DataViewController.h
//  ScenicRoute
//
//  Created by Seb on 10-12-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HighwayRampRect;

@interface DataViewController : UIViewController<MKMapViewDelegate> {
	MKMapView *mapView;
}

@property(nonatomic, assign) IBOutlet MKMapView *mapView;

- (void)addOverlays;
- (void)addOverlayForRect:(HighwayRampRect*)rect;

@end
