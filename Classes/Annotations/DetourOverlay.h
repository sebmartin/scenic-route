//
//  DetourOverlay.h
//  ScenicRoute
//
//  Created by Seb on 10-11-01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@class GoogleRoute;

@interface DetourOverlay : MKPolyline<MKOverlay> {

}

@property (nonatomic, readonly) CLLocationCoordinate2D firstCoordinate;
@property (nonatomic, readonly) CLLocationCoordinate2D lastCoordinate;

+ (DetourOverlay*)detourOverlayWithPoints:(MKMapPoint *)points count:(NSUInteger)count;

@end
