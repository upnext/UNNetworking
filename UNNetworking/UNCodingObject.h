//
//  UNCoding.h
//  UNNetworking
//
//  Copyright (c) 2014 Upnext Ltd. All rights reserved.
//
//  This class provide helper base class that conforms to UNCoding protocol
//  If you can't inherit from UNCodingObject then simply copy & paste methods to you UNCoding compilant class

#import <Foundation/Foundation.h>
#import "UNCoding.h"

@interface UNCodingObject : NSObject <UNCoding>

- (id)initWithCoder:(NSCoder *)decoder;
- (void)encodeWithCoder:(NSCoder *)encoder;
- (instancetype) initWithDictionary:(NSDictionary *)dictionary;
- (NSDictionary *) dictionaryRepresentation;

@end
