//
//  RouteRequest.h
//  ScenicRoute
//
//  Created by Seb on 10-12-22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BasicRoute.h"

@interface RouteRequest : BasicRoute {
	CLLocationCoordinate2D startCoordinate;
	CLLocationCoordinate2D endCoordinate;
	NSNumber *step;
}
@property (nonatomic, assign) CLLocationCoordinate2D startCoordinate;
@property (nonatomic, assign) CLLocationCoordinate2D endCoordinate;
@property (nonatomic, retain) NSNumber *step;

@end
