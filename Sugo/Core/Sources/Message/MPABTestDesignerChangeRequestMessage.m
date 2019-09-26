//
// Copyright (c) 2014 Sugo. All rights reserved.

#import "MPABTestDesignerChangeRequestMessage.h"
#import "MPABTestDesignerChangeResponseMessage.h"
#import "MPABTestDesignerConnection.h"
#import "MPABTestDesignerSnapshotResponseMessage.h"
#import "ExceptionUtils.h"

NSString *const MPABTestDesignerChangeRequestMessageType = @"change_request";

@implementation MPABTestDesignerChangeRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:MPABTestDesignerChangeRequestMessageType];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    @try {
        __weak MPABTestDesignerConnection *weak_connection = connection;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            MPABTestDesignerConnection *conn = weak_connection;

            MPABTestDesignerChangeResponseMessage *changeResponseMessage = [MPABTestDesignerChangeResponseMessage message];
            changeResponseMessage.status = @"OK";
            [conn sendMessage:changeResponseMessage];
        }];

        return operation;
    } @catch (NSException *exception) {
        [ExceptionUtils exceptionToNetWork:exception];
        return nil;
    }
}

@end
