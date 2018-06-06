//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <Foundation/Foundation.h>
#import "MPAbstractABTestDesignerMessage.h"

@class MPObjectSerializerConfig;

extern NSString *const MPABTestDesignerSnapshotRequestMessageType;

@interface MPABTestDesignerSnapshotRequestMessage : MPAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, readonly) MPObjectSerializerConfig *configuration;

@end
