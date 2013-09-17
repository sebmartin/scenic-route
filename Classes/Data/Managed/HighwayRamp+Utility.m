//
//  HighwayRamp+Utility.m
//  ScenicRoute
//
//  Created by Seb on 10-12-12.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "HighwayRamp+Utility.h"


@implementation HighwayRamp (Utility)

- (BOOL)isForSameExitAsRamp:(HighwayRamp*)ramp {
	return (
			[self.number caseInsensitiveCompare:ramp.number] == NSOrderedSame &&
			[self.direction caseInsensitiveCompare:ramp.direction] == NSOrderedSame
			);
}

@end
