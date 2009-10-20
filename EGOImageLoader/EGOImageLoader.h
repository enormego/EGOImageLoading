//
//  EGOImageLoader.h
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/15/09.
//  Copyright 2009 enormego. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EGOImageLoaderObserver;
@interface EGOImageLoader : NSObject {
@private
	NSOperationQueue* operationQueue;
}

+ (EGOImageLoader*)sharedImageLoader;

- (BOOL)isLoadingImageURL:(NSURL*)aURL;
- (void)cancelLoadForURL:(NSURL*)aURL;
- (void)loadImageForURL:(NSURL*)aURL observer:(id<EGOImageLoaderObserver>)observer;
- (UIImage*)imageForURL:(NSURL*)aURL shouldLoadWithObserver:(id<EGOImageLoaderObserver>)observer;

- (void)increaseImageLoadPriorityForURL:(NSURL*)aURL;
- (void)decreaseImageLoadPriorityForURL:(NSURL*)aURL;	

@end

@protocol EGOImageLoaderObserver<NSObject>
@optional
- (void)imageLoaderDidLoad:(NSNotification*)notification; // Object will be EGOImageLoader, userInfo will contain imageURL and image
- (void)imageLoaderDidFailToLoad:(NSNotification*)notification; // Object will be EGOImageLoader, userInfo will contain error
@end