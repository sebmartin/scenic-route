//
//  HighwayDetour+Utility.h
//  ScenicRoute
//
//  Created by Seb on 10-12-11.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HighwayDetour.h"
#import "GoogleRoute.h"

@interface HighwayDetour (Utility)

+ (HighwayDetour*)detourFromGoogleRoute:(GoogleRoute*)route;

@end
