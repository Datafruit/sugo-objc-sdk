//
//  MPABTestDesignerDisconnectMessage.m
//  HelloSugo
//
//  Created by Alex Hofsteede on 29/7/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerDisconnectMessage.h"

NSString *const MPABTestDesignerDisconnectMessageType = @"disconnect";

@implementation MPABTestDesignerDisconnectMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerDisconnectMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        MPABTestDesignerConnection *conn = weak_connection;

        conn.sessionEnded = YES;
        [conn close];
    }];
    return operation;
}

@end
