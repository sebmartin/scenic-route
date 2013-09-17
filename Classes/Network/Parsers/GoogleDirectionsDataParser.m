//
//  GoogleDirectionsDataParser.m
//  ScenicRoute
//
//  Created by Seb on 10-11-09.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DataParser.h"
#import "GoogleDirectionsDataParser.h"
#import "GoogleRoute.h"
#import "GoogleRouteLeg.h"
#import "GoogleRouteStep.h"


@interface GoogleDirectionsDataParser (private)
-(void) parser:(NSXMLParser *)parser processElement:(NSString*)elementName;
-(void)parseElement:(NSString*)elementName ForGoogleRouteStepOrRouteLeg:(id)object;
@end


@implementation GoogleDirectionsDataParser

@synthesize route;

- (void) fetchDataForOrigin:(NSString*)origin destination:(NSString*)destination {
	[self fetchDataForOrigin:origin destination:destination avoidHighways:NO];
}

- (void) fetchDataForOrigin:(NSString*)origin destination:(NSString*)destination avoidHighways:(BOOL)avoidHighways {
	NSString *urlString = [NSString stringWithFormat:@"http://maps.googleapis.com/maps/api/directions/xml?region=ca&origin=%@&destination=%@&mode=driving&sensor=true",
						   [origin stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding], 
						   [destination stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]];
	if (avoidHighways) {
		urlString = [urlString stringByAppendingString:@"&avoid=highways"];
	}	
	self.sourceUrl = [NSURL URLWithString:urlString];
	
	NSLog(@"GoogleDirections> URL Requested: %@", [self.sourceUrl absoluteString]);
	NSLog(@"                  Google Maps: from:%@ to:%@", origin, destination);
	
	[super sendRequest];
}

// Useful for testing without bombing the google service
// -- The resource must contain the XML response from a google api call
- (void) fetchDataFromResource:(NSString*)resource ofType:(NSString*)type {
	
	 // Load XML from a file
	 NSString *path = [[NSBundle mainBundle] pathForResource:resource ofType:type];
	 [self setResponseData:[NSData dataWithContentsOfFile:path]];
	 [self parseData];	
	
}

-(void) parseData {	
	NSLog(@"GoogleDirections> Return data : %i bytes", [[self responseData] length]);
	
	// Parse the returned XML
	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:[self responseData]];
	parser.delegate = self;
	[parser parse];
	
	// parser gets cleaned up when parsing is done, in parserDidEndDocument:
}

#pragma mark -
#pragma mark NSXMLParserDelegate implementation

-(void) parserDidStartDocument:(NSXMLParser *)parser {
	// Initialize the parser state variables when a new parsing operation begins
	[currentlyParsing release];	
	currentlyParsing = nil;
	
	[route release];
	route = nil;
	
	[currentString release];
	currentString = @"";
	
	[elementStack release];
	elementStack = [NSMutableArray array];
}

