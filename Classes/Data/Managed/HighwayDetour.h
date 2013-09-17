//
//  HighwayDetour.h
//  ScenicRoute
//
//  Created by Seb on 10-12-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class HighwayDetourPoint;
@class HighwayRamp;

@interface HighwayDetour :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * polyline;
@property (nonatomic, retain) NSNumber * distance;
@property (nonatomic, retain) NSNumber * duration;
@property (nonatomic, retain) HighwayRamp * endRamp;
@property (nonatomic, retain) NSSet* steps;
@property (nonatomic, retain) HighwayRamp * startRamp;

@end


@interface HighwayDetour (CoreDataGeneratedAccessors)
- (void)addStepsObject:(HighwayDetourPoint *)value;
- (void)removeStepsObject:(HighwayDetourPoint *)value;
- (void)addSteps:(NSSet *)value;
- (void)removeSteps:(NSSet *)value;

@end

