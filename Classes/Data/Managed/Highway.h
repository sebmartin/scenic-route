//
//  Highway.h
//  ScenicRoute
//
//  Created by Seb on 10-12-06.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface Highway :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSSet* ramps;

@end


@interface Highway (CoreDataGeneratedAccessors)
- (void)addRampsObject:(NSManagedObject *)value;
- (void)removeRampsObject:(NSManagedObject *)value;
- (void)addRamps:(NSSet *)value;
- (void)removeRamps:(NSSet *)value;

@end

