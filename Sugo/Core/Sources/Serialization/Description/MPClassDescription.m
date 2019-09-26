//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPClassDescription.h"
#import "MPPropertyDescription.h"
#import "ExceptionUtils.h"

@implementation MPDelegateInfo

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _selectorName = dictionary[@"selector"];
    }
    return self;
}

@end

@implementation MPClassDescription

{
    NSArray *_propertyDescriptions;
    NSArray *_delegateInfos;
}

- (instancetype)initWithSuperclassDescription:(MPClassDescription *)superclassDescription dictionary:(NSDictionary *)dictionary
{
    
    self = [super initWithDictionary:dictionary];
    @try {
        if (self) {
            _superclassDescription = superclassDescription;

            NSMutableArray *propertyDescriptions = [NSMutableArray array];
            for (NSDictionary *propertyDictionary in dictionary[@"properties"]) {
                [propertyDescriptions addObject:[[MPPropertyDescription alloc] initWithDictionary:propertyDictionary]];
            }

            _propertyDescriptions = [propertyDescriptions copy];

            NSMutableArray *delegateInfos = [NSMutableArray array];
            for (NSDictionary *delegateInfoDictionary in dictionary[@"delegateImplements"]) {
                [delegateInfos addObject:[[MPDelegateInfo alloc] initWithDictionary:delegateInfoDictionary]];
            }
            _delegateInfos = [delegateInfos copy];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }

    return self;
}

- (NSArray *)propertyDescriptions
{
    @try {
        NSMutableDictionary *allPropertyDescriptions = [NSMutableDictionary dictionary];

        MPClassDescription *description = self;
        while (description)
        {
            for (MPPropertyDescription *propertyDescription in description->_propertyDescriptions) {
                if (!allPropertyDescriptions[propertyDescription.name]) {
                    allPropertyDescriptions[propertyDescription.name] = propertyDescription;
                }
            }
            description = description.superclassDescription;
        }

        return allPropertyDescriptions.allValues;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return [[NSArray alloc]init];
    }
}

- (BOOL)isDescriptionForKindOfClass:(Class)aClass
{
    return [self.name isEqualToString:NSStringFromClass(aClass)] && [self.superclassDescription isDescriptionForKindOfClass:[aClass superclass]];
}

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@:%p name='%@' superclass='%@'>", NSStringFromClass([self class]), (__bridge void *)self, self.name, self.superclassDescription ? self.superclassDescription.name : @""];
}

@end
