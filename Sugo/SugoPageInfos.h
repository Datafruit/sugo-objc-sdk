//
//  SugoPageInfos.h
//  Sugo
//
//  Created by Zack on 3/2/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SugoPageInfos : NSObject

+ (instancetype)global;

@property (atomic, strong) NSMutableArray* infos;

@end
