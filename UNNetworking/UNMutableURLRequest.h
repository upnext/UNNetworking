/*
 * Copyright (c) 2014 UP-NEXT. All rights reserved.
 * http://www.up-next.com
 *
 */

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, UNParametersContentType) {
    CCPParametersContentTypeURLEncoded = 0,
    CCPParametersContentTypeMultipart
};

/** Convienience class for service requests */
@interface UNMutableURLRequest : NSMutableURLRequest

@property (strong) NSDictionary *userInfo;

- (instancetype)initWithURL:(NSURL *)theURL cachePolicy:(NSURLRequestCachePolicy)cachePolicy timeoutInterval:(NSTimeInterval)timeoutInterval parameters:(NSDictionary *)parameters method:(NSString *)method parametersContentType:(UNParametersContentType)parametersContentType;
- (instancetype)initWithGetURL:(NSURL *)theURL parameters:(NSDictionary *)parameters;
- (instancetype)initWithPostURL:(NSURL *)theURL parameters:(NSDictionary *)parameters;
- (instancetype)initWithPutURL:(NSURL *)theURL parameters:(NSDictionary *)parameters;
- (instancetype)initWithDeleteURL:(NSURL *)theURL parameters:(NSDictionary *)parameters;

- (NSURL *) appendQueryParameters:(NSDictionary *)parameters;

// helpers
+ (NSString *)percentEscapedQueryString:(NSString *)string;
@end
