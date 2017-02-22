//
//  SugoConfigurationPropertyList.h
//  Sugo
//
//  Created by Zack on 18/2/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SugoConfigurationPropertyList : NSObject

+ (NSDictionary *)loadWithName:(NSString *)name;
+ (NSDictionary *)loadWithName:(NSString *)name andKey:(NSString *)key;

@end
