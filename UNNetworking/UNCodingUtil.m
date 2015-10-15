/*
 * Copyright (c) 2014 UP-NEXT. All rights reserved.
 * http://www.up-next.com
 *
 */

#import "UNCodingUtil.h"
#import "UNCoding.h"
#import <objc/runtime.h>

@implementation UNCodingUtil {
    __weak id _object;
}

- (instancetype) initWithObject:(id <NSCoding>)obj
{
    if (self = [self init]) {
        _object = obj;
    }
    return self;
}

- (NSSet *) allProperties
{
    unsigned int count = 0;
    // Get a list of all properties in the class.
    __strong __typeof(_object)objectStrong = _object;
    objc_property_t *properties = class_copyPropertyList([objectStrong class], &count);
    
    NSMutableSet *props = [[NSMutableSet alloc] initWithCapacity:count];
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(properties[i])];
        //skip blocks, pointers and read-only attributes
        if (![attributes hasPrefix:@"T@?"] && ![attributes hasPrefix:@"T@^"]) {
            [props addObject:key];
        }
    }
    
    free(properties);
    return [props copy];
}

- (NSSet *) readwriteProperties
{
    unsigned int count = 0;
    // Get a list of all properties in the class.
    __strong __typeof(_object)objectStrong = _object;
    
    objc_property_t *properties = class_copyPropertyList([objectStrong class], &count);
    
    NSMutableSet *props = [[NSMutableSet alloc] initWithCapacity:count];
    
    for (int i = 0; i < count; i++) {
        NSString *key = [NSString stringWithUTF8String:property_getName(properties[i])];
        NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(properties[i])];
        
        //        BOOL isReadOnlyProperty = NO;
        //        char *readonly = property_copyAttributeValue(properties[i], "R");
        //        if (readonly) {
        //            isReadOnlyProperty = YES;
        //        }
        
        BOOL existsIVAR = YES;
        char *ivar_name = property_copyAttributeValue(properties[i], "V");
        if (!ivar_name) {
            existsIVAR = NO;
        }
        
        //        if (existsIVAR) {
        //            isReadOnlyProperty = NO;
        //        }
        
        //skip blocks, pointers and read-only attributes
        if (![attributes hasPrefix:@"T@?"] && ![attributes hasPrefix:@"T@^"] /*&& !isReadOnlyProperty */ && existsIVAR) {
            [props addObject:key];
        }
    }
    
    free(properties);
    return [props copy];
}

- (NSSet *)propertiesToEncode:(BOOL)onlyReadWriteProperties
{
    NSSet *properties = onlyReadWriteProperties ? [self readwriteProperties] : [self allProperties];
    
    if ([_object respondsToSelector:@selector(propertiesToExcludeFromEncoding)]) {
        NSArray *propertiesToExclude = [_object performSelector:@selector(propertiesToExcludeFromEncoding) withObject:nil];
        
        properties = [properties filteredSetUsingPredicate:[NSPredicate predicateWithBlock:^(id evaluatedObject, NSDictionary *bindings) {
            return (BOOL)![propertiesToExclude containsObject:evaluatedObject];
        }]];
    }
    
    return properties;
}

- (NSDictionary *)dictionaryRepresentation {
    NSSet *properties = [self propertiesToEncode:NO];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] initWithCapacity:properties.count];
    for (NSString *propertyName in properties) {
        id value = [_object valueForKey:propertyName];
        
        if (value) {
            if ([value respondsToSelector:@selector(dictionaryRepresentation)]) {
                [dictionary setObject:[value dictionaryRepresentation] forKey:propertyName];
            } else {
                [dictionary setObject:value forKey:propertyName];
            }
        }
    }
    return [dictionary copy];
}

- (void) loadDictionaryRepresentation:(NSDictionary *)dictionary;
{
    id objectStrong = _object;
    UNCodingUtil *coder = [[UNCodingUtil alloc] initWithObject:objectStrong];
    NSSet *properties = [coder propertiesToEncode:NO];
    for (NSString *propertyKey in properties) {
        BOOL doDefault = YES;
        if ([dictionary[propertyKey] isKindOfClass:[NSDictionary class]]) {
            // if property class responds to method loadDictionaryRepresentation: then use it
            unsigned int count = 0;
            objc_property_t *propList = class_copyPropertyList([objectStrong class], &count);
            for (int i = 0; i < count; i++) {
                NSString *propName = [NSString stringWithUTF8String:property_getName(propList[i])];
                if ([propName isEqualToString:propertyKey]) {
                    NSString *attributes = [NSString stringWithUTF8String:property_getAttributes(propList[i])];
                    // get class name
                    NSError *error = NULL;
                    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"T@\"(.*)\",.*$" options:NSRegularExpressionDotMatchesLineSeparators error:&error];
                    NSString *result = [regex stringByReplacingMatchesInString:attributes options:0 range:NSMakeRange(0, [attributes length]) withTemplate:@"$1"];
                    if (result) {
                        Class c = NSClassFromString(result);
                        if (class_getInstanceMethod(c, @selector(initWithDictionary:))) {
                            // create and initialie object with dictionary
                            id obj = [[c alloc] initWithDictionary:dictionary[propertyKey]];
                            [objectStrong setValue:obj forKey:propertyKey];
                            doDefault = NO;
                        }
                    }
                }
            }
            
            if (doDefault) {
                [objectStrong setValue:dictionary[propertyKey] forKey:propertyKey];
            }
        } else {
            [objectStrong setValue:dictionary[propertyKey] forKey:propertyKey];
        }
    }
}

+ (void) encodeObject:(id <NSCoding>)object withCoder:(NSCoder *)encoder
{
    UNCodingUtil *c = [[UNCodingUtil alloc] initWithObject:object];
    [c encodePropertiesWithCoder:encoder];
}

+ (void) decodeObject:(id <NSCoding>)object withCoder:(NSCoder *)decoder
{
    UNCodingUtil *c = [[UNCodingUtil alloc] initWithObject:object];
    [c decodePropertiesWithCoder:decoder];
}


#pragma mark - Private

- (void) encodePropertiesWithCoder:(NSCoder *)encoder
{
    NSSet *properties = [self propertiesToEncode:YES];
    for (NSString *propertyKey in properties) {
        [encoder encodeObject:[_object valueForKey:propertyKey] forKey:propertyKey];
    }
}

- (void) decodePropertiesWithCoder:(NSCoder *)decoder
{
    NSSet *properties = [self readwriteProperties];
    for (NSString *propertyKey in properties) {
        id value = [decoder decodeObjectForKey:propertyKey];
        if (value) {
            // find ivar
            [_object setValue:value forKey:propertyKey];
        }
    }
}

@end
