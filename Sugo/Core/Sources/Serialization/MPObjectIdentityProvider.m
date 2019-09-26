//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPObjectIdentityProvider.h"
#import "MPSequenceGenerator.h"
#import "ExceptionUtils.h"
@implementation MPObjectIdentityProvider

{
    NSMapTable *_objectToIdentifierMap;
    MPSequenceGenerator *_sequenceGenerator;
}

- (instancetype)init
{
    @try {
        self = [super init];
        if (self) {
            _objectToIdentifierMap = [NSMapTable weakToStrongObjectsMapTable];
            _sequenceGenerator = [[MPSequenceGenerator alloc] init];
        }
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
    }
    return self;
}

- (NSString *)identifierForObject:(id)object
{
    @try {
        if ([object isKindOfClass:[NSString class]]) {
            return object;
        }
        NSString *identifier = [_objectToIdentifierMap objectForKey:object];
        if (identifier == nil) {
            identifier = [NSString stringWithFormat:@"$%" PRIi32, [_sequenceGenerator nextValue]];
            [_objectToIdentifierMap setObject:identifier forKey:object];
        }
        return identifier;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return @"";
    }
    
}

@end
