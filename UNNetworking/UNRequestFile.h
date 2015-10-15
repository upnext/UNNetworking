//
//  UNRequestFile.h
//  UNNetworking
//
//  Copyright (c) 2014 Upnext Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface UNRequestFile : NSObject

/**
 *  System path to file.
 */
@property (strong, nonatomic) NSString *path;
/**
 *  parameter key name, if not specified dictionary parameter key is used anyway
 */
@property (strong, nonatomic) NSString *key;
/**
 *  Mime type, if not specified then type is guessed
 */
@property (strong, nonatomic) NSString *mimeType;
/**
 *  File name, if not specified then file name is take from path.
 *  File name with extension part.
 */
@property (strong, nonatomic) NSString *fileName;

/**
 *  Init with path to file
 *
 *  @param path path to file
 *
 *  @return instance
 */
- (instancetype) initWithPath:(NSString *)path;

@end
