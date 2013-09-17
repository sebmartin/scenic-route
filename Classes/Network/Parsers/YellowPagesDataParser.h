//
//  YellowPagesDataParser.h
//  ScenicRoute
//
//  Created by Etienne Martin on 10-10-29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataParser.h"
#import "POIAnnotation.h"

// Class:       YellowPagesDataParser
// Description: This class will fetch data from the Yellow pages API.
// API:         http://www.yellowapi.com/docs
@interface YellowPagesDataParser : DataParser <NSXMLParserDelegate> {
	
	// Variables used a temporary storage while reading XML
	NSString       *currentString;
	POIAnnotation  *currentPOI;
	UIButton	   *annotationButton;
	
	NSMutableArray *allPOIs;
}

@property (nonatomic, retain) NSString *currentString;
@property (nonatomic, retain) NSMutableArray *allPOIs;

// Constructors
- (id) initWithDelegate: (id<DataParserDelegate>) del;
- (id) initWithProdKey: (NSString*) prodApiKey devKey:(NSString*)devApiKey delegate: (id<DataParserDelegate>) del;

// Fetch Data based on What and Where API
- (void) fetchData: (NSString*) keyword;

@end
