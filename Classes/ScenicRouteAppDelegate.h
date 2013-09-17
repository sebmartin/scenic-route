//
//  ScenicRouteAppDelegate.h
//  ScenicRoute
//
//  Created by Seb on 10-10-18.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>
#import "AppData.h"

@interface ScenicRouteAppDelegate : NSObject <UIApplicationDelegate> {
	IBOutlet UINavigationController *navController;
    UIWindow *window;
	
@private
    AppData *database;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, readonly) AppData *database;

- (NSString *)applicationDocumentsDirectory;

@end

