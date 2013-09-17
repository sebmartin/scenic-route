//
//  WaitView.m
//  ScenicRoute
//
//  Created by Seb on 10-12-26.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "WaitView.h"


@implementation WaitView

- (BOOL) canBecomeFirstResponder {
	return YES;
}

-(void) touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[[NSNotificationCenter defaultCenter] postNotification:
	 [NSNotification notificationWithName:@"hideKeyboard" object:self]];
}

@end
