//
//  EGOImageLoadConnection.h
//  EGOImageLoading
//
//  Created by Shaun Harrison on 12/1/09.
//  Copyright 2009 enormego. All rights reserved.
//
//  This work is licensed under the Creative Commons GNU General Public License License.
//  To view a copy of this license, visit http://creativecommons.org/licenses/GPL/2.0/
//  or send a letter to Creative Commons, 171 Second Street, Suite 300, San Francisco, California, 94105, USA.
//

#import <Foundation/Foundation.h>

@protocol EGOImageLoadConnectionDelegate;

@interface EGOImageLoadConnection : NSObject {
@private
	NSURL* _imageURL;
	NSURLResponse* _response;
	NSMutableData* _responseData;
	NSURLConnection* _connection;
	NSTimeInterval _timeoutInterval;
	
	id<EGOImageLoadConnectionDelegate> _delegate;
}

- (id)initWithImageURL:(NSURL*)aURL delegate:(id)delegate;

- (void)start;
- (void)cancel;

@property(nonatomic,readonly) NSData* responseData;
@property(nonatomic,readonly,getter=imageURL) NSURL* imageURL;

@property(nonatomic,retain) NSURLResponse* response;
@property(nonatomic,assign) id<EGOImageLoadConnectionDelegate> delegate;

@property(nonatomic,assign) NSTimeInterval timeoutInterval; // Default is 30 seconds

@end

@protocol EGOImageLoadConnectionDelegate<NSObject>
- (void)connectionDidFinishLoading:(EGOImageLoadConnection *)connection;
- (void)connection:(EGOImageLoadConnection *)connection didFailWithError:(NSError *)error;	
@end