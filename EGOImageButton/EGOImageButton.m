//
//  EGOImageButton.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/30/09.
//  Copyright 2009 enormego. All rights reserved.
//
//  This work is licensed under the Creative Commons GNU General Public License License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/GPL/2.0/
//  or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
//

#import "EGOImageButton.h"


@implementation EGOImageButton
@synthesize imageURL, placeholderImage, delegate;

- (id)initWithPlaceholderImage:(UIImage*)anImage {
	return [self initWithPlaceholderImage:anImage delegate:nil];	
}

- (id)initWithPlaceholderImage:(UIImage*)anImage delegate:(id<EGOImageButtonDelegate>)aDelegate {
	if((self = [super initWithFrame:CGRectZero])) {
		self.placeholderImage = anImage;
		self.delegate = aDelegate;
		[self setImage:self.placeholderImage forState:UIControlStateNormal];
	}
	
	return self;
}

- (void)setImageURL:(NSURL *)aURL {
	[imageURL release];
	
	if(!aURL) {
		[self setImage:self.placeholderImage forState:UIControlStateNormal];
		imageURL = nil;
		return;
	} else {
		imageURL = [aURL retain];
	}
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	UIImage* anImage = [[EGOImageLoader sharedImageLoader] imageForURL:aURL shouldLoadWithObserver:self];
	
	if(anImage) {
		[self setImage:anImage forState:UIControlStateNormal];
	} else {
		[self setImage:self.placeholderImage forState:UIControlStateNormal];
	}
}

#pragma mark -
#pragma mark Image loading

- (void)increaseImageLoadPriority {
	[[EGOImageLoader sharedImageLoader] increaseImageLoadPriorityForURL:self.imageURL];
}

- (void)decreaseImageLoadPriority {
	[[EGOImageLoader sharedImageLoader] decreaseImageLoadPriorityForURL:self.imageURL];
}

- (void)imageLoaderDidLoad:(NSNotification*)notification {
	if(![[[notification userInfo] objectForKey:@"imageURL"] isEqual:self.imageURL]) return;
	
	UIImage* anImage = [[notification userInfo] objectForKey:@"image"];
	[self setImage:anImage forState:UIControlStateNormal];
	[self setNeedsDisplay];
	
	if([self.delegate respondsToSelector:@selector(imageButtonLoadedImage:)]) {
		[self.delegate imageButtonLoadedImage:self];
	}	
}

- (void)imageLoaderDidFailToLoad:(NSNotification*)notification {
	if(![[[notification userInfo] objectForKey:@"imageURL"] isEqual:self.imageURL]) return;
	
	if([self.delegate respondsToSelector:@selector(imageButtonFailedToLoadImage:error:)]) {
		[self.delegate imageButtonFailedToLoadImage:self error:[[notification userInfo] objectForKey:@"error"]];
	}
}

#pragma mark -
- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	self.imageURL = nil;
	self.placeholderImage = nil;
    [super dealloc];
}

@end
