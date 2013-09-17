//
//  GoogleRouteLeg.m
//  ScenicRoute
//
//  Created by Seb on 10-11-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GoogleRouteLeg.h"


@implementation GoogleRouteLeg

@synthesize startAddress;
@synthesize endAddress;
@synthesize duration;	
@synthesize distance;	
@synthesize startLocation;
@synthesize endLocation;
@synthesize steps;

- (void) dealloc {
	[startAddress release];
	[endAddress release];
	[steps release];
	
	[super dealloc];
}

@end
