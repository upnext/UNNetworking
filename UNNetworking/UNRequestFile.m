//
//  UNRequestFile.m
//  UNNetworking
//
//  Copyright (c) 2014 Upnext Ltd. All rights reserved.
//

#import "UNRequestFile.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation UNRequestFile

- (instancetype) initWithPath:(NSString *)path
{
    if (self = [self init]) {
        self.path = [path stringByExpandingTildeInPath];
    }
    return self;
}

- (NSString *)fileName
{
    if (!_fileName) {
        if (self.path) {
            return [self.path lastPathComponent];
        }
    }

    return _fileName;
}

- (NSString *)mimeType
{
    if (!_mimeType) {
        CFStringRef pathExtension = (__bridge_retained CFStringRef)[self.path pathExtension];
        CFStringRef type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, pathExtension, NULL);
        CFRelease(pathExtension);

        NSString *mimeType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType);
        if (type != NULL)
            CFRelease(type);

        return mimeType;
    }
    return _mimeType;
}

@end
