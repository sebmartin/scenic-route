//
//  RouterDelegate.h
//  ScenicRoute
//
//  Created by Seb on 10-12-22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HighwayDetourRouter;

@protocol RouterDelegate

- (void)routerDidFinish:(HighwayDetourRouter*)router;

@end
