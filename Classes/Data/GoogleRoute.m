//
//  GoogleRoute.m
//  ScenicRoute
//
//  Created by Seb on 10-11-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GoogleRoute.h"
#import "GoogleRouteLeg.h"


@implementation GoogleRoute

@synthesize summary;
@synthesize legs;
@synthesize copyright;
@synthesize overviewPolyline;
@synthesize overviewPolylineEncoded;

-(NSInteger) duration {
	NSInteger duration = 0;
	for (GoogleRouteLeg *leg in self.legs) {
		duration += leg.duration;
	}
	return duration;
}

-(NSInteger) distance {
	NSInteger distance = 0;
	for (GoogleRouteLeg *leg in self.legs) {
		distance += leg.distance;
	}
	return distance;	
}

- (void) dealloc
{
	[summary release];
	[legs release];
	[copyright release];
	[overviewPolyline release];
	
	[super dealloc];
}


@end
