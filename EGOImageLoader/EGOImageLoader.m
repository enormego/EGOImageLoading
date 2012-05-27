//
//  EGOImageLoader.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 9/15/09.
//  Copyright (c) 2009-2010 enormego
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "EGOImageLoader.h"
#import "EGOImageLoadConnection.h"
#import "EGOCache.h"

static EGOImageLoader* __imageLoader;

inline static NSString* keyForURL(NSURL* url, NSString* style) {
	if(style) {
		return [NSString stringWithFormat:@"EGOImageLoader-%u-%u", [[url description] hash], [style hash]];
	} else {
		return [NSString stringWithFormat:@"EGOImageLoader-%u", [[url description] hash]];
	}
}

#if __EGOIL_USE_BLOCKS
	#define kNoStyle @"EGOImageLoader-nostyle"
	#define kCompletionsKey @"completions"
	#define kStylerKey @"styler"
	#define kStylerQueue _operationQueue
	#define kCompletionsQueue dispatch_get_main_queue()
#endif

#if __EGOIL_USE_NOTIF
	#define kImageNotificationLoaded(s) [@"kEGOImageLoaderNotificationLoaded-" stringByAppendingString:keyForURL(s, nil)]
	#define kImageNotificationLoadFailed(s) [@"kEGOImageLoaderNotificationLoadFailed-" stringByAppendingString:keyForURL(s, nil)]
#endif

@interface EGOImageLoader ()
#if __EGOIL_USE_BLOCKS
- (void)handleCompletionsForConnection:(EGOImageLoadConnection*)connection image:(UIImage*)image error:(NSError*)error;
#endif
@end

@implementation EGOImageLoader
@synthesize currentConnections=_currentConnections;

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
		connectionsLock = [[NSLock alloc] init];
		currentConnections = [[NSMutableDictionary alloc] init];
		
		#if __EGOIL_USE_BLOCKS
		_operationQueue = dispatch_queue_create("com.enormego.EGOImageLoader",NULL);
		dispatch_queue_t priority = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH,0);
		dispatch_set_target_queue(priority, _operationQueue);
		#endif
	}
	
	return self;
}

- (EGOImageLoadConnection*)loadingConnectionForURL:(NSURL*)aURL {
#if EGO_NO_ARC
	EGOImageLoadConnection* connection = [[self.currentConnections objectForKey:aURL] retain];
#else
    EGOImageLoadConnection* connection = [self.currentConnections objectForKey:aURL];
#endif
	if(!connection) return nil;
    else {
#if EGO_NO_ARC
        [connection autorelease];
#endif
        return connection;
    }
}

- (void)cleanUpConnection:(EGOImageLoadConnection*)connection {
	if(!connection.imageURL) return;
	
	connection.delegate = nil;
	
	[connectionsLock lock];
	[currentConnections removeObjectForKey:connection.imageURL];
    self.currentConnections = [currentConnections copy];
#if EGO_NO_ARC
	[self.currentConnections autorelease];
#endif
	[connectionsLock unlock];	
}

- (void)clearCacheForURL:(NSURL*)aURL {
	[self clearCacheForURL:aURL style:nil];
}

- (void)clearCacheForURL:(NSURL*)aURL style:(NSString*)style {
	[[EGOCache currentCache] removeCacheForKey:keyForURL(aURL, style)];
}

- (BOOL)isLoadingImageURL:(NSURL*)aURL {
	return [self loadingConnectionForURL:aURL] ? YES : NO;
}

- (void)cancelLoadForURL:(NSURL*)aURL {
	EGOImageLoadConnection* connection = [self loadingConnectionForURL:aURL];
	[NSObject cancelPreviousPerformRequestsWithTarget:connection selector:@selector(start) object:nil];
	[connection cancel];
	[self cleanUpConnection:connection];
}

- (EGOImageLoadConnection*)loadImageForURL:(NSURL*)aURL {
	EGOImageLoadConnection* connection;
	
	if((connection = [self loadingConnectionForURL:aURL])) {
		return connection;
	} else {
		connection = [[EGOImageLoadConnection alloc] initWithImageURL:aURL delegate:self];
	
		[connectionsLock lock];
		[currentConnections setObject:connection forKey:aURL];
        self.currentConnections = [currentConnections copy];
#if EGO_NO_ARC
		[self.currentConnections autorelease]; 
#endif
		[connectionsLock unlock];
		[connection performSelector:@selector(start) withObject:nil afterDelay:0.01];
#if EGO_NO_ARC
		[connection release];
#endif
		
		return connection;
	}
}

