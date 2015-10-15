/*
 * Copyright (c) 2014 UP-NEXT. All rights reserved.
 * http://www.up-next.com
 *
 */

#import "UNURLConnection.h"
#import <objc/runtime.h>
#import <UIKit/UIKit.h>

@interface UNURLConnection () <NSURLConnectionDataDelegate>
@property (strong) NSMutableData* responseData;
@property (strong) NSHTTPURLResponse* response;
@property (copy) UNURLConnectionCompletionBlock completion;
@property (copy) UNURLConnectionProgressBlock sendProgressCallback;
@end

#ifdef DEBUG
static BOOL UNVerbose = YES;
#else
static BOOL UNVerbose = NO;
#endif

@implementation UNURLConnection

/**
 Creates and initializes an `UNURLConnection` object with the specified `NSURLRequest`.
 
 @param request request object
 @param completion finish called on finish.
 (NSData *responseData, NSError *errorRequest);
 */
- (instancetype)initWithRequest:(NSURLRequest*)request completion:(UNURLConnectionCompletionBlock)completion
{
    return [self initWithRequest:request completion:completion uploadProgress:nil];
}

- (instancetype)initWithRequest:(NSURLRequest*)request completion:(UNURLConnectionCompletionBlock)completion uploadProgress:(UNURLConnectionProgressBlock)uploadProgress
{
    if (self = [super initWithRequest:request delegate:self startImmediately:NO]) {
        _sendProgressCallback = uploadProgress;
        if (completion) {
            self.completion = completion;
        }
        [self scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

+ (instancetype)connectionWithRequest:(NSURLRequest*)request completion:(UNURLConnectionCompletionBlock)completion
{
    return [UNURLConnection connectionWithRequest:request completion:completion uploadProgress:nil];
}

+ (instancetype)connectionWithRequest:(NSURLRequest*)request completion:(UNURLConnectionCompletionBlock)completion uploadProgress:(UNURLConnectionProgressBlock)uploadProgress
{
    return [[UNURLConnection alloc] initWithRequest:request completion:completion uploadProgress:uploadProgress];
}

- (void)start
{
    [[self pool] addObject:self];

    if ([[self class] isVerbose]) {
        if (self.currentRequest.HTTPBody) {
            NSString* str = [[NSString alloc] initWithData:self.currentRequest.HTTPBody encoding:NSUTF8StringEncoding];
            NSLog(@"Request %@\n%@ (...)", self.currentRequest.URL, str ?: [self.currentRequest.HTTPBody subdataWithRange:(NSRange) { 0, MIN(50, self.currentRequest.HTTPBody.length) }]);
        } else {
            NSLog(@"Request %@", self.currentRequest.URL);
        }
    }

    [super start];
}

- (void)cancel
{
    [[self pool] removeObject:self];
    [super cancel];
    //[self unscheduleFromRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    [self updateNetworkActivity];
}

#pragma mark NSURLConnectionDataDelegate

- (void)connection:(NSURLConnection*)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
    // In debug mode you can disable SSL validation
    if (self.doNotValidateSSL) {
        NSURLProtectionSpace* protectionSpace = [challenge protectionSpace];
        NSURLCredential* credentail = [NSURLCredential credentialForTrust:[protectionSpace serverTrust]];
        if (challenge.previousFailureCount > 2) {
            [[challenge sender] continueWithoutCredentialForAuthenticationChallenge:challenge];
        } else {
            [[challenge sender] useCredential:credentail forAuthenticationChallenge:challenge];
        }
    } else if (([self.class pinnedCertificates].count > 0) && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        // SSL Pinning
        SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;

        CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
        NSMutableArray* trustChain = [NSMutableArray arrayWithCapacity:certificateCount];
        for (CFIndex i = 0; i < certificateCount; i++) {
            SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
            [trustChain addObject:(__bridge_transfer NSData*)SecCertificateCopyData(certificate)];
        }
        for (id serverCertificateData in trustChain) {
            if ([[self.class pinnedCertificates] containsObject:serverCertificateData]) {
                NSURLCredential* credential = [NSURLCredential credentialForTrust:serverTrust];
                [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
                return;
            }
        }

        [[challenge sender] cancelAuthenticationChallenge:challenge];
    } else {
        // Regular
        [[challenge sender] performDefaultHandlingForAuthenticationChallenge:challenge];
    }
}

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)response
{
    self.responseData = [[NSMutableData alloc] init];
    self.response = (NSHTTPURLResponse*)response;
}

- (void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data
{
    if (data) {
        [self.responseData appendData:data];
    }
}

- (NSCachedURLResponse*)connection:(NSURLConnection*)connection willCacheResponse:(NSCachedURLResponse*)cachedResponse
{
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection*)connection
{
    if ([UNURLConnection isVerbose])
        NSLog(@"Response %@: %@", @(self.response.statusCode), [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding]);

    if (self.completion) {
        self.completion(self.response, self.responseData, nil);
    }

    [[self pool] removeObject:self];
    [self updateNetworkActivity];
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{

    if ([UNURLConnection isVerbose])
        NSLog(@"Response %@: %@", @(self.response.statusCode), error);

    if (self.completion) {
        self.completion(self.response, nil, error);
    }

    [[self pool] removeObject:self];
    [self updateNetworkActivity];
}

- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    // NSLog(@"bytesWritten %@/totalBytesWritten %@, totalBytesExpectedToWrite %@", @(bytesWritten), @(totalBytesWritten), @(totalBytesExpectedToWrite));
    if (totalBytesExpectedToWrite > 0 && self.sendProgressCallback) {
        if (! self.sendProgressCallback(bytesWritten, totalBytesWritten, totalBytesExpectedToWrite)) {
            [connection cancel];
        }
    }
}

- (void)updateNetworkActivity
{
    if ([self pool].count == 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    } else if ([self pool].count > 0) {
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    }
}

// working connections pool
static NSMutableSet* connectionPool = nil;

- (NSMutableSet*)pool
{
    return connectionPool;
}

#pragma mark Class Methods

static NSLock* generalLock = nil;
static NSArray* pinnedCertificatesArray = nil;

+ (void)initialize
{
    connectionPool = [NSMutableSet setWithCapacity:1];
    generalLock = [[NSLock alloc] init];
    pinnedCertificatesArray = [[NSArray alloc] init];
}

/**
 Whitelisted certificates. SSL Pinning.
 
 Aside of defined certificates this implementation look for .cer files in bundle and
 use it as pinned certificate.
 
 @param DERCertificate NSData with whitelisted certificate (DER encoded certificates)
 */
+ (void)addPinnedCertificate:(NSData*)DERCertificate
{
    if (DERCertificate == nil) {
        return;
    }

    [generalLock lock];

    if (![pinnedCertificatesArray containsObject:DERCertificate]) {
        pinnedCertificatesArray = [pinnedCertificatesArray arrayByAddingObject:[DERCertificate copy]];
    }

    [generalLock unlock];
}

/** Whitelisted certificates, empty by default */
+ (NSArray*)pinnedCertificates
{
    return pinnedCertificatesArray;
}

+ (void)setVerbose:(BOOL)enable
{
    UNVerbose = enable;
}

+ (BOOL)isVerbose;
{
    return UNVerbose;
}

@end
