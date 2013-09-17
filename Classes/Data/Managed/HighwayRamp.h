//
//  HighwayRamp.h
//  ScenicRoute
//
//  Created by Seb on 10-12-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class Highway;
@class HighwayDetour;
@class HighwayRampRect;

@interface HighwayRamp :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSString * type;
@property (nonatomic, retain) NSString * direction;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* outBoundDetours;
@property (nonatomic, retain) NSSet* inBoundDetours;
@property (nonatomic, retain) Highway * highway;
@property (nonatomic, retain) NSSet* rampRects;

@end


@interface HighwayRamp (CoreDataGeneratedAccessors)
- (void)addOutBoundDetoursObject:(HighwayDetour *)value;
- (void)removeOutBoundDetoursObject:(HighwayDetour *)value;
- (void)addOutBoundDetours:(NSSet *)value;
- (void)removeOutBoundDetours:(NSSet *)value;

- (void)addInBoundDetoursObject:(HighwayDetour *)value;
- (void)removeInBoundDetoursObject:(HighwayDetour *)value;
- (void)addInBoundDetours:(NSSet *)value;
- (void)removeInBoundDetours:(NSSet *)value;

- (void)addRampRectsObject:(HighwayRampRect *)value;
- (void)removeRampRectsObject:(HighwayRampRect *)value;
- (void)addRampRects:(NSSet *)value;
- (void)removeRampRects:(NSSet *)value;

@end

