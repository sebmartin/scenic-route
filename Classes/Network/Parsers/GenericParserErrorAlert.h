//
//  GenericParserErrorAlert.h
//  ScenicRoute
//
//  Created by Seb on 10-12-22.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface GenericParserErrorAlert : NSObject {

}

+ (void)showAlertForError:(NSError*)error;

@end
