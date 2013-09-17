//
//  CanPagesDataParser.h
//  ScenicRoute
//
//  Created by Etienne Martin on 10-10-21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataParser.h"

// Class:	    CanPagesDataParser
// Description: This class will be used to pull Map data from the CanPages.ca
//              Source. It will parse the incoming data and convert it into 
//              Local Map data that we can store
@interface CanPagesDataParser : DataParser {
	
}

// Constructors
- (id) initWithDelegate: (id<DataParserDelegate>) del;
- (id) initWithKey: (NSString*)apiKey delegate: (id<DataParserDelegate>)del;

// Fetch Data based on Longitude and Latitude with default radius
- (void) fetchDataWithKeyword: (NSString*) keyword 
					longitude: (NSNumber*) longitude 
					 latitude: (NSNumber*) latitude;

// Fetch Data based on Longitude and Latitude with a defined Radius
- (void) fetchDataWithKeyword: (NSString*) keyword 
					longitude: (NSNumber*) longitude 
					 latitude: (NSNumber*) latitude 
					   radius: (NSNumber*) radius;

@end
