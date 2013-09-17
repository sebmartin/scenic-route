    //
//  OperationsViewController.m
//  ScenicRoute
//
//  Created by Seb on 10-12-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "OperationsViewController.h"
#import "DataUtilityAppDelegate.h"
#import "HighwayRampLoader.h"
#import "HighwayDetourLoader.h"
#import "AppData.h"


@implementation OperationsViewController

@synthesize activityIndicator, statusLabel, tabBar;

- (void)viewDidLoad {
    [super viewDidLoad];
	
	pendingOperations = [NSMutableArray new];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(didFinishLoadingMetaData:)
												 name:@"didFinishLoadingMetaDataStep" 
											   object:nil];	
	
	[self performSelectorInBackground:@selector(loadMetaData) withObject:nil];
}

- (void)loadMetaData {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	
	// Start loading the database
	DataUtilityAppDelegate *delegate = (DataUtilityAppDelegate*)[[UIApplication sharedApplication] delegate];
	NSManagedObjectContext *context = delegate.database.context;
	[context reset];
	NSURL *url = [NSURL URLWithString:[delegate applicationDocumentsDirectory]];

	// Make sure the context will retain new objects
	[context setRetainsRegisteredObjects:YES];
	[HighwayRampLoader loadFromURL:url intoContext:context];
	[pendingOperations addObject:[HighwayRampLoader class]];
	
	HighwayDetourLoader *detourLoader = [[HighwayDetourLoader alloc] init];
	[pendingOperations addObject:detourLoader];
	[detourLoader loadFromURL:url intoContext:context];
	[detourLoader release];
	
	[self didFinishLoadingMetaData:nil];
	
	[pool drain];
}

- (void)didFinishLoadingMetaData:(NSNotification*)notification {
	
	if ([pendingOperations count] > 0) {
		[pendingOperations removeLastObject];
	}
	if ([pendingOperations count] > 0) {
		return;
	}
	
	NSError *error = nil;
	DataUtilityAppDelegate *delegate = (DataUtilityAppDelegate*)[[UIApplication sharedApplication] delegate];
	[delegate.database.context save:&error];
	
	if (error) {
		self.statusLabel.text = @"ERROR! See log for details.";
		NSLog(@"%@", error);
	}
	else {
		self.statusLabel.text = @"Complete";
	}

	[self.activityIndicator stopAnimating];
	
	for (UITabBarItem *item in self.tabBar.items) {
		item.enabled = YES;
	}
	
	// All done, publish the event
	[[NSNotificationCenter defaultCenter] 
	 postNotification:[NSNotification notificationWithName:@"didFinishLoadingMetaData" object:nil]];
}

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}


- (void)dealloc {
	[pendingOperations release];
    [super dealloc];
}


@end
