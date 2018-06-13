//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <Foundation/Foundation.h>

@interface MPTypeDescription : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary;

@property (nonatomic, readonly) NSString *name;

@end
