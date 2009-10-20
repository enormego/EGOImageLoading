//
//  RootViewController.h
//  EGOImageLoadingDemo
//
//  Created by Shaun Harrison on 10/19/09.
//  Copyright enormego 2009. All rights reserved.
//

@interface RootViewController : UITableViewController {
@private
	NSArray* flickrPhotos;
}

- (IBAction)clearCache;
- (IBAction)jumpToBottom;

@end
