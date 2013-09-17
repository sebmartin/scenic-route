//
//  BaseAnnotation.m
//  ScenicRoute
//
//  Created by Seb on 10-11-01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "BaseAnnotation.h"


@implementation BaseAnnotation

@synthesize coordinate, title, subtitle;

#pragma mark -
#pragma mark Initialization

-(id) init {
	//NSAssert(NO, @"BaseAnnotation should not be initialized with the simple 'init' selector");
	return (self = [super init]);
}

#pragma mark -
#pragma mark Accessors

-(MKAnnotationView*)viewForMapView:(MKMapView*)map {
	
	// Try to re-use an existing view
	MKAnnotationView *newView = [map dequeueReusableAnnotationViewWithIdentifier:[self viewIdentifier]];
	if (!newView) {
		// No re-usable views available, alloc a new one
		newView = [[self allocAnnotationView] autorelease];
	}
	newView.annotation = self;
	return newView;
}

#pragma mark -
#pragma mark Override these

// This is can be overriden by the subclass to specify a custom type of annotation
-(MKAnnotationView*)allocAnnotationView {
	// Use a pin as a default view
	MKPinAnnotationView *newView = [[MKPinAnnotationView alloc] initWithAnnotation:self reuseIdentifier:[self viewIdentifier]];
	newView.pinColor = MKPinAnnotationColorGreen;
	newView.animatesDrop = YES;

	return newView;
}

// Used for re-using annotation views
-(NSString*)viewIdentifier {
	return @"BaseAnnotationID";
}

#pragma mark -
#pragma mark Memory management

- (void) dealloc {
	[super dealloc];
}

@end
