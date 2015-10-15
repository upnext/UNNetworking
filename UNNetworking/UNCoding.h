//
//  UNCodingProtocol.h
//  UNNetworking
//
//  Copyright (c) 2014 Upnext Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Coding protocol allows serialize object to/from dictionary.
 */
@protocol UNCoding <NSCoding>

@required

/** @name Object serialization and deserialization */
/**
 Initialize object with dictionary.
 @param dictionary Dictionary received from <dictionaryRepresentation>
 */
- (instancetype) initWithDictionary:(NSDictionary *)dictionary;
/**
 Returns dictionary represenation for object instance.
 
 @returns Dictionary to be used with <initWithDictionary:>
 */
- (NSDictionary *) dictionaryRepresentation;

@optional

- (NSArray *)propertiesToExcludeFromEncoding;

@end