-(void) parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {

	if (currentlyParsing == nil) {
		currentlyParsing = [[NSMutableArray alloc] init];
	}

	// Push the current element to the stack
	[elementStack addObject:elementName];
	
	// Are we parsing a nested object?  If the new element is a complex type, we:
	// - create an instance of the object that will contain the data
	// - assign it to it's parent data object
	// - push the new object to the stack of parsing objects
	if ([[elementName lowercaseString] isEqualToString:@"route"]) {
		if (route != nil) {
			NSLog(@"*** WARNING: More than one <route> element found in Google Directions response data.");
			return;
		}
		
		// Assign the new object as the top-most parent route ivar
		// and push the new object to the parsing stack
		self.route = [[GoogleRoute alloc] init];  // Released from -dealloc
		[currentlyParsing addObject:route];
		return;
	}
	else if ([[elementName lowercaseString] isEqualToString:@"leg"]) {
		id currentObject = [currentlyParsing lastObject];
		if (![currentObject isKindOfClass:[GoogleRoute class]]) {
			NSLog(@"*** WARNING: A <leg> element was found which is not a direct child of a <route> element.");
			return;
		}
		
		// Assign the new object to the parent's appropriate ivar 
		GoogleRouteLeg *newLeg = [[[GoogleRouteLeg alloc] init] autorelease];
		GoogleRoute *currRoute = (GoogleRoute*)currentObject;
		if (!currRoute.legs) {
			currRoute.legs = [[[NSMutableArray alloc] init] autorelease];
		}
		[(NSMutableArray*)[currRoute legs] addObject:newLeg];

		// Push the new object to the parsing stack
		[currentlyParsing addObject:newLeg];
		
		return;
	}
	else if ([[elementName lowercaseString] isEqualToString:@"step"]) {
		id currentObject = [currentlyParsing lastObject];
		if (![currentObject isKindOfClass:[GoogleRouteLeg class]]) {
			NSLog(@"*** WARNING: A <step> element was found which is not a direct child of a <leg> element.");
			return;
		}
		
		// Assign the new object to the parent's appropriate ivar 
		GoogleRouteStep *newStep = [[[GoogleRouteStep alloc] init] autorelease];
		GoogleRouteLeg *currLeg = (GoogleRouteLeg*)currentObject;
		if (!currLeg.steps) {
			currLeg.steps = [[[NSMutableArray alloc] init] autorelease];
		}
		[(NSMutableArray*)[currLeg steps] addObject:newStep];

		// Push the new object to the parsing stack
		[currentlyParsing addObject:newStep];
		
		return;		
	}
}

- (void) parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

	// Process the element.  This method has many exit points and the following lines need to be called
	// for each one of them
	[self parser:parser processElement:elementName];
	
	// Pop the element from the stack
	[elementStack removeLastObject];
	
	// Reset the text string
	currentString = @"";
	
}

-(void) parser:(NSXMLParser *)parser processElement:(NSString*)elementName {

	if ([currentlyParsing lastObject] == nil) {
		// This happens when we parse past the end of the top-most element that we are interested in.
		// For example, we stop caring after </route>
		return;
	}
	
	// Did we finish parsing a complex data type?  If so, pop it from the parsing stack
	if ([[elementName lowercaseString] isEqualToString:@"route"]) {
		if (![[currentlyParsing lastObject] isKindOfClass:[GoogleRoute class]]) {
			NSLog(@"*** WARNING: the parsing stack is out of sync with the didEndElement calls");
			return;
		}
		[currentlyParsing removeLastObject];
	}
	else if ([[elementName lowercaseString] isEqualToString:@"leg"]) {	
		if (![[currentlyParsing lastObject] isKindOfClass:[GoogleRouteLeg class]]) {
			NSLog(@"*** WARNING: the parsing stack is out of sync with the didEndElement calls");
			return;
		}
		[currentlyParsing removeLastObject];
	}
	else if ([[elementName lowercaseString] isEqualToString:@"step"]) {
		if (![[currentlyParsing lastObject] isKindOfClass:[GoogleRouteStep class]]) {
			NSLog(@"*** WARNING: the parsing stack is out of sync with the didEndElement calls");
			return;
		}
		[currentlyParsing removeLastObject];
	}
	else {
		// Assign the property
		// - parse each object in its own method to avoid a massive nest of if-elseif blocks
		id currentObject = [currentlyParsing lastObject];
		NSString *className = NSStringFromClass([currentObject class]);
		NSString *parseSelectorStr = [NSString stringWithFormat:@"parseElement:For%@:", className];
		SEL parseSelector = NSSelectorFromString(parseSelectorStr);
		if ([self respondsToSelector:parseSelector]) {
			[self performSelector:parseSelector withObject:elementName withObject:currentObject];
		}
		else if (className != nil) {
			// Only show a warning if we hit the top-most element that we're interested in
			NSLog(@"*** WARNING: Cannot parse element:%@ for object type:%@", elementName, className);
		}
	}
}

