//
//  DataParser.m
//  ScenicRoute
//
//  Created by Etienne Martin on 10-10-21.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "DataParser.h"
#import <CommonCrypto/CommonDigest.h>

@implementation DataParser

@synthesize sourceUrl;
@synthesize error;
@synthesize delegate;
@synthesize responseData;
@synthesize context;

#pragma mark -
#pragma mark Constructors

// Default Constructor
- (id) init {
	return [self initWithURL:nil delegate: nil];
}

// Custom Constructor
- (id) initWithURL: (NSURL*) url delegate: (id<DataParserDelegate>) del {
    if (self = [super init]) {
        self.sourceUrl = url;
		self.error     = nil;
		self.delegate  = del;
		self.responseData = [NSMutableData data];
    }
    return self;	
}

- (NSString*) getClientUID {
	
	const char *src = [[UIDevice currentDevice].uniqueIdentifier UTF8String];
	unsigned char result[16];
	CC_MD5(src, strlen(src), result);
    NSString *ret = [[[NSString alloc] initWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
					  result[0], result[1], result[2], result[3],
					  result[4], result[5], result[6], result[7],
					  result[8], result[9], result[10], result[11],
					  result[12], result[13], result[14], result[15]
					  ] autorelease];
    return [ret lowercaseString];

}

#pragma mark -
#pragma mark Parser Actions

// Create URL for request, and send it out
- (void) fetchData: (NSString*) keyword {
	[self sendRequest];
}

// This is meant to be overridden by the children classes. It will
// handle the incoming data and parse into usable map data
- (void) parseData {
	// Does nothing for base class, sends URL as is.
	NSLog(@"DataParser> base parseData() called");
}

// Send out Asyncronous request. This shouldn't need to be overwridden by children
- (void) sendRequest {
	if(self.sourceUrl == nil) return;
	NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:sourceUrl];
	[[[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES] release];
	// TODO: Validate sent command for Errors
}

#pragma mark -
#pragma mark NSConnection implementation

// Handle event where response is received
- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	// Notify delegate that search is done
	[[self delegate] searchFinished];
}

// Handle incoming data from request
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	if(data == nil) {
		NSLog(@"DataParser> No Data has been returned from %@", [self class]);
	} else {
		// Since data is recieved in multiple blocks, we need to append the data
		// as it comes in.
		[responseData appendData:data];
	}
}

// Handle connection failure
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)err {
	
	// Call the delegate
	[[self delegate] parser:self didFailWithError:err];
	
	if(err == nil)
		NSLog(@"DataParser> Connection failed! URL:%@, no error specified", [self.sourceUrl absoluteURL]);
	else {
		NSLog(@"DataParser> Connection failed! URL:%@, error: %@, error code: %d", 
			  [self.sourceUrl absoluteURL], 
			  [self.error description],
			  [self.error code]);
		self.error = err;
	}
}


// Handle end of connection (request finished)
- (void) connectionDidFinishLoading:(NSURLConnection *)connection {
	
	// Parse incoming data
	[self parseData];
	
}

#pragma mark -
#pragma mark Memory Handlers

// Destructor (clean up)
- (void) dealloc {
    [sourceUrl release];
	[error release];
	[responseData release];
	
    [super dealloc];
}

@end
