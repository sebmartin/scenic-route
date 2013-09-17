//
//  GoogleDirectionsDataParser.h
//  ScenicRoute
//
//  Created by Seb on 10-11-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "DataParser.h"

@class GoogleRoute;

@interface GoogleDirectionsDataParser : DataParser<NSXMLParserDelegate> {
	NSMutableArray *currentlyParsing;
	NSMutableArray *elementStack;
	GoogleRoute *route;
	NSString *currentString;
}

@property (nonatomic, retain) GoogleRoute *route;

- (void) fetchDataForOrigin:(NSString*)origin destination:(NSString*)destination;
- (void) fetchDataForOrigin:(NSString*)origin destination:(NSString*)destination avoidHighways:(BOOL)avoidHighways;
- (void) fetchDataFromResource:(NSString*)resource ofType:(NSString*)type;

// Utility methods
- (BOOL) elementStackEndsWithElements:(NSString*)lastElementOrNil, ... NS_REQUIRES_NIL_TERMINATION;
+ (NSMutableArray *)decodePolyLine: (NSString *)encoded;
+ (MKPolyline*) polylineFromEncodedString:(NSString*)encoded;


@end
