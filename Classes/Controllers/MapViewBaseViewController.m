//
//  MapViewBaseViewController.m
//  ScenicRoute
//
//  Created by Seb on 10-10-20.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "MapViewBaseViewController.h"


@implementation MapViewBaseViewController

@synthesize mapView = _mapView;

#pragma mark -
#pragma mark View life cycle

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void)viewWillActivate:(NSTimeInterval)seconds {
	// Override by subclass
}

-(void)viewWillDeactivate:(NSTimeInterval)seconds {
	// Override by subclass
}

-(void)viewDidActivate {
	// Override by subclass
}

-(void)viewDidDeactivate {
	// Override by subclass
}

#pragma mark - 
#pragma mark MKMapViewDelegate Implementation


#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[self.mapView release];
    [super dealloc];
}


@end
