//
//  BaseAnnotation.h
//  ScenicRoute
//
//  Created by Seb on 10-11-01.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface BaseAnnotation : NSObject<MKAnnotation> {
}

// MKAnnotation protocol
@property (nonatomic, assign)	CLLocationCoordinate2D coordinate;
@property (nonatomic, retain)	NSString *title;
@property (nonatomic, retain)	NSString *subtitle;

-(NSString*)viewIdentifier;
-(MKAnnotationView*)allocAnnotationView;
-(MKAnnotationView*)viewForMapView:(MKMapView*)map;

@end
