//
//  EGOImageLoader.h
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/15/09.
//  Copyright 2009 enormego. All rights reserved.
//
//  This work is licensed under the Creative Commons GNU General Public License License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/GPL/2.0/
//  or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
//

#import <Foundation/Foundation.h>

@protocol EGOImageLoaderObserver;
@interface EGOImageLoader : NSObject {
@private
	NSDictionary* _currentOperations;
	NSMutableDictionary* currentOperations;
	NSOperationQueue* operationQueue;
}

+ (EGOImageLoader*)sharedImageLoader;

- (BOOL)isLoadingImageURL:(NSURL*)aURL;
- (void)cancelLoadForURL:(NSURL*)aURL;
- (void)loadImageForURL:(NSURL*)aURL observer:(id<EGOImageLoaderObserver>)observer;
- (UIImage*)imageForURL:(NSURL*)aURL shouldLoadWithObserver:(id<EGOImageLoaderObserver>)observer;

- (void)increaseImageLoadPriorityForURL:(NSURL*)aURL;
- (void)decreaseImageLoadPriorityForURL:(NSURL*)aURL;	

@property(nonatomic,retain) NSDictionary* currentOperations;
@property(nonatomic,assign,getter=isSuspended) BOOL suspended;
@end

@protocol EGOImageLoaderObserver<NSObject>
@optional
- (void)imageLoaderDidLoad:(NSNotification*)notification; // Object will be EGOImageLoader, userInfo will contain imageURL and image
- (void)imageLoaderDidFailToLoad:(NSNotification*)notification; // Object will be EGOImageLoader, userInfo will contain error
@end