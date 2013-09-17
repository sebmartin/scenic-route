//
//  HighwayNamedExit.h
//  ScenicRoute
//
//  Created by Seb on 10-12-14.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "Highway.h"

@interface HighwayNamedExit :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * number;
@property (nonatomic, retain) NSNumber * latitude;
@property (nonatomic, retain) NSNumber * longitude;
@property (nonatomic, retain) Highway * highway;

@end



