//
//  EGOImageView.h
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/15/09.
//  Copyright 2009 enormego. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EGOImageLoader.h"

@protocol EGOImageViewDelegate;
@interface EGOImageView : UIImageView<EGOImageLoaderObserver> {
@private
	NSURL* imageURL;
	UIImage* placeholderImage;
	id<EGOImageViewDelegate> delegate;
}

- (id)initWithPlaceholderImage:(UIImage*)anImage; // delegate:nil
- (id)initWithPlaceholderImage:(UIImage*)anImage delegate:(id<EGOImageViewDelegate>)aDelegate;

- (void)increaseImageLoadPriority;
- (void)decreaseImageLoadPriority;

@property(nonatomic,retain) NSURL* imageURL;
@property(nonatomic,retain) UIImage* placeholderImage;
@property(nonatomic,retain) id<EGOImageViewDelegate> delegate;
@end

@protocol EGOImageViewDelegate<NSObject>
@optional
- (void)imageViewLoadedImage:(EGOImageView*)imageView;
- (void)imageViewFailedToLoadImage:(EGOImageView*)imageView error:(NSError*)error;
@end