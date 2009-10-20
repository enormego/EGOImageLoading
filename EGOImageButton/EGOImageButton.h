//
//  EGOImageButton.h
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/30/09.
//  Copyright 2009 enormego. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGOImageLoader.h"

@protocol EGOImageButtonDelegate;
@interface EGOImageButton : UIButton<EGOImageLoaderObserver> {
@private
	NSURL* imageURL;
	UIImage* placeholderImage;
	id<EGOImageButtonDelegate> delegate;
}

- (id)initWithPlaceholderImage:(UIImage*)anImage; // delegate:nil
- (id)initWithPlaceholderImage:(UIImage*)anImage delegate:(id<EGOImageButtonDelegate>)aDelegate;

- (void)increaseImageLoadPriority;
- (void)decreaseImageLoadPriority;

@property(nonatomic,retain) NSURL* imageURL;
@property(nonatomic,retain) UIImage* placeholderImage;
@property(nonatomic,retain) id<EGOImageButtonDelegate> delegate;
@end

@protocol EGOImageButtonDelegate<NSObject>
@optional
- (void)imageButtonLoadedImage:(EGOImageButton*)imageButton;
- (void)imageButtonFailedToLoadImage:(EGOImageButton*)imageButton error:(NSError*)error;
@end