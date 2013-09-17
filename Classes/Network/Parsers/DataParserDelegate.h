//
//  DataParserDelegate.h
//  ScenicRoute
//
//  Created by Etienne Martin on 10-10-29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <MapKit/MapKit.h>

// This protocol, will be used to set UIViews as a delegate for Data Parsing
// Classes
@protocol DataParserDelegate

// Called when the search is finished, and returns a data set
- (void) searchFinished;

// Called after parsing of the data is finished
- (void) parsingFinished: (id) parser;

// An error occured
- (void) parser:(id)parser didFailWithError:(NSError*)error;

// Make sure the delegate has access to a MKMapView instance
// TODO: Remove the need for this.  The parser should not need access to a mapview.  The calling class should
//   do the things like adding annotations.
@property (nonatomic, retain) MKMapView *mapView;

@end
