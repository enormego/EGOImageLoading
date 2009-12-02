//
//  EGOImageLoadOperation.m
//  EGOImageLoading
//
//  Created by Shaun Harrison on 10/28/09.
//  Copyright 2009 enormego. All rights reserved.
//

#import "EGOImageLoadOperation.h"


@implementation EGOImageLoadOperation
@synthesize imageURL, delegate, timeoutInterval;

- (id)initWithImageURL:(NSURL*)aURL {
	if((self = [super init])) {
		imageURL = [aURL retain];
	}
	   
	return self;
}

- (void)main {
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	[delegate retain];
	
	NSURLRequest* request = [[NSURLRequest alloc] initWithURL:self.imageURL cachePolicy:NSURLRequestReturnCacheDataElseLoad timeoutInterval:self.timeoutInterval];
	NSData* imageData = [NSURLConnection sendSynchronousRequest:request returningResponse:NULL error:NULL];
	[request release];
	
	
	if(![self isCancelled] && imageData.length > 0) {
		[delegate imageLoadOperation:self didFinishWithData:imageData];
	} else {
		[delegate imageLoadOperationDidFail:self];
	}
	
	[delegate release];
	delegate = nil;
	[pool release];
}

- (void)setQueuePriority:(NSOperationQueuePriority)p {
	if(![self isFinished] && ![self isCancelled] && ![self isExecuting]) {
		[super setQueuePriority:p];	
	}
}

- (void)dealloc {
	[imageURL release];
	[super dealloc];
}

@end
