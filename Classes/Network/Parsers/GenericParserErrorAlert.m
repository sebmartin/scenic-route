//
//  GenericParserErrorAlert.m
//  ScenicRoute
//
//  Created by Seb on 10-12-22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "GenericParserErrorAlert.h"


@implementation GenericParserErrorAlert

+ (void) showAlertForError:(NSError *)error {
	
	// Is the data connection down?
	if ([error.domain isEqualToString: @"NSURLErrorDomain"]) {
		NSString *title = @"Connection Error";
		NSString *description;
		switch (error.code) {
			case NSURLErrorNotConnectedToInternet:
				description = @"This application requires an internet connection in order to provide search results.";
				break;
				
			default:
				description = [error localizedDescription];
				break;
		}
		
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title 
														message:description 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert autorelease];
	}
	else {
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" 
														message:[error localizedDescription] 
													   delegate:self 
											  cancelButtonTitle:@"OK" 
											  otherButtonTitles:nil];
		[alert show];
		[alert autorelease];
	}

}

@end
