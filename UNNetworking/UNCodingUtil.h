/*
 * Copyright (c) 2014 UP-NEXT. All rights reserved.
 * http://www.up-next.com
 *
 */

#import <Foundation/Foundation.h>

/**
 NSCoding utility class.
 */
@interface UNCodingUtil : NSObject

- (instancetype) initWithObject:(id <NSCoding>)obj;
- (NSSet *) readwriteProperties;
- (NSSet *) allProperties;
- (NSSet *) propertiesToEncode:(BOOL)onlyReadWriteProperties;
- (NSDictionary *) dictionaryRepresentation;
- (void) loadDictionaryRepresentation:(NSDictionary *)dictionary;

+ (void) encodeObject:(id <NSCoding>)object withCoder:(NSCoder *)encoder;
+ (void) decodeObject:(id <NSCoding>)object withCoder:(NSCoder *)decoder;
@end
