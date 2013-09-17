//
//  AnnotationViewController.h
//  ScenicRoute
//
//  Created by Etienne Martin on 10-12-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "POIAnnotation.h"

@interface AnnotationViewController : UITableViewController {
	POIAnnotation *annotation;
}

@property (nonatomic, retain) POIAnnotation *annotation;

- (id) initWithAnnotation:(POIAnnotation*) annot;
- (void) onClickYellowPagesBadge:(UIButton*)sender;

@end
