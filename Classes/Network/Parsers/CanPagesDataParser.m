//
//  CanPagesDataParser.m
//  ScenicRoute
//
//  Created by Etienne Martin on 10-10-21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CanPagesDataParser.h"

@implementation CanPagesDataParser

#pragma mark -
#pragma mark construtors

// Default Constructor (Uses default key)
- (id) init {
	return [self initWithDelegate: nil];
}

- (id) initWithDelegate: (id<DataParserDelegate>) del {
	return [self initWithKey: @"127628B4F3AD0A44FCE3768600DCB8566EBDD6B0"
					delegate: nil];	
}

// Key based initialization
// sandbox URL   : http://sandapi.canpages.ca/LocalSearch/v1?loc=[LOCATION]&apiKey=[API KEY]&key=[SEARCH WORD]
// production URL: http://api.canpages.ca/LocalSearch/v1?loc=[LOCATION]&apiKey=[API KEY]&key=[SEARCH WORD]
- (id) initWithKey: (NSString *) apiKey delegate: (id<DataParserDelegate>) del {
		
	static const NSString *location   = @"Ottawa";

	// Create URL but leave the search word blank
	NSURL *parserUrl = [NSURL URLWithString: [NSString stringWithFormat: @"http://sandapi.canpages.ca/LocalSearch/v1?loc=%@&api_key=%@&key=", 
												location, apiKey]];
						  
	// Init using parent class
	return [super initWithURL:parserUrl delegate: del];
}

#pragma mark -
#pragma mark Parser Actions

// Create URL for request, and send it out
- (void) fetchData: (NSString*) keyword {
	[self fetchDataWithKeyword:keyword longitude:nil latitude:nil radius: nil];
}

// Fetch Data based on Longitude and Latitude with default radius
// NOTE: Default radius according to the API is 10km
- (void) fetchDataWithKeyword: (NSString*) keyword 
					longitude: (NSNumber*) longitude 
					 latitude: (NSNumber*) latitude {
	[self fetchDataWithKeyword:keyword longitude:longitude latitude:latitude radius: nil];
}

// Fetch Data based on Longitude and Latitude with a defined Radius
- (void) fetchDataWithKeyword: (NSString*) keyword 
					longitude: (NSNumber*) longitude 
					 latitude: (NSNumber*) latitude 
					   radius: (NSNumber*) radius {
	if(keyword == nil) return;
	
	NSString *urlString = [self.sourceUrl absoluteString];
	
	urlString = [urlString stringByAppendingFormat:@"%@", keyword];
	if(longitude != nil) urlString = [urlString stringByAppendingFormat:@"&lng=%f", longitude];
	if(latitude  != nil) urlString = [urlString stringByAppendingFormat:@"&lat=%f", latitude];
	if(longitude != nil) urlString = [urlString stringByAppendingFormat:@"&radius=%f", radius];
		
	self.sourceUrl = [NSURL URLWithString: urlString];
	
	NSLog(@"CanPagesParser> URL Requested: %@", [self.sourceUrl absoluteString]);
	
	[super sendRequest];	
}

// This is meant to be overridden by the children classes. It will
// handle the incoming data and parse into usable map data
- (void) parseData {
	
	NSString *responseString = [[NSString alloc] initWithData:[self responseData] encoding:NSUTF8StringEncoding];
	NSLog(@"CanPagesParser> Return data :\n %@ \n", responseString);
	
	// TODO: Implement data parsing once sandbox works
	
}

#pragma mark -
#pragma mark Memory Handlers

// Destructor
- (void) dealloc {
    [super dealloc];
}

@end
