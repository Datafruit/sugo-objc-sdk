//
//  SugoConfigurationPropertyList.m
//  Sugo
//
//  Created by Zack on 18/2/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "SugoConfigurationPropertyList.h"
#import "Sugo.h"

@implementation SugoConfigurationPropertyList

+ (NSDictionary *)loadWithName:(NSString *)name
{
    NSMutableDictionary *configuration = [[NSMutableDictionary alloc] init];
    NSBundle *bundle = [NSBundle bundleForClass:[Sugo class]];
    NSString *path = [bundle pathForResource:name ofType:@"plist"];
    if (path) {
        configuration = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    }
    NSLog(@"%@ Property List: %@", name, configuration);
    return [NSDictionary dictionaryWithDictionary:configuration];
}

+ (NSDictionary *)loadWithName:(NSString *)name andKey:(NSString *)key
{
    NSMutableDictionary *configuration = [[NSMutableDictionary alloc] init];
    if ([SugoConfigurationPropertyList loadWithName:name][key]) {
        configuration = [SugoConfigurationPropertyList loadWithName:name][key];
    }
    return [NSDictionary dictionaryWithDictionary:configuration];
}

+ (void)adjustWithName:(NSString *)name andKey:(NSString *)key andValue:(id)value
{
    NSBundle *bundle = [NSBundle bundleForClass:[Sugo class]];
    NSString *path = [bundle pathForResource:name ofType:@"plist"];
    NSMutableDictionary *plist = [[NSMutableDictionary alloc] initWithDictionary:[SugoConfigurationPropertyList loadWithName:name]];
    
    plist[key] = value;
    [plist writeToFile:path atomically:YES];
    
    NSLog(@"Adjust %@ Property List: key = %@, value = %@", name, key, value);
}

@end
