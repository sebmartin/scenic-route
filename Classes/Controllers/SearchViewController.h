//
//  SearchViewController.h
//  ScenicRoute
//
//  Created by Seb on 10-10-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import	"MapViewBaseViewController.h"
#import "DataParserDelegate.h"
#import "MapStateViewController.h"

@interface SearchViewController : MapViewBaseViewController <UISearchBarDelegate, DataParserDelegate> {
	IBOutlet MapStateViewController *mapStateController;
	NSMutableDictionary *parserList;
	POIAnnotation *currentAnnotation;
	NSMutableArray *annotations;
}

@property (nonatomic, retain) NSMutableDictionary *parserList;
@property (nonatomic, retain) MapStateViewController *mapStateController;
@property (nonatomic, retain) POIAnnotation * currentAnnotation;
@property (nonatomic, retain) NSMutableArray *annotations;

// Pops an Annotation View onto the Navigation Controller
- (void) ShowAnnotationView;

@end
