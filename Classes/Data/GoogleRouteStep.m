//
//  GoogleRouteStep.m
//  ScenicRoute
//
//  Created by Seb on 10-11-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GoogleRouteStep.h"


@implementation GoogleRouteStep

@synthesize travelMode;
@synthesize htmlInstructions;
@synthesize duration;
@synthesize distance;
@synthesize startLocation;
@synthesize endLocation;
@synthesize polyline;

-(void) dealloc {
	[travelMode release];
	[htmlInstructions release];
	[polyline release];
	
	[super dealloc];
}

@end
