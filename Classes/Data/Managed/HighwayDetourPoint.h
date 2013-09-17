//
//  HighwayDetourPoint.h
//  ScenicRoute
//
//  Created by Seb on 10-12-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>

@class HighwayDetour;

@interface HighwayDetourPoint :  NSManagedObject  
{
}

@property (nonatomic, retain) NSNumber * order;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) HighwayDetour * detour;

@end



