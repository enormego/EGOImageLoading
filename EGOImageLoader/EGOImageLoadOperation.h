//
//  EGOImageLoadOperation.h
//  EGOImageLoading
//
//  Created by Shaun Harrison on 10/28/09.
//  Copyright 2009 enormego. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol EGOImageLoadOperationDelegate;
@interface EGOImageLoadOperation : NSOperation {
@private
	NSURL* imageURL;
	NSTimeInterval timeoutInterval;
	id<EGOImageLoadOperationDelegate> delegate;
}

- (id)initWithImageURL:(NSURL*)aURL;

@property(nonatomic,assign) id<EGOImageLoadOperationDelegate> delegate;
@property(nonatomic,assign) NSTimeInterval timeoutInterval;
@property(nonatomic,readonly) NSURL* imageURL;
@end

@protocol EGOImageLoadOperationDelegate<NSObject>
- (void)imageLoadOperation:(EGOImageLoadOperation*)operation didFinishWithData:(NSData*)imageData;
- (void)imageLoadOperationDidFail:(EGOImageLoadOperation*)operation;
@end