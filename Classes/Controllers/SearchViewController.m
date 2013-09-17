    //
//  SearchViewController.m
//  ScenicRoute
//
//  Created by Seb on 10-10-18.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "SearchViewController.h"
#import "CanPagesDataParser.h"
#import "YellowPagesDataParser.h"
#import	"POIAnnotation.h"
#import "AnnotationViewController.h"
#import "GenericParserErrorAlert.h"

@implementation SearchViewController

@synthesize parserList;
@synthesize mapStateController;
@synthesize currentAnnotation;
@synthesize annotations;

// Here for the protocol, but this is declared in the parent class
@dynamic mapView;

// Called when an annotation Details button view is touched
- (void) ShowAnnotationView{
	NSLog(@"Showing Annotation View");
	[self.mapStateController createPOIAnnotationView:self.currentAnnotation];
}


#pragma mark -
#pragma mark View life cycle


- (void)viewDidUnload {
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

-(void) viewDidActivate {
	if (self.annotations) {
		[self.mapView addAnnotations:self.annotations];
	}
}

#pragma mark - 
#pragma mark UISearchBarDelegate Implementation

- (BOOL) searchBarShouldBeginEditing:(UISearchBar *)searchBar {
	[searchBar setShowsCancelButton:YES animated:YES];
	return YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
	// Hide the cancel button
	[searchBar setShowsCancelButton:NO animated:YES];
	
	// End keyboard input and hide it
	[searchBar resignFirstResponder];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {

	NSString *searchText = searchBar.text;
	NSLog(@"SearchView> Search string: %@", searchText);
	
	// Show the wait view
	[[NSNotificationCenter defaultCenter] postNotification:
	 [NSNotification notificationWithName:@"ShowWaitView" object:self userInfo:
	  [NSDictionary dictionaryWithObjectsAndKeys:@"1", @"show", nil]]];
	
	if(parserList == nil) {
		self.parserList = [[NSMutableDictionary alloc] init];
	}
	
	// Clear annotations
	[annotations removeAllObjects];
	[mapStateController clearAnnotations];

	YellowPagesDataParser *yPages = [[YellowPagesDataParser alloc] initWithDelegate:self];	
	[self.parserList setObject:yPages forKey: [yPages class]];
	[yPages fetchData: searchText];
	[yPages release];
		
	[searchBar resignFirstResponder];
	
}

- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
	NSLog(@">>>>>>> Did end editing");
}

#pragma mark -
#pragma mark DataParserDelegate Implementation

// Called when data parser has received data back from the source
- (void) searchFinished {
	NSLog(@"SearchView> parser search returned");
}

// Called when data parser has finished parsing the incoming data
- (void) parsingFinished: (id) parser {
	
	if ([parser isKindOfClass:[YellowPagesDataParser class]]) {
		
		self.annotations = ((YellowPagesDataParser*)parser).allPOIs;
		[self.mapView addAnnotations:self.annotations];
		
		// Remove parser from the list
		if(self.parserList != nil && parser != nil) {
			[self.parserList removeObjectForKey:[parser class]];
			NSLog(@" Parser List Count: %d", [parserList count]);
		}
		
		// Hide the wait view
		[[NSNotificationCenter defaultCenter] postNotification:
		 [NSNotification notificationWithName:@"ShowWaitView" object:self userInfo:
		  [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"show", nil]]];
		
		NSLog(@"SearchView> parser finished parsing");	
	}
}

-(void) parser:(id)parser didFailWithError:(NSError *)error {
	// Hide the wait view
	[[NSNotificationCenter defaultCenter] postNotification:
	 [NSNotification notificationWithName:@"ShowWaitView" object:self userInfo:
	  [NSDictionary dictionaryWithObjectsAndKeys:@"0", @"show", nil]]];
	
	[GenericParserErrorAlert showAlertForError:error];
}

#pragma mark -
#pragma mark MKMapViewDelegate implementation

- (MKOverlayView *) mapView:(MKMapView *)mapView viewForOverlay:(id <MKOverlay>)overlay {
	
	if ([overlay respondsToSelector:@selector(view)]) {
		return [overlay performSelector:@selector(view)];
	}
	return nil;
}

- (MKAnnotationView *) mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation {
	
	if ([annotation respondsToSelector:@selector(viewForMapView:)]) {
		return [annotation performSelector:@selector(viewForMapView:) withObject:theMapView];
	}
	return nil;
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view {
	// Store current selected Annotation
	self.currentAnnotation = view.annotation;
}

#pragma mark -
#pragma mark Memory Management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

- (void)dealloc {
	[parserList release];
	[annotations release];
	
    [super dealloc];
}


@end
