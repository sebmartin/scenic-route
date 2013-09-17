//
//  HighwayRedZoneOverlay.h
//  ScenicRoute
//
//  Created by Seb on 10-12-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HighwayExitAnnotation.h"

// TODO: Finish this class so that it can display a polyline between the two exits
@interface HighwayRedZoneOverlay : MKPolyline<MKOverlay> {
	HighwayExitAnnotation *lowAnnotation;
	HighwayExitAnnotation *highAnnotation;
}

@property (nonatomic, retain) HighwayExitAnnotation *lowAnnotation;
@property (nonatomic, retain) HighwayExitAnnotation *highAnnotation;
@property (nonatomic, readonly) NSArray *annotations;

- (id)initWithLowAnnotation:(HighwayExitAnnotation*)lowAnnotation highAnnotation:(HighwayExitAnnotation*)highAnnotation;

- (void)coordinateDidChangeForAnnotation:(HighwayExitAnnotation*)annotation;

@end
