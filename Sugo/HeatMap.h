//
//  HeatMap.h
//  Sugo
//
//  Created by Zack on 27/4/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HeatMap : NSObject

@property BOOL mode;
@property (atomic, strong) NSData *data;
@property (atomic, strong) NSDictionary *coldColor;
@property (atomic, strong) NSDictionary *hotColor;

- (instancetype)initWithData:(NSData *)data;

- (void)switchMode:(BOOL)mode;

@end
