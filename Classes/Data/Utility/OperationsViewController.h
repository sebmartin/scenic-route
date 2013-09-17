//
//  OperationsViewController.h
//  ScenicRoute
//
//  Created by Seb on 10-12-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DataViewController;

@interface OperationsViewController : UIViewController {
	UIActivityIndicatorView *activityIndicator;
	UILabel *statusLabel;
	UITabBar *tabBar;
	
	NSMutableArray *pendingOperations;
}

@property(nonatomic, assign) IBOutlet UIActivityIndicatorView *activityIndicator;
@property(nonatomic, assign) IBOutlet UILabel *statusLabel;
@property(nonatomic, assign) IBOutlet UITabBar *tabBar;

- (void)loadMetaData;
- (void)didFinishLoadingMetaData:(NSNotification*)notification;

@end
