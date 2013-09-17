//
//  HighwayRampRect.h
//  ScenicRoute
//
//  Created by Seb on 10-12-06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

#import "HighwayRamp.h"

@interface HighwayRampRect :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * topLeftLat;
@property (nonatomic, retain) NSNumber * topLeftLng;
@property (nonatomic, retain) NSNumber * bottomRightLat;
@property (nonatomic, retain) NSNumber * bottomRightLng;
@property (nonatomic, retain) HighwayRamp * ramp;

@end



