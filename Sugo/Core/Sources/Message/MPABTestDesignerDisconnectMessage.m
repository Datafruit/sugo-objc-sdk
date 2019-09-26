//
//  MPABTestDesignerDisconnectMessage.m
//  HelloSugo
//
//  Created by Alex Hofsteede on 29/7/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerDisconnectMessage.h"
#import "ExceptionUtils.h"
NSString *const MPABTestDesignerDisconnectMessageType = @"disconnect";

@implementation MPABTestDesignerDisconnectMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerDisconnectMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    @try {
        __weak MPABTestDesignerConnection *weak_connection = connection;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            MPABTestDesignerConnection *conn = weak_connection;

            conn.sessionEnded = YES;
            [conn close];
        }];
        return operation;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

@end
