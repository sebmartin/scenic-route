//
//  RouteRequest.m
//  ScenicRoute
//
//  Created by Seb on 10-12-22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "RouteRequest.h"


@implementation RouteRequest

@synthesize startCoordinate;
@synthesize endCoordinate;
@synthesize step;

-(void) dealloc {
	self.step = nil;
	self.polyline = nil;
	[super dealloc];
}

@end
