//
//  EGOImageLoader.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/15/09.
//  Copyright 2009 enormego. All rights reserved.
//
//  This work is licensed under the Creative Commons GNU General Public License License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/GPL/2.0/
//  or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
//

#import "EGOImageLoader.h"
#import "EGOCache.h"
#import "EGOImageLoadOperation.h"
#import "Reachability.h"

static EGOImageLoader* __imageLoader;

inline static NSString* keyForURL(NSURL* url) {
	return [NSString stringWithFormat:@"EGOImageLoader-%u", [[url description] hash]];
}

#define kImageNotificationLoaded(s) [@"kEGOImageLoaderNotificationLoaded-" stringByAppendingString:keyForURL(s)]
#define kImageNotificationLoadFailed(s) [@"kEGOImageLoaderNotificationLoadFailed-" stringByAppendingString:keyForURL(s)]

@implementation EGOImageLoader
@synthesize currentOperations=_currentOperations;

+ (EGOImageLoader*)sharedImageLoader {
	@synchronized(self) {
		if(!__imageLoader) {
			__imageLoader = [[[self class] alloc] init];
		}
	}
	
	return __imageLoader;
}

- (id)init {
	if((self = [super init])) {
		operationQueue = [[NSOperationQueue alloc] init];

		if([[Reachability sharedReachability] internetConnectionStatus] == ReachableViaWiFiNetwork) {
			[operationQueue setMaxConcurrentOperationCount:3];
		}
	}
	
	return self;
}

- (EGOImageLoadOperation*)loadingOperationForURL:(NSURL*)aURL {
	EGOImageLoadOperation* operation = [[self.currentOperations objectForKey:aURL] retain];
	if(!operation) return nil;
	
	if(![operation isFinished] && ![operation isCancelled] && ![operation isExecuting]) {
		return [operation autorelease];
	} else {
		[operation release];
		return nil;
	}
}

- (BOOL)isLoadingImageURL:(NSURL*)aURL {
	return [self loadingOperationForURL:aURL] ? YES : NO;
}

- (void)cancelLoadForURL:(NSURL*)aURL {
	EGOImageLoadOperation* operation = [self loadingOperationForURL:aURL];
	[operation cancel];
}

- (void)increaseImageLoadPriorityForURL:(NSURL*)aURL {
	EGOImageLoadOperation* operation = [[self loadingOperationForURL:aURL] retain];
	operation.queuePriority = NSOperationQueuePriorityHigh;
	[operation release];
}

- (void)decreaseImageLoadPriorityForURL:(NSURL*)aURL {
	EGOImageLoadOperation* operation = [[self loadingOperationForURL:aURL] retain];
	operation.queuePriority = NSOperationQueuePriorityLow;
	[operation release];
}

- (void)loadImageForURL:(NSURL*)aURL observer:(id<EGOImageLoaderObserver>)observer {
	if([observer respondsToSelector:@selector(imageLoaderDidLoad:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidLoad:) name:kImageNotificationLoaded(aURL) object:self];
	}
	
	if([observer respondsToSelector:@selector(imageLoaderDidFailToLoad:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidFailToLoad:) name:kImageNotificationLoadFailed(aURL) object:self];
	}
	
	EGOImageLoadOperation* operation;
	if((operation = [[self loadingOperationForURL:aURL] retain])) {
		if(![operation isFinished] && ![operation isCancelled] && ![operation isExecuting]) {
			operation.queuePriority = NSOperationQueuePriorityHigh;
		}
		
		[operation release];
		return;
	}
		
	operation = [[EGOImageLoadOperation alloc] initWithImageURL:aURL];
	operation.queuePriority = NSOperationQueuePriorityHigh;
	operation.timeoutInterval = 30.0;
	operation.delegate = (id<EGOImageLoadOperationDelegate>)self;
	[operationQueue addOperation:operation];
	[currentOperations setObject:operation forKey:operation.imageURL];
	self.currentOperations = [[currentOperations copy] autorelease];
}

- (UIImage*)imageForURL:(NSURL*)aURL shouldLoadWithObserver:(id<EGOImageLoaderObserver>)observer {
	UIImage* anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL)];

	if(anImage) {
		return anImage;
	} else {
		[self loadImageForURL:(NSURL*)aURL observer:observer];
		return nil;
	}
}

#pragma mark -
#pragma mark Request methods
- (void)imageLoadOperation:(EGOImageLoadOperation*)operation didFinishWithData:(NSData*)imageData {
	UIImage* anImage = [UIImage imageWithData:imageData];
	
	if(!anImage) {
		NSError* error = [NSError errorWithDomain:[operation.imageURL host] code:406 userInfo:nil];
		NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(operation.imageURL)
																	 object:self
																   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",operation.imageURL,@"imageURL",nil]];
		
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		return;
	}
	
	[[EGOCache currentCache] setData:imageData forKey:keyForURL(operation.imageURL) withTimeoutInterval:604800];
	
	[currentOperations removeObjectForKey:operation.imageURL];
	self.currentOperations = [[currentOperations copy] autorelease];
	
	NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoaded(operation.imageURL)
																 object:self
															   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:anImage,@"image",operation.imageURL,@"imageURL",nil]];
	
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

- (void)imageLoadOperationDidFail:(EGOImageLoadOperation*)operation {
	[currentOperations removeObjectForKey:operation.imageURL];
	self.currentOperations = [[currentOperations copy] autorelease];

	NSError* error = [NSError errorWithDomain:[operation.imageURL host] code:406 userInfo:nil];
	NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(operation.imageURL)
																 object:self
															   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",operation.imageURL,@"imageURL",nil]];
	
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

#pragma mark -

- (BOOL)isSuspended {
	return [operationQueue isSuspended];	
}

- (void)setSuspended:(BOOL)isSuspended {
	[operationQueue setSuspended:isSuspended];
}

#pragma mark -

- (void)dealloc {
	self.currentOperations = nil;
	[currentOperations release];
	[operationQueue release];
	[super dealloc];
}

@end
