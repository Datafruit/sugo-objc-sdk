//
//  MPEventBinding.m
//  HelloSugo
//
//  Created by Amanda Canyon on 7/22/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import "Sugo.h"
#import "MPEventBinding.h"
#import "MPUIControlBinding.h"
#import "MPUITableViewBinding.h"
#import "MPLogger.h"

@implementation MPEventBinding

+ (MPEventBinding *)bindingWithJSONObject:(NSDictionary *)object
{
    if (object == nil) {
        MPLogDebug(@"must supply an JSON object to initialize from");
        return nil;
    }

    NSString *bindingType = object[@"event_type"];
    Class klass = [self subclassFromString:bindingType];
    return [klass bindingWithJSONObject:object];
}

+ (MPEventBinding *)bindngWithJSONObject:(NSDictionary *)object
{
    return [self bindingWithJSONObject:object];
}

+ (Class)subclassFromString:(NSString *)bindingType
{
    NSDictionary *classTypeMap = @{
                                   [MPUIControlBinding typeName]: [MPUIControlBinding class],
                                   [MPUITableViewBinding typeName]: [MPUITableViewBinding class]
                                   };
    return[classTypeMap valueForKey:bindingType] ?: [MPUIControlBinding class];
}

+ (void)track:(NSString *)eventID eventName:(NSString *)eventName properties:(NSDictionary *)properties
{
    NSMutableDictionary *bindingProperties = [NSMutableDictionary dictionaryWithObjectsAndKeys: @YES, @"from_binding", nil];
    [bindingProperties addEntriesFromDictionary:properties];
    [[Sugo sharedInstance] trackEventID:eventID eventName:eventName properties:bindingProperties];
}

- (instancetype)initWithEventID:(NSString *)eventID
                      eventName:(NSString *)eventName
                         onPath:(NSString *)path
                 withAttributes:(Attributes *)attributes
{
    if (self = [super init]) {
        self.eventID = eventID;
        self.eventName = eventName;
        self.path = [[MPObjectSelector alloc] initWithString:path];
        self.attributes = attributes;
        self.name = [[NSUUID UUID] UUIDString];
        self.running = NO;
    }
    return self;
}


- (NSString *)description
{
    return [NSString stringWithFormat:@"Event Binding base class: '%@' for '%@'", [self eventName], [self path]];
}

#pragma mark -- Method stubs

+ (NSString *)typeName
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)execute
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

- (void)stop
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                                 userInfo:nil];
}

#pragma mark -- NSCoder

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    NSString *path = [aDecoder decodeObjectForKey:@"path"];
    NSString *eventID = [aDecoder decodeObjectForKey:@"eventID"];
    NSString *eventName = [aDecoder decodeObjectForKey:@"eventName"];
    NSDictionary *attributesPaths = [aDecoder decodeObjectForKey:@"attributes"];
    if (self = [self initWithEventID:eventID eventName:eventName onPath:path withAttributes:[[Attributes alloc] initWithAttributes:attributesPaths]]) {
        self.ID = [[aDecoder decodeObjectForKey:@"ID"] unsignedLongValue];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.swizzleClass = NSClassFromString([aDecoder decodeObjectForKey:@"swizzleClass"]);
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:@(_ID) forKey:@"ID"];
    [aCoder encodeObject:_name forKey:@"name"];
    [aCoder encodeObject:_path.string forKey:@"path"];
    [aCoder encodeObject:_eventID forKey:@"eventID"];
    [aCoder encodeObject:_eventName forKey:@"eventName"];
    [aCoder encodeObject:NSStringFromClass(_swizzleClass) forKey:@"swizzleClass"];
    [aCoder encodeObject:_attributes.paths forKey:@"attributes"];
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    } else if (![other isKindOfClass:[MPEventBinding class]]) {
        return NO;
    } else {
        return [self.eventName isEqual:((MPEventBinding *)other).eventName] && [self.path isEqual:((MPEventBinding *)other).path];
    }
}

- (NSUInteger)hash {
    return [self.eventName hash] ^ [self.path hash];
}

@end
