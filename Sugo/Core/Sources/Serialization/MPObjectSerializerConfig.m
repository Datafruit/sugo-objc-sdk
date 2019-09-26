//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPClassDescription.h"
#import "MPEnumDescription.h"
#import "MPObjectSerializerConfig.h"
#import "MPTypeDescription.h"
#import "ExceptionUtils.h"

@implementation MPObjectSerializerConfig

{
    NSDictionary *_classes;
    NSDictionary *_enums;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    @try {
        self = [super init];
        if (self) {
            NSMutableDictionary *classDescriptions = [NSMutableDictionary dictionary];
            for (NSDictionary *d in dictionary[@"classes"]) {
                NSString *superclassName = d[@"superclass"];
                MPClassDescription *superclassDescription = superclassName ? classDescriptions[superclassName] : nil;
                MPClassDescription *classDescription = [[MPClassDescription alloc] initWithSuperclassDescription:superclassDescription
                                                                                                      dictionary:d];

                classDescriptions[classDescription.name] = classDescription;
            }

            NSMutableDictionary *enumDescriptions = [NSMutableDictionary dictionary];
            for (NSDictionary *d in dictionary[@"enums"]) {
                MPEnumDescription *enumDescription = [[MPEnumDescription alloc] initWithDictionary:d];
                enumDescriptions[enumDescription.name] = enumDescription;
            }

            _classes = [classDescriptions copy];
            _enums = [enumDescriptions copy];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return self;
}

- (NSArray *)classDescriptions
{
    return _classes.allValues;
}

- (MPEnumDescription *)enumWithName:(NSString *)name
{
    return _enums[name];
}

- (MPClassDescription *)classWithName:(NSString *)name
{
    return _classes[name];
}

- (MPTypeDescription *)typeWithName:(NSString *)name
{
    @try {
        MPEnumDescription *enumDescription = [self enumWithName:name];
        if (enumDescription) {
            return enumDescription;
        }

        MPClassDescription *classDescription = [self classWithName:name];
        if (classDescription) {
            return classDescription;
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return nil;
}

@end
