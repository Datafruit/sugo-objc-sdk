//
//  MPDesignerEventBindingRequestMesssage.m
//  HelloSugo
//
//  Created by Amanda Canyon on 7/15/14.
//  Copyright (c) 2014 Sugo. All rights reserved.
//

#import "Sugo.h"
#import "MPABTestDesignerConnection.h"
#import "MPDesignerEventBindingMessage.h"
#import "MPDesignerSessionCollection.h"
#import "MPEventBinding.h"
#import "MPObjectSelector.h"
#import "MPSwizzler.h"
#import "WebViewBindings.h"

NSString *const MPDesignerEventBindingRequestMessageType = @"event_binding_request";

@interface MPEventBindingCollection : NSObject<MPDesignerSessionCollection>

@property (nonatomic) NSMutableArray *bindings;

@end

@implementation MPEventBindingCollection

- (void)updateBindings:(NSArray *)bindingPayload
{
    NSMutableArray *newBindings = [NSMutableArray array];
    for (NSDictionary *bindingInfo in bindingPayload) {
        MPEventBinding *binding = [MPEventBinding bindingWithJSONObject:bindingInfo];
        if (binding) {
            [newBindings addObject:binding];
        }
    }

    for (MPEventBinding *oldBinding in self.bindings) {
        [oldBinding stop];
    }
    self.bindings = newBindings;
    for (MPEventBinding *newBinding in self.bindings) {
        [newBinding execute];
    }
}

- (void)cleanup
{
    for (MPEventBinding *oldBinding in self.bindings) {
        [oldBinding stop];
    }
    self.bindings = nil;
}

@end

@implementation MPDesignerEventBindingRequestMessage

+ (instancetype)message
{
    return [[self alloc] initWithType:@"event_binding_request"];
}

- (NSOperation *)responseCommandWithConnection:(MPABTestDesignerConnection *)connection
{
    __weak MPABTestDesignerConnection *weak_connection = connection;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        MPABTestDesignerConnection *conn = weak_connection;

        dispatch_sync(dispatch_get_main_queue(), ^{
            NSArray *commonEvents = [self payload][@"events"];
            NSLog(@"Loading event bindings:\n%@", commonEvents);
            MPEventBindingCollection *bindingCollection = [conn sessionObjectForKey:@"event_bindings"];
            if (!bindingCollection) {
                bindingCollection = [[MPEventBindingCollection alloc] init];
                [conn setSessionObject:bindingCollection forKey:@"event_bindings"];
            }
            [bindingCollection updateBindings:commonEvents];
            
            NSArray *htmlEvents = [self payload][@"h5_events"];
            if (htmlEvents) {
                [[WebViewBindings globalBindings].codelessBindings removeAllObjects];
                [[WebViewBindings globalBindings].codelessBindings addObjectsFromArray:htmlEvents];
                [WebViewBindings globalBindings].mode = Codeless;
                [[WebViewBindings globalBindings] fillBindings];
            }
        });

        MPDesignerEventBindingResponseMessage *changeResponseMessage = [MPDesignerEventBindingResponseMessage message];
        changeResponseMessage.status = @"OK";
        [conn sendMessage:changeResponseMessage];
    }];

    return operation;
}

@end
