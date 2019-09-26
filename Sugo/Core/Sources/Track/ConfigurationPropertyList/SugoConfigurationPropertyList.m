//
//  SugoConfigurationPropertyList.m
//  Sugo
//
//  Created by Zack on 18/2/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "SugoConfigurationPropertyList.h"
#import "Sugo.h"
#import "ExceptionUtils.h"

@implementation SugoConfigurationPropertyList

+ (NSDictionary *)loadWithName:(NSString *)name
{
    @try {
        NSMutableDictionary *configuration = [[NSMutableDictionary alloc] init];
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        NSString *path = [bundle pathForResource:name ofType:@"plist"];
        if (path) {
            configuration = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        }
        return [NSDictionary dictionaryWithDictionary:configuration];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSDictionary alloc]init];
    }
}

+ (NSDictionary *)loadWithName:(NSString *)name andKey:(NSString *)key
{
    @try {
        NSMutableDictionary *configuration = [[NSMutableDictionary alloc] init];
        if ([SugoConfigurationPropertyList loadWithName:name][key]) {
            configuration = [SugoConfigurationPropertyList loadWithName:name][key];
        }
        return [NSDictionary dictionaryWithDictionary:configuration];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSDictionary alloc]init];
    }
}

@end
