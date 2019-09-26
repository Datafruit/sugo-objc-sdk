//
//  MPABTestDesignerClearRequestMessage.m
//  HelloSugo
//
//  Created by Alex Hofsteede on 3/7/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import "MPABTestDesignerClearRequestMessage.h"
#import "MPABTestDesignerClearResponseMessage.h"
#import "MPABTestDesignerConnection.h"
#import "ExceptionUtils.h"
NSString *const MPABTestDesignerClearRequestMessageType = @"clear_request";

@implementation MPABTestDesignerClearRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerClearRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    @try {
        __weak MPABTestDesignerConnection *weak_connection = connection;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            MPABTestDesignerConnection *conn = weak_connection;


            MPABTestDesignerClearResponseMessage *clearResponseMessage = [MPABTestDesignerClearResponseMessage message];
            clearResponseMessage.status = @"OK";
            [conn sendMessage:clearResponseMessage];
        }];
        return operation;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

@end
