//
//  POIAnnotation.m
//  ScenicRoute
//
//  Created by Etienne Martin on 10-11-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "POIAnnotation.h"


@implementation POIAnnotation

@synthesize Name, Email, Address, City, Province, PostalCode;
@synthesize URL, Photo, Video;
@synthesize AccessoryButton;

#pragma mark -
#pragma mark Initialization

-(id) init {
	return [self initWithButton:nil];	
}

-(id) initWithButton: (UIButton *)button {
	if (self = [super init]) {
        self.Name  = @"";
		self.Email  = @"";
		self.Address  = @"";
		self.City  = @"";
		self.Province  = @"";
		self.PostalCode  = @"";
		
		self.AccessoryButton = button;
		
		/* Statis sub title for annotations */
		self.subtitle = @"Tap me for more details...";
		
		// URL are to be left as nil
    }
    return self;
}

#pragma mark -
#pragma mark Override these
-(MKAnnotationView*)allocAnnotationView {
	MKAnnotationView *view = [super allocAnnotationView];
	
	view.canShowCallout = YES;
	 
	// Add Button to the Annotation Callout
	//UIButton *calloutBtn = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
	//view.rightCalloutAccessoryView = calloutBtn;
	
	// Assign button used to enable annotation view
	view.rightCalloutAccessoryView = self.AccessoryButton;

	// Assign left callout icon
	UIImage *image = [UIImage imageNamed:@"yp_icon.png"];
	UIImageView *imgView = [[UIImageView alloc] initWithImage:image];
	view.leftCalloutAccessoryView = imgView;
	[imgView release];
	
	return view;
}

-(NSString*)viewIdentifier {
	return @"POIAnnotation";
}

#pragma mark -
#pragma mark Memory management

- (void) dealloc {
	[Name release];
	[Email release];
	[Address release];
	[City release];
	[Province release];
	[PostalCode release];
	[URL release];
	[Video release];
	[Photo release];
	
	[super dealloc];
}	

@end
