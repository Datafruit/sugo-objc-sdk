//
//  Attributes.h
//  Sugo
//
//  Created by Zack on 9/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Attributes : NSObject

@property (nonatomic, strong) NSMutableDictionary *paths;

- (instancetype)initWithAttributes:(NSDictionary *)attributes;

- (NSDictionary *)parse;

@end
