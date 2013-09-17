//
//  YellowPagesDataParser.m
//  ScenicRoute
//
//  Created by Etienne Martin on 10-10-29.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <MapKit/MapKit.h>
#import "YellowPagesDataParser.h"

@implementation YellowPagesDataParser

@synthesize currentString;
@synthesize allPOIs;

#pragma mark -
#pragma mark construtors

// Default Constructor (Uses default key)
- (id) init {
	return [self initWithDelegate: nil];
}

// Constructor with Delegate (uses default key)
- (id) initWithDelegate: (id<DataParserDelegate>) del {
	return [self initWithProdKey:@"<prod-key-here>" devKey:@"<dev-key-here>" delegate:del];
}

// Sandbox API: http://api.sandbox.yellowapi.com/FindBusiness/?what=[KEYWORD]&where=[LOCATION]&UID=[UID]&apikey=
// API          http://api.yellowapi.com/FindBusiness/?what=[KEYWORD]&where=[LOCATION]&UID=[UID]&apikey=
- (id) initWithProdKey: (NSString*) prodApiKey devKey:(NSString*)devApiKey delegate: (id<DataParserDelegate>) del {
	
	static const NSString *location = @"Ottawa";
	NSString *uid = [self getClientUID];

	// Create URL but leave the search word blank
	NSURL *parserUrl = nil;
	#ifdef DEBUG
	// Debugging, use the dev key
	parserUrl = [NSURL URLWithString: [NSString stringWithFormat: @"http://api.sandbox.yellowapi.com/FindBusiness/?fmt=XML&where=%@&UID=%@&apikey=%@&what=", 
											  location, 
											  uid,
											  devApiKey]];
	#else
	// -- use production key
	parserUrl = [NSURL URLWithString: [NSString stringWithFormat: @"http://api.yellowapi.com/FindBusiness/?fmt=XML&where=%@&UID=%@&apikey=%@&what=", 
											  location, 
											  uid,
											  prodApiKey]];
	#endif
		
	self.currentString = @"";
	
	self.allPOIs = [NSMutableArray array];
	
	annotationButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	[annotationButton retain];
	if(del != nil)
		[annotationButton addTarget:del 
							 action:@selector(ShowAnnotationView)
				   forControlEvents:UIControlEventTouchUpInside];

	
	// Init using parent class
	return [super initWithURL:parserUrl delegate: del];
}

#pragma mark -
#pragma mark Parser Actions

// Fetch Data from the source
- (void) fetchData: (NSString*) keyword {
	if(keyword == nil) return;
	
	NSString *urlString = [self.sourceUrl absoluteString];
	
	// Append search and encode
	urlString = [urlString stringByAppendingFormat:@"%@", keyword];
	urlString = [urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	
	self.sourceUrl = [NSURL URLWithString: urlString];
	
#ifdef DEBUG
	NSLog(@"YellowPages> URL Requested: %@", [self.sourceUrl absoluteString]);
#endif
	
	[super sendRequest];
}

// Parse incoming XML data from the Yellow Pages API
- (void) parseData {
	// Create Parser
	NSXMLParser *ypParser = [[NSXMLParser alloc] initWithData:responseData];
	ypParser.delegate = self;
	[ypParser parse];
	
	// parser gets cleaned up when parsing is done, in parserDidEndDocument:
}

#pragma mark -
#pragma mark NSXMLParserDelegate Implementation

// XML Parsing elements
static NSString *kName_Listing  = @"Listing";
static NSString *kName_Name     = @"Name";
static NSString *kName_Street   = @"Street";
static NSString *kName_City     = @"City";
static NSString *kName_Prov     = @"Prov";
static NSString *kName_pCode    = @"Pcode";
static NSString *kName_lat      = @"Latitude";
static NSString *kName_long     = @"Longitude";
static NSString *kName_Dist     = @"Distance";
static NSString *kName_Video    = @"Video";
static NSString *kName_Photo    = @"Photo";
static NSString *kName_Url      = @"Url";

// Started parsing element
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *) elementName 
										namespaceURI:(NSString *) namespaceURI 
									   qualifiedName:(NSString *) qualifiedName 
										  attributes:(NSDictionary *)attributeDict {
	
	if([elementName isEqualToString: kName_Listing]) {
		currentPOI = [[POIAnnotation alloc] initWithButton:annotationButton];
	} 

}
	
// Parsing of element finished
- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
									  namespaceURI:(NSString *)namespaceURI 
									 qualifiedName:(NSString *)qName {

	// Clean String
	self.currentString = [self.currentString stringByReplacingOccurrencesOfString: @"\n" withString: @""];
	
	if([elementName isEqualToString: kName_Listing]) {
		
		// Assign Object to the list
		//[self.delegate.mapView addAnnotation: currentPOI];
		[self.allPOIs addObject:currentPOI];
		[currentPOI release];
		currentPOI = nil;
		
	} else if([elementName isEqualToString: kName_Name]) {
		NSLog(@"YP> Parsing Listing: %@", self.currentString);
		currentPOI.title = [NSString stringWithString: self.currentString];
		currentPOI.Name = [NSString stringWithString: self.currentString];
	} else if([elementName isEqualToString: kName_Street]){
		currentPOI.Address = [NSString stringWithString: self.currentString];
	} else if([elementName isEqualToString: kName_City]) {
		currentPOI.City = [NSString stringWithString: self.currentString];
	} else if([elementName isEqualToString: kName_Prov]) {
		currentPOI.Province = [NSString stringWithString: self.currentString];
	} else if([elementName isEqualToString: kName_pCode]) {
		currentPOI.PostalCode = [NSString stringWithString: self.currentString];
	} else if([elementName isEqualToString: kName_lat]) {		
		CLLocationCoordinate2D coord = currentPOI.coordinate;
		coord.latitude = [self.currentString doubleValue];
		currentPOI.coordinate = coord;
	} else if([elementName isEqualToString: kName_long]) {	
		CLLocationCoordinate2D coord = currentPOI.coordinate;
		coord.longitude = [self.currentString doubleValue];
		currentPOI.coordinate = coord;
	} else if([elementName isEqualToString: kName_Dist]) {	
		//currentPOI.Location.Distance = [NSNumber numberWithDouble:[self.currentString doubleValue]];
	} else if([elementName isEqualToString: kName_Video]) {	
		NSLog(@"YP> Video: %@", self.currentString);
		currentPOI.Video = [NSURL URLWithString: self.currentString];
	} else if([elementName isEqualToString: kName_Photo]) {	
		NSLog(@"YP> Photo: %@", self.currentString);
		currentPOI.Photo = [NSURL URLWithString: self.currentString];
	} else if([elementName isEqualToString: kName_Url]) {	
		NSLog(@"YP> URL: %@", self.currentString);
		currentPOI.URL = [NSURL URLWithString: self.currentString];
	}	
	
	self.currentString = @"";

}

// Found more string data to append to current element
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	self.currentString = [self.currentString stringByAppendingString: string];
}

// Error parsing data
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	// TODO: Need to handle error better
	NSLog(@"YellowPagesDataParser> Error while parsing. Code:%d", [parseError code]);
}

// All done
-(void)parserDidEndDocument:(NSXMLParser *)parser {
	// Call back into the delegate
	[[self delegate] parsingFinished:self];
	
	[parser release];
}
	
#pragma mark -
#pragma mark Memory Handlers

// Destructor
- (void) dealloc {
	[currentString release];
	[currentPOI release];
	[annotationButton release];
	[allPOIs release];
	
    [super dealloc];
}

@end
