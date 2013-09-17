//
//  DetourOverlay.m
//  ScenicRoute
//
//  Created by Seb on 10-11-01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DetourOverlay.h"


@implementation DetourOverlay

@synthesize boundingMapRect, coordinate;

+ (DetourOverlay*)detourOverlayWithPoints:(MKMapPoint *)points count:(NSUInteger)count {
	return (DetourOverlay*)[[self class] polylineWithPoints:points count:count];
}

-(CLLocationCoordinate2D ) firstCoordinate {
	return MKCoordinateForMapPoint(self.points[0]);
}

-(CLLocationCoordinate2D ) lastCoordinate {
	return MKCoordinateForMapPoint(self.points[self.pointCount - 1]);
}

// Calculates a MKMapRect that will fit the entire polyline
-(MKMapRect) boundingMapRect {
	double leftMost = 0;
	double rightMost = 0;
	double topMost = 0;
	double bottomMost = 0;
	for (int i=0; i < self.pointCount; i++) {
		MKMapPoint point = self.points[i];
		if (leftMost == 0 || point.x < leftMost) {
			leftMost = point.x;
		}
		if (rightMost == 0 || point.x > rightMost) {
			rightMost = point.x;
		}
		if (topMost == 0 || point.y > topMost) {
			topMost = point.y;
		}
		if (bottomMost == 0 || point.y < bottomMost) {
			bottomMost = point.y;
		}
	}
	
	MKMapRect rect;
	rect.origin.x = leftMost;
	rect.origin.y = bottomMost;
	rect.size.width = abs(rightMost - leftMost);
	rect.size.height = abs(topMost - bottomMost);
	
	return rect;
}

-(CLLocationCoordinate2D) coordinate {
	MKCoordinateRegion region = MKCoordinateRegionForMapRect([self boundingMapRect]);
	return region.center;	
}

- (MKPolylineView*)view {
	// Instantiate the view
	MKPolylineView *view = [[[MKPolylineView alloc] initWithPolyline:self] autorelease];
	view.fillColor = [UIColor blueColor];
	view.strokeColor = [UIColor colorWithRed:0.0 green:0 blue:1.0 alpha:0.6];
	view.lineWidth = 4;
	
	// Don't retain a reference, the map will take care of this for us and only
	// ask again when it needs to re-instantiate.
	return view;
}

@end
