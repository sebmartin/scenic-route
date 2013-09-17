//
//  RouteEndAnnotation.h
//  ScenicRoute
//
//  Created by Seb on 10-11-17.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseAnnotation.h"

enum RouteEndAnnotationType {
	RouteEndAnnotationOrigin = 0,
	RouteEndAnnotationDestination
};

@interface RouteEndAnnotation : BaseAnnotation {
	enum RouteEndAnnotationType endType;
}

@property (nonatomic, assign) enum RouteEndAnnotationType endType;

@end
