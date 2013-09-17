//
//  HighwayRedZoneOverlay.m
//  ScenicRoute
//
//  Created by Seb on 10-12-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HighwayRedZoneOverlay.h"

@implementation HighwayRedZoneOverlay

@synthesize lowAnnotation;
@synthesize highAnnotation;

@dynamic boundingMapRect;
@dynamic coordinate;

- (id)initWithLowAnnotation:(HighwayExitAnnotation*)low highAnnotation:(HighwayExitAnnotation*)high {
	if (self = [super init]) {
		self.lowAnnotation = low;
		self.highAnnotation = high;
	}
	return self;
}

-(NSString*)viewIdentifier {
	return @"HighwayRedZoneOverlay";
}

-(NSArray*)annotations {
	return [NSArray arrayWithObjects:lowAnnotation, highAnnotation, nil];
}

- (void)coordinateDidChangeForAnnotation:(HighwayExitAnnotation*)annotation {
	// Send a notification that the red zones changed
	// TODO: update the overlay when we actually have one
}

-(void) dealloc {
	self.lowAnnotation = nil;
	self.highAnnotation = nil;
	
	[super dealloc];
}

@end
