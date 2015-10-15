/*
 * Copyright (c) 2014 UP-NEXT. All rights reserved.
 * http://www.up-next.com
 *
 */

#import <Foundation/Foundation.h>

typedef void (^UNURLConnectionCompletionBlock)(NSHTTPURLResponse *response, NSData *responseData, NSError *errorRequest);
typedef BOOL (^UNURLConnectionProgressBlock)(NSInteger bytesWritten, NSInteger totalBytesWritten, NSInteger totalBytesExpectedToWrite);

/** UNURLConnection */
@interface UNURLConnection : NSURLConnection

/** Disable SSL validation */
@property (assign) BOOL doNotValidateSSL;

- (instancetype) initWithRequest:(NSURLRequest *)request completion:(UNURLConnectionCompletionBlock)completion;
- (instancetype) initWithRequest:(NSURLRequest*)request completion:(UNURLConnectionCompletionBlock)completion uploadProgress:(UNURLConnectionProgressBlock)uploadProgress;
+ (instancetype) connectionWithRequest:(NSURLRequest *)request completion:(UNURLConnectionCompletionBlock)completion;
+ (instancetype) connectionWithRequest:(NSURLRequest*)request completion:(UNURLConnectionCompletionBlock)completion uploadProgress:(UNURLConnectionProgressBlock)uploadProgress;

+ (void) setVerbose:(BOOL)enable;
+ (BOOL) isVerbose;

+ (void) addPinnedCertificate:(NSData *)DERCertificate;
+ (NSArray *)pinnedCertificates;


@end