#if __EGOIL_USE_NOTIF
- (void)loadImageForURL:(NSURL*)aURL observer:(id<EGOImageLoaderObserver>)observer {
	if(!aURL) return;
	
	if([observer respondsToSelector:@selector(imageLoaderDidLoad:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidLoad:) name:kImageNotificationLoaded(aURL) object:self];
	}
	
	if([observer respondsToSelector:@selector(imageLoaderDidFailToLoad:)]) {
		[[NSNotificationCenter defaultCenter] addObserver:observer selector:@selector(imageLoaderDidFailToLoad:) name:kImageNotificationLoadFailed(aURL) object:self];
	}

	[self loadImageForURL:aURL];
}

- (UIImage*)imageForURL:(NSURL*)aURL shouldLoadWithObserver:(id<EGOImageLoaderObserver>)observer {
	if(!aURL) return nil;
	
	UIImage* anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL,nil)];
	
	if(anImage) {
		return anImage;
	} else {
		[self loadImageForURL:aURL observer:observer];
		return nil;
	}
}

- (void)removeObserver:(id<EGOImageLoaderObserver>)observer {
	[[NSNotificationCenter defaultCenter] removeObserver:observer name:nil object:self];
}

- (void)removeObserver:(id<EGOImageLoaderObserver>)observer forURL:(NSURL*)aURL {
	[[NSNotificationCenter defaultCenter] removeObserver:observer name:kImageNotificationLoaded(aURL) object:self];
	[[NSNotificationCenter defaultCenter] removeObserver:observer name:kImageNotificationLoadFailed(aURL) object:self];
}

#endif

#if __EGOIL_USE_BLOCKS
- (void)loadImageForURL:(NSURL*)aURL completion:(void (^)(UIImage* image, NSURL* imageURL, NSError* error))completion {
	[self loadImageForURL:aURL style:nil styler:nil completion:completion];
}

- (void)loadImageForURL:(NSURL*)aURL style:(NSString*)style styler:(UIImage* (^)(UIImage* image))styler completion:(void (^)(UIImage* image, NSURL* imageURL, NSError* error))completion {
	UIImage* anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL,style)];

	if(anImage) {
		completion(anImage, aURL, nil);
	} else if(!anImage && styler && style && (anImage = [[EGOCache currentCache] imageForKey:keyForURL(aURL,nil)])) {
		dispatch_async(kStylerQueue, ^{
			UIImage* image = styler(anImage);
			[[EGOCache currentCache] setImage:image forKey:keyForURL(aURL, style) withTimeoutInterval:604800];
			dispatch_async(kCompletionsQueue, ^{
				completion(image, aURL, nil);
			});
		});
	} else {
		EGOImageLoadConnection* connection = [self loadImageForURL:aURL];
		void (^completionCopy)(UIImage* image, NSURL* imageURL, NSError* error) = [completion copy];
		
		NSString* handlerKey = style ? style : kNoStyle;
		NSMutableDictionary* handler = [connection.handlers objectForKey:handlerKey];
		
		if(!handler) {
			handler = [[NSMutableDictionary alloc] initWithCapacity:2];
			[connection.handlers setObject:handler forKey:handlerKey];

			[handler setObject:[NSMutableArray arrayWithCapacity:1] forKey:kCompletionsKey];
			if(styler) {
				UIImage* (^stylerCopy)(UIImage* image) = [styler copy];
				[handler setObject:stylerCopy forKey:kStylerKey];
#if EGO_NO_ARC
				[stylerCopy release];
#endif
			}
			
#if EGO_NO_ARC
			[handler release];
#endif
		}
		
		[[handler objectForKey:kCompletionsKey] addObject:completionCopy];
#if EGO_NO_ARC
		[completionCopy release];
#endif
	}
}
#endif

- (BOOL)hasLoadedImageURL:(NSURL*)aURL {
	return [[EGOCache currentCache] hasCacheForKey:keyForURL(aURL,nil)];
}

