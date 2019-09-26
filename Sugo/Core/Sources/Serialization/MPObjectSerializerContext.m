//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPObjectSerializerContext.h"
#import "ExceptionUtils.h"
@implementation MPObjectSerializerContext

{
    NSMutableSet *_visitedObjects;
    NSMutableSet *_unvisitedObjects;
    NSMutableDictionary *_serializedObjects;
}

- (instancetype)initWithRootObject:(id)object
{
    @try {
        self = [super init];
        if (self) {
            _visitedObjects = [NSMutableSet set];
            _unvisitedObjects = [NSMutableSet setWithObject:object];
            _serializedObjects = [NSMutableDictionary dictionary];
        }

        return self;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

- (BOOL)hasUnvisitedObjects
{
    return _unvisitedObjects.count > 0;
}

- (void)enqueueUnvisitedObject:(NSObject *)object
{
    @try {
        NSParameterAssert(object != nil);

        [_unvisitedObjects addObject:object];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

- (NSObject *)dequeueUnvisitedObject
{
    @try {
        NSObject *object = [_unvisitedObjects anyObject];
        [_unvisitedObjects removeObject:object];
        return object;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

- (void)addVisitedObject:(NSObject *)object
{
    @try {
        NSParameterAssert(object != nil);

        [_visitedObjects addObject:object];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

- (BOOL)isVisitedObject:(NSObject *)object
{
    @try {
        return object && [_visitedObjects containsObject:object];
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return NO;
    }
    
}

- (void)addSerializedObject:(NSDictionary *)serializedObject
{
    @try {
        NSParameterAssert(serializedObject[@"id"] != nil);
        _serializedObjects[serializedObject[@"id"]] = serializedObject;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
}

- (NSArray *)allSerializedObjects
{
    return _serializedObjects.allValues;
}

@end
