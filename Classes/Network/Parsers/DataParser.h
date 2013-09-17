//
//  DataParser.h
//  ScenicRoute
//
//  Created by Etienne Martin on 10-10-21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataParserDelegate.h"

// Class:       DataParser
// Description: This class is used as a parent class for Data Parsers.
@interface DataParser : NSObject {
	id<DataParserDelegate>  delegate;     // Delegate used to call back into Controller
	NSURL                  *sourceUrl;	  // URL for data source
	NSError                *error;		  // Will hold error
	NSMutableData		   *responseData; // Incoming data
	id						context;	  // Set to an arbitrary object that you want to have a reference to during the parsing
}

@property (nonatomic, retain) NSURL *sourceUrl;
@property (nonatomic, retain) NSError *error;
@property (nonatomic, retain) id<DataParserDelegate> delegate;
@property (nonatomic, retain) NSMutableData *responseData;
@property (nonatomic, retain) id context;

// Custom Constructor
- (id) initWithURL: (NSURL*) url delegate: (id<DataParserDelegate>) del;

// Created the URL, and sends out the request
- (void) fetchData: (NSString*) keyword;
// Parse the data that was read
- (void) parseData;
// Sends the request to the formulated URL
- (void) sendRequest;
// Called when the data is received and ready to be parsed
- (void) parseData;

// Returns the Device IP Address
- (NSString*) getClientUID;
	
@end
