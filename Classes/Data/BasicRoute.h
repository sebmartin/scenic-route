//
//  BasicRoute.h
//  ScenicRoute
//
//  Created by Seb on 10-12-22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface BasicRoute : NSObject {
	MKPolyline *polyline;
	NSInteger	duration;
	NSInteger	distance;
}

@property (nonatomic, retain) MKPolyline	*polyline;
@property (nonatomic, assign) NSInteger		 duration;
@property (nonatomic, assign) NSInteger		 distance;

@end
