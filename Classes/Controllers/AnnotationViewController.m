//
//  AnnotationViewController.m
//  ScenicRoute
//
//  Created by Etienne Martin on 10-12-13.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "AnnotationViewController.h"


@implementation AnnotationViewController

@synthesize annotation;

#pragma mark -
#pragma mark View lifecycle

- (id) initWithAnnotation:(POIAnnotation*) annot {
	if (self = [super initWithNibName:@"AnnotationViewController" bundle:nil]) {
		self.annotation = annot;
	} 
	return self;
}

- (void) onClickYellowPagesBadge:(UIButton*)sender {
	NSLog(@"Clicked YellowPages Badge");
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://badge.yellowapi.com/"]];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.rightBarButtonItem = self.editButtonItem;
	
	self.title = @"Info";
	[self.navigationController setNavigationBarHidden:NO animated:YES];
	
}

/*
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}
*/
/*
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}
*/

- (void)viewWillDisappear:(BOOL)animated {
	
	
	
	[self.navigationController setNavigationBarHidden:YES animated:YES];
    [super viewWillDisappear:animated];
	
}

/*
- (void)viewDidDisappear:(BOOL)animated {
	[super viewDidDisappear:animated];
}
*/

/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/


#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)table {
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {

	if (section == 0) {
		return 1;
	} else if (section == 1) {
		return 1;
	} else if (section == 2) {
		return 1;
	} else if (section == 3) {
		return 2;
	}
	
    return 1;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
	
	if (cell == nil && indexPath.section == 0) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
									   reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
    } else if (cell == nil && indexPath.section == 1) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2
									   reuseIdentifier:CellIdentifier] autorelease];
		cell.selectionStyle = UITableViewCellSelectionStyleNone;
	} else {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
									   reuseIdentifier:CellIdentifier] autorelease];		
	}
		
	// Set up the cell...
	if(indexPath.section == 0) {
		
		cell.textLabel.text = annotation.Name;
		if ([annotation.Email compare:@""] != NSOrderedSame ) {
			cell.detailTextLabel.text = annotation.Email;
		}
		
	} else if (indexPath.section == 1 ) {
		
		cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
		cell.textLabel.text = @"Address";
		cell.detailTextLabel.font = [UIFont systemFontOfSize:13];
		cell.detailTextLabel.text = [NSString stringWithFormat: @"%@\n%@, %@\n%@", 
									 annotation.Address, 
									 annotation.City, 
									 annotation.Province, 
									 annotation.PostalCode]; 
		
	} else if (indexPath.section == 2) {
		
		//&& [[annotation.URL absoluteString] compare:@""] != NSOrderedSame 
		//cell.detailTextLabel.text = [annotation.URL absoluteString];
		//cell.detailTextLabel.text = @"http://www.samplewebsite.com";
		
		cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
		cell.textLabel.font = [UIFont systemFontOfSize:13];
		
		if ([[annotation.URL absoluteString] compare:@""] == NSOrderedSame) {
			cell.textLabel.text = @"Google Search";
		} else {
			cell.textLabel.text = @"Website";
		}
		
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		
	} else if (indexPath.section == 3) {
		
		cell.textLabel.textAlignment = UITextAlignmentCenter;
		cell.textLabel.font = [UIFont systemFontOfSize:13];
		cell.textLabel.textColor = [UIColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:1.0];
		
		switch (indexPath.row) {
			case 0:
				cell.textLabel.text = @"Direction To Here";
				break;
				// Address
			case 1:
				cell.textLabel.text = @"Direction From Here";
				break;
			default:
				break;
		}
	}
	
	cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.numberOfLines = 0;
    [cell.textLabel sizeToFit];
	
	cell.detailTextLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.detailTextLabel.numberOfLines = 0;
    [cell.detailTextLabel sizeToFit];
	
	return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section {


	UIButton *footerView  = [[UIView alloc] init];
	
	if(section == 3) {
		
		//create the button
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        
		[button setBackgroundImage:[UIImage imageNamed:@"yp_badge.png"] forState:UIControlStateNormal];
		
		//the button should be as big as a table view cell
        [button setFrame:CGRectMake(210, 3, 100, 40)];

		button.userInteractionEnabled = YES;
		footerView.userInteractionEnabled = YES;
		
        //set action of the button
        [button addTarget:self
				   action:@selector(onClickYellowPagesBadge:)
		 forControlEvents:UIControlEventTouchUpInside];

		
        //add the button to the view
        [footerView addSubview:button];
	}
	
	return [footerView autorelease];

}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
	if(section == 3)
		return 40;
	else
		return 0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];

	int fontSize = 14;
	
	uint textHeight   = 0;
	uint detailHeight = 0;
	
	CGSize tempSize;
	CGSize theTextSize;

	if (indexPath.section == 0) {
		tempSize.width = 310;
		fontSize = 22;
	} else {
		tempSize.width = 240;
	}
	
	tempSize.height = 99999;
	
	// Calculate Detail Text Height
	theTextSize = [cell.detailTextLabel.text sizeWithFont: [UIFont systemFontOfSize:fontSize] constrainedToSize: tempSize];
	detailHeight = theTextSize.height + 5;
	
	if (indexPath.section > 0)	
		tempSize.width = 70;	
	
	// Calculcate Text Label Height
	theTextSize = [cell.textLabel.text sizeWithFont: [UIFont systemFontOfSize:fontSize] constrainedToSize: tempSize];
	textHeight = theTextSize.height + 5;
	
	// If top view, return both heights, else, return the biggest of the two
	if(indexPath.section == 0)
		return (detailHeight + textHeight);
	else if (indexPath.section == 2 || indexPath.section == 3)
		return 40;
	else
		return (detailHeight > textHeight) ? detailHeight : textHeight; 

}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/
/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:YES];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/
/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/
/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    // Navigation logic may go here. Create and push another view controller.
	/*
	 <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
	 [self.navigationController pushViewController:detailViewController animated:YES];
	 [detailViewController release];
	 */
	
	// Click for Website
	if(indexPath.section == 2){
		
		NSLog(@"Attempting to open URL: --%@--", annotation.URL);
		
		//http://www.google.ca/#sclient=psy&q=
		if ([[annotation.URL absoluteString] compare:@""] == NSOrderedSame) {
			
			NSString *URLString = [NSString stringWithFormat: @"http://www.google.ca/m/search?q=%@", annotation.Name];
			URLString = [URLString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
			NSLog(@"Opening Annotation URL: %@", URLString);
			[[UIApplication sharedApplication] openURL:[NSURL URLWithString:URLString]];
		} else {
			NSLog(@"Opening Annotation URL: %@", [annotation.URL absoluteString]);
			[[UIApplication sharedApplication] openURL:annotation.URL];
		}
		
	} else if (indexPath.section == 3) {
		if (indexPath.row == 0) {
			// TODO: Add call to Destinations
		} else {
			// TODO: Add call to Destinations
		}
	}
	
	// Direction Buttons
	if(indexPath.section == 3) {
		
		NSString *searchAddress =[NSString stringWithFormat: @"%@,%@,%@,%@", 
															annotation.Address, 
															annotation.City, 
															annotation.Province, 
															annotation.PostalCode]; 
		
		NSDictionary *dict = [[NSDictionary alloc] initWithObjectsAndKeys:searchAddress, @"address", nil];
		
		// Determine which button was selected
		if (indexPath.row == 0) {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AnnotationDirectionToHere" 
																object:self
			                                                  userInfo:dict];
		} else {
			[[NSNotificationCenter defaultCenter] postNotificationName:@"AnnotationDirectionFromHere" 
																object:self 
															  userInfo:dict];
		}
		[dict release];
		
		// Return to the map view
		[self.navigationController popViewControllerAnimated:YES];
		
	}
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Relinquish ownership any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
    // Relinquish ownership of anything that can be recreated in viewDidLoad or on demand.
    // For example: self.myOutlet = nil;
}


- (void)dealloc {
	[super dealloc];
}


@end

