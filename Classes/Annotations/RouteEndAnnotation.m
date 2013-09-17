//
//  RouteEndAnnotation.m
//  ScenicRoute
//
//  Created by Seb on 10-11-17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RouteEndAnnotation.h"


@implementation RouteEndAnnotation

@synthesize endType;

-(MKAnnotationView *) viewForMapView:(MKMapView *)map {
	MKPinAnnotationView *annotation = [[MKPinAnnotationView alloc] initWithAnnotation:self reuseIdentifier:@"RouteStartAnnotation"];
	annotation.pinColor = MKPinAnnotationColorGreen;
	annotation.draggable = YES;
	
	return [annotation autorelease];
}

@end
