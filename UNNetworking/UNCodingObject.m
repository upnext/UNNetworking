//
//  UNCoding.m
//  UNNetworking
//
//  Copyright (c) 2014 Upnext Ltd. All rights reserved.
//

#import "UNCodingObject.h"
#import "UNCodingUtil.h"

@implementation UNCodingObject

- (id)initWithCoder:(NSCoder *)decoder
{
    if(self = [self init]) {
        [UNCodingUtil decodeObject:self withCoder:decoder];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder
{
    [UNCodingUtil encodeObject:self withCoder:encoder];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [self init]) {
        [[[UNCodingUtil alloc] initWithObject:self] loadDictionaryRepresentation:dictionary];
    }
    return self;
}

- (NSDictionary *) dictionaryRepresentation
{
    return [[[UNCodingUtil alloc] initWithObject:self] dictionaryRepresentation];
}

@end
