//
//  HighwayExitAnnotation.h
//  ScenicRoute
//
//  Created by Seb on 10-12-17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseAnnotation.h"
#import "HighwayNamedExit.h"

#define	kHighwayExitAnnotation_CoordinateDidChange @"highwayExitAnnotation.coordinateDidChange"

@class HighwayRedZoneOverlay;

@interface HighwayExitAnnotation : BaseAnnotation {
	HighwayNamedExit *namedExit;
}

@property (nonatomic, retain) HighwayNamedExit *namedExit;

-(void) setCoordinate:(CLLocationCoordinate2D)coord;
-(void) setCoordinate:(CLLocationCoordinate2D)coord exact:(BOOL)exact;

@end
