//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <UIKit/UIKit.h>
#import "MPAbstractABTestDesignerMessage.h"

@interface MPABTestDesignerSnapshotResponseMessage : MPAbstractABTestDesignerMessage

+ (instancetype)message;

@property (nonatomic, strong) UIImage *screenshot;
@property (nonatomic, copy) NSDictionary *serializedObjects;
@property (nonatomic, copy) NSData *compressedSerializedObjects;
@property (nonatomic, strong, readonly) NSString *imageHash;

@end