-(void)parseElement:(NSString*)elementName ForGoogleRoute:(GoogleRoute*)newRoute {
	
	// Trim whitespaces around the value
	currentString = [currentString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([self elementStackEndsWithElements: @"summary", @"route", nil]) {
		newRoute.summary = currentString;
	}
	else if ([self elementStackEndsWithElements: @"copyright", @"route", nil]) {
		newRoute.copyright = currentString;
	}
	else if ([self elementStackEndsWithElements: @"points", @"overview_polyline", @"route", nil]) {
		newRoute.overviewPolylineEncoded = currentString;
		newRoute.overviewPolyline = [[self class] polylineFromEncodedString:currentString];
	}
	else if ([self elementStackEndsWithElements: @"levels", @"overview_polyline", @"route", nil]) {
		// TODO: parse the levels (needed?)		
	}
}

-(void)parseElement:(NSString*)elementName ForGoogleRouteLeg:(GoogleRouteLeg*)leg {
	
	// Steps and Legs are almost identical objects, so parse from the same method
	[self parseElement:elementName ForGoogleRouteStepOrRouteLeg:leg];
}

-(void)parseElement:(NSString*)elementName ForGoogleRouteStep:(GoogleRouteStep*)step {
	
	// Steps and Legs are almost identical objects, so parse from the same method
	[self parseElement:elementName ForGoogleRouteStepOrRouteLeg:step];
}

-(void)parseElement:(NSString*)elementName ForGoogleRouteStepOrRouteLeg:(id)object {
	
	// Trim whitespaces around the value
	currentString = [currentString stringByTrimmingCharactersInSet: [NSCharacterSet whitespaceAndNewlineCharacterSet]];
	
	if ([self elementStackEndsWithElements: @"value", @"duration", nil]) {
		[object setDuration: [currentString intValue]];
	}
	else if ([self elementStackEndsWithElements: @"value", @"distance", nil]) {
		[object setDistance: [currentString intValue]];
	}
	else if ([self elementStackEndsWithElements: @"lat", @"start_location", nil]) {
		[object setStartLocation: CLLocationCoordinate2DMake(
															  [currentString doubleValue],
															  [object startLocation].longitude
															  )];
	}
	else if ([self elementStackEndsWithElements: @"lng", @"start_location", nil]) {
		[object setStartLocation: CLLocationCoordinate2DMake(
													   [object startLocation].latitude, 
													   [currentString doubleValue]
															 )];
	}
	else if ([self elementStackEndsWithElements: @"lat", @"end_location", nil]) {
		[object setEndLocation: CLLocationCoordinate2DMake(
													 [currentString doubleValue],
													 [object endLocation].longitude
													 )];
	}
	else if ([self elementStackEndsWithElements: @"lng", @"end_location", nil]) {
		[object setEndLocation: CLLocationCoordinate2DMake(
													 [object endLocation].latitude, 
													 [currentString doubleValue]
													 )];
	}
	else if ([self elementStackEndsWithElements: @"start_address", nil]) {
		[object setStartAddress: currentString];
	}
	else if ([self elementStackEndsWithElements: @"end_address", nil]) {
		[object setEndAddress: currentString];
	}
	
	// These are only defined in steps
	else if ([self elementStackEndsWithElements: @"travel_mode", nil]) {
		[object setTravelMode: currentString];
	}
	else if ([self elementStackEndsWithElements: @"html_instructions", nil]) {
		[object setHtmlInstructions: currentString];
	}
	else if ([self elementStackEndsWithElements: @"points", @"polyline", nil]) {
		[object setPolyline:[[self class] polylineFromEncodedString:currentString]];
	}
}

// Found more string data to append to current element
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
	NSString *oldString = currentString;
	currentString = [[oldString stringByAppendingString: string] retain];
	[oldString release];
}

- (void) parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
	// TODO: handle this
	NSLog(@"A parsing error occured!");
	
	[currentlyParsing release];
	currentlyParsing = nil;
	[parser release];
}

// All done
-(void) parserDidEndDocument:(NSXMLParser *)parser {
	[currentlyParsing release];
	currentlyParsing = nil;
	
	// Call back into the delegate
	[[self delegate] parsingFinished:self];
	
	[parser release];
}

