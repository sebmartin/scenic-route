//
//  GoogleRouteLeg.h
//  ScenicRoute
//
//  Created by Seb on 10-11-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>


@interface GoogleRouteLeg : NSObject {
	NSString				*startAddress;
	NSString				*endAddress;
	NSInteger				 duration;		// seconds
	NSInteger				 distance;		// meters
	CLLocationCoordinate2D	 startLocation;
	CLLocationCoordinate2D	 endLocation;
	NSArray					*steps;
}

@property (nonatomic, retain) NSString					*startAddress;
@property (nonatomic, retain) NSString					*endAddress;
@property (nonatomic, assign) NSInteger					 duration;		// seconds
@property (nonatomic, assign) NSInteger					 distance;		// meters
@property (nonatomic, assign) CLLocationCoordinate2D	 startLocation;
@property (nonatomic, assign) CLLocationCoordinate2D	 endLocation;
@property (nonatomic, retain) NSArray					*steps;

@end
