//
//  POIAnnotation.h
//  ScenicRoute
//
//  Created by Etienne Martin on 10-11-07.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BaseAnnotation.h"
#import "POIAnnotation.h"

@interface POIAnnotation : BaseAnnotation {

	UIButton *AccessoryButton;
	
	NSString *Name;
	NSString *Email;
	NSString *Address;
	NSString *City;
	NSString *Province;
	NSString *PostalCode;
	
	NSURL *URL;
	NSURL *Photo;
	NSURL *Video;
}

@property (nonatomic, retain) NSString * Name;
@property (nonatomic, retain) NSString * Email;
@property (nonatomic, retain) NSString * Address;
@property (nonatomic, retain) NSString * City;
@property (nonatomic, retain) NSString * Province;
@property (nonatomic, retain) NSString * PostalCode;

@property (nonatomic, retain) NSURL * URL;
@property (nonatomic, retain) NSURL * Photo;
@property (nonatomic, retain) NSURL * Video;

@property (nonatomic, retain) UIButton * AccessoryButton;

-(id) initWithButton: (UIButton *)button;

@end
