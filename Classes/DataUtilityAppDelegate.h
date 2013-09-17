//
//  ScenicRouteAppDelegate.h
//  ScenicRoute
//
//  Created by Seb on 10-10-18.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@class AppData;

@interface DataUtilityAppDelegate : NSObject <UIApplicationDelegate> {
   UIWindow *window;
   AppData *database;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) AppData *database;

- (NSString *)applicationDocumentsDirectory;

@end

