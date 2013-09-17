//
//  GoogleRoute.h
//  ScenicRoute
//
//  Created by Seb on 10-11-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class DetourOverlay;

@interface GoogleRoute : NSObject {
	NSString		*summary;
	NSArray			*legs;
	NSString		*copyright;
	MKPolyline		*overviewPolyline;
	NSString		*overviewPolylineEncoded;
}

@property (nonatomic, retain) NSString			*summary;
@property (nonatomic, retain) NSArray			*legs;
@property (nonatomic, retain) NSString			*copyright;
@property (nonatomic, readonly) NSInteger		 duration;
@property (nonatomic, readonly) NSInteger		 distance;
@property (nonatomic, retain) MKPolyline		*overviewPolyline;
@property (nonatomic, retain) NSString			*overviewPolylineEncoded;

@end
