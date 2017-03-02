//
//  MPDesignerTrackMessage.m
//  HelloSugo
//
//  Created by Amanda Canyon on 9/3/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import "MPDesignerEventBindingMessage.h"
#import "MPNetwork.h"
#import "MPLogger.h"

NSString *const MPDesignerEventBindingTrackMessageType = @"track_message";

@implementation MPDesignerTrackMessage

{
    NSDictionary *_payload;
}

+ (instancetype)message
{
    return [[self alloc] initWithType:@"track_message"];
}

+ (instancetype)messageWithPayload:(NSDictionary *)payload
{
    return[[self alloc] initWithType:@"track_message" andPayload:payload];
}

- (instancetype)initWithType:(NSString *)type
{
    return [self initWithType:type andPayload:@{}];
}

- (instancetype)initWithType:(NSString *)type andPayload:(NSDictionary *)payload
{
    if (self = [super initWithType:type]) {
        _payload = payload;
    }
    return self;
}

- (NSData *)JSONData
{
    NSDictionary *jsonObject = @{ @"type": self.type, @"payload": [_payload copy] };
    NSLog(@"jsonObject:\n%@", jsonObject);
    
    NSError *error = nil;
    NSData *jsonData = nil;
    @try {
        jsonData = [NSJSONSerialization dataWithJSONObject:[MPNetwork convertFoundationTypesToJSON:jsonObject]
                                                   options:(NSJSONWritingOptions)0
                                                     error:&error];
    }
    @catch (NSException *exception) {
        MPLogError(@"exception encoding api data: %@", exception);
    }
    
    if (error) {
        MPLogDebug(@"Failed to serialize test designer message: %@", error);
    }

    return jsonData;
}

@end