#pragma mark -
#pragma mark Utility methods

- (BOOL) elementStackEndsWithElements:(NSString*)lastElementOrNil, ... {
	
	if (lastElementOrNil == nil) {
		return NO;
	}
	
	// Go through the list of ancestors (if any) and make sure that the 
	// element stack compares to the expected ancestor elements
	va_list	args;
	va_start(args, lastElementOrNil);
	
	NSInteger revStackIndex = 0;
	BOOL same = YES;
	
	for (NSString *expectedElement = lastElementOrNil; 
		 expectedElement != nil; 
		 expectedElement = va_arg(args, NSString*)) 
	{
		if (revStackIndex >= [elementStack count]) {
			same = NO;
			break;
		}
		
		NSString *stackAncestor = [elementStack objectAtIndex:[elementStack count] - revStackIndex - 1];
		revStackIndex++;
		
		if ([stackAncestor caseInsensitiveCompare:expectedElement] != NSOrderedSame) {
			same = NO;
			break;
		}
	}
	
	va_end(args);
	
	return same;
}

/*
 * Converts an encoded string of coordinates returned by the google service and returns each
 * coordinate in an NSMutableArray
 */
+ (NSMutableArray *)decodePolyLine: (NSString *)encoded {
	encoded = [encoded mutableCopy];
	[(NSMutableString*)[encoded mutableCopy] replaceOccurrencesOfString:@"\\\\" withString:@"\\"
																options:NSLiteralSearch
																  range:NSMakeRange(0, [encoded length])];
	NSInteger len = [encoded length];
	NSInteger index = 0;
	NSMutableArray *array = [[NSMutableArray alloc] init];
	NSInteger lat=0;
	NSInteger lng=0;
	while (index < len) {
		NSInteger b;
		NSInteger shift = 0;
		NSInteger result = 0;
		do {
			b = [encoded characterAtIndex:index++] - 63;
			result |= (b & 0x1f) << shift;
			shift += 5;
		} while (b >= 0x20);
		NSInteger dlat = ((result & 1) ? ~(result >> 1) : (result >> 1));
		lat += dlat;
		shift = 0;
		result = 0;
		do {
			b = [encoded characterAtIndex:index++] - 63;
			result |= (b & 0x1f) << shift;
			shift += 5;
		} while (b >= 0x20);
		NSInteger dlng = ((result & 1) ? ~(result >> 1) : (result >> 1));
		lng += dlng;
		NSNumber *latitude = [[NSNumber alloc] initWithFloat:lat * 1e-5];
		NSNumber *longitude = [[NSNumber alloc] initWithFloat:lng * 1e-5];
		CLLocation *loc = [[CLLocation alloc] initWithLatitude:[latitude doubleValue] longitude:[longitude doubleValue]];
		[array addObject:loc];
		

		[loc release];
		[latitude release];
		[longitude release];
	}
	return [array autorelease];
}

/*
 * Converts a encoded string of coordinates that is returned from the google service to an MKPolyline object
 */
+ (MKPolyline*) polylineFromEncodedString:(NSString*)encoded {
	NSArray *coordsObjC = [[self class] decodePolyLine:encoded];
	CLLocationCoordinate2D *coordsC = malloc([coordsObjC count] * sizeof(CLLocationCoordinate2D));
	
	for (int i=0; i < [coordsObjC count]; i++) {
		CLLocation *location = [coordsObjC objectAtIndex:i];
		((CLLocationCoordinate2D)coordsC[i]).longitude = location.coordinate.longitude;
		((CLLocationCoordinate2D)coordsC[i]).latitude = location.coordinate.latitude;
	}
	
	MKPolyline *polyline = [MKPolyline polylineWithCoordinates:coordsC count:[coordsObjC count]];

	free(coordsC);
	
	return polyline;
}

#pragma mark -
#pragma mark Memory management

-(void) dealloc {
	[currentlyParsing release];
	[route release];
	
	[super dealloc];
}

@end
