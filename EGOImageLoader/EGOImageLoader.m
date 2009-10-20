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
#import "Reachability.h"
#import "ASIHTTPRequest.h"

static EGOImageLoader* __imageLoader;

inline static NSString* keyForURL(NSURL* url) {
	return [NSString stringWithFormat:@"EGOImageLoader-%u", [[url description] hash]];
}

#define kImageNotificationLoaded(s) [@"kEGOImageLoaderNotificationLoaded-" stringByAppendingString:keyForURL(s)]
#define kImageNotificationLoadFailed(s) [@"kEGOImageLoaderNotificationLoadFailed-" stringByAppendingString:keyForURL(s)]

@implementation EGOImageLoader

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

- (ASIHTTPRequest*)loadingRequestForURL:(NSURL*)aURL {
	NSArray* operations = [[[operationQueue operations] copy] autorelease];
	
	for(ASIHTTPRequest* operation in operations) {
		if(![operation isKindOfClass:[ASIHTTPRequest class]]) continue;
		
		if(![operation isFinished] && ![operation isCancelled] && ![operation isExecuting]) {
			if([operation.url isEqual:aURL]) return [[operation retain] autorelease];
		}
	}
	
	return nil;
}

- (BOOL)isLoadingImageURL:(NSURL*)aURL {
	return [self loadingRequestForURL:aURL] ? YES : NO;
}

- (void)cancelLoadForURL:(NSURL*)aURL {
	ASIHTTPRequest* request = [self loadingRequestForURL:aURL];
	request.delegate = nil;
	[request cancel];
}

- (void)increaseImageLoadPriorityForURL:(NSURL*)aURL {
	ASIHTTPRequest* request = [self loadingRequestForURL:aURL];
	
	if(![request isFinished] && ![request isCancelled] && ![request isExecuting]) {
		request.queuePriority = NSOperationQueuePriorityHigh;
	}
}

- (void)decreaseImageLoadPriorityForURL:(NSURL*)aURL {
	ASIHTTPRequest* request = [self loadingRequestForURL:aURL];

	if(![request isFinished] && ![request isCancelled] && ![request isExecuting]) {
		request.queuePriority = NSOperationQueuePriorityLow;
	}
}

- (void)loadImageForURL:(NSURL*)aURL observer:(id<EGOImageLoaderObserver>)observer {
	if([observer respondsToSelector:@selector(imageLoaderDidLoad:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidLoad:) name:kImageNotificationLoaded(aURL) object:self];
	}
	
	if([observer respondsToSelector:@selector(imageLoaderDidFailToLoad:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidFailToLoad:) name:kImageNotificationLoadFailed(aURL) object:self];
	}
	
	ASIHTTPRequest* request;
	if((request = [[[self loadingRequestForURL:aURL] retain] autorelease])) {
		if(![request isFinished] && ![request isCancelled] && ![request isExecuting]) {
			request.queuePriority = NSOperationQueuePriorityHigh;
		}
		
		return;
	}
		
	request = [[ASIHTTPRequest alloc] initWithURL:aURL];
	request.queuePriority = NSOperationQueuePriorityHigh;
	request.timeOutSeconds = 30.0;
	request.delegate = self;
	request.didFinishSelector = @selector(imageLoadFinished:);
	request.didFailSelector = @selector(imageLoadFailed:);
	[operationQueue addOperation:request];
	[request release];
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
- (void)imageLoadFinished:(ASIHTTPRequest*)request {
	if(request.responseStatusCode != 200) {
		NSError* error = [NSError errorWithDomain:[request.url host] code:request.responseStatusCode userInfo:nil];
		NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(request.url)
																	 object:self
																   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",request.url,@"imageURL",nil]];
		
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		return;
	}
	
	NSData* responseData = [request responseData];
	UIImage* anImage = [UIImage imageWithData:responseData];
	
	if(!anImage) {
		NSError* error = [NSError errorWithDomain:[request.url host] code:406 userInfo:nil];
		NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(request.url)
																	 object:self
																   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",request.url,@"imageURL",nil]];
		
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		return;
	}
	
	[[EGOCache currentCache] setData:responseData forKey:keyForURL(request.url) withTimeoutInterval:604800];
	
	NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoaded(request.url)
																 object:self
															   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:anImage,@"image",request.url,@"imageURL",nil]];
	
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

- (void)imageLoadFailed:(ASIHTTPRequest*)request {
	NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(request.url)
																 object:self
															   userInfo:[NSDictionary dictionaryWithObject:request.error forKey:@"error"]];

	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
}

#pragma mark -

- (void)dealloc {
	[operationQueue release];
	[super dealloc];
}

@end