#pragma mark -
#pragma mark URL Connection delegate methods

- (void)imageLoadConnectionDidFinishLoading:(EGOImageLoadConnection *)connection {
	UIImage* anImage = [UIImage imageWithData:connection.responseData];
	
	if(!anImage) {
		NSError* error = [NSError errorWithDomain:[connection.imageURL host] code:406 userInfo:nil];
		
		#if __EGOIL_USE_NOTIF
		NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(connection.imageURL)
																	 object:self
																   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",connection.imageURL,@"imageURL",nil]];
		
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		#endif
		
		#if __EGOIL_USE_BLOCKS
		[self handleCompletionsForConnection:connection image:nil error:error];
		#endif
	} else {
		[[EGOCache currentCache] setData:connection.responseData forKey:keyForURL(connection.imageURL,nil) withTimeoutInterval:604800];
		
		[currentConnections removeObjectForKey:connection.imageURL];
        self.currentConnections = [currentConnections copy];
#if EGO_NO_ARC
		[self.currentConnections autorelease];
#endif
		
		#if __EGOIL_USE_NOTIF
		NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoaded(connection.imageURL)
																	 object:self
																   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:anImage,@"image",connection.imageURL,@"imageURL",nil]];
		
		[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
		#endif
		
		#if __EGOIL_USE_BLOCKS
		[self handleCompletionsForConnection:connection image:anImage error:nil];
		#endif
	}
	
	

	[self cleanUpConnection:connection];
}

- (void)imageLoadConnection:(EGOImageLoadConnection *)connection didFailWithError:(NSError *)error {
	[currentConnections removeObjectForKey:connection.imageURL];
    self.currentConnections = [currentConnections copy];
#if EGO_NO_ARC
	[self.currentConnections autorelease];
#endif
	
	#if __EGOIL_USE_NOTIF
	NSNotification* notification = [NSNotification notificationWithName:kImageNotificationLoadFailed(connection.imageURL)
																 object:self
															   userInfo:[NSDictionary dictionaryWithObjectsAndKeys:error,@"error",connection.imageURL,@"imageURL",nil]];
	
	[[NSNotificationCenter defaultCenter] performSelectorOnMainThread:@selector(postNotification:) withObject:notification waitUntilDone:YES];
	#endif
	
	#if __EGOIL_USE_BLOCKS
	[self handleCompletionsForConnection:connection image:nil error:error];
	#endif

	[self cleanUpConnection:connection];
}

#if __EGOIL_USE_BLOCKS
- (void)handleCompletionsForConnection:(EGOImageLoadConnection*)connection image:(UIImage*)image error:(NSError*)error {
	if([connection.handlers count] == 0) return;

	NSURL* imageURL = connection.imageURL;
	
	void (^callCompletions)(UIImage* anImage, NSArray* completions) = ^(UIImage* anImage, NSArray* completions) {
		dispatch_async(kCompletionsQueue, ^{
			for(void (^completion)(UIImage* image, NSURL* imageURL, NSError* error) in completions) {
				completion(anImage, connection.imageURL, error);
			}
		});
	};
	
	for(NSString* styleKey in connection.handlers) {
		NSDictionary* handler = [connection.handlers objectForKey:styleKey];
		UIImage* (^styler)(UIImage* image) = [handler objectForKey:kStylerKey];
		if(!error && image && styler) {
			dispatch_async(kStylerQueue, ^{
				UIImage* anImage = styler(image);
				[[EGOCache currentCache] setImage:anImage forKey:keyForURL(imageURL, styleKey) withTimeoutInterval:604800];
				callCompletions(anImage, [handler objectForKey:kCompletionsKey]);
			});
		} else {
			callCompletions(image, [handler objectForKey:kCompletionsKey]);
		}
	}
}
#endif

#pragma mark -

- (void)dealloc {
	#if __EGOIL_USE_BLOCKS
		dispatch_release(_operationQueue), _operationQueue = nil;
	#endif
	
	self.currentConnections = nil;
#if EGO_NO_ARC
	[currentConnections release];
	[connectionsLock release];
#endif
    currentConnections = nil;
    connectionsLock = nil;
#if EGO_NO_ARC
	[super dealloc];
#endif
}

@end