//
//  MPNetwork.h
//  Sugo
//
//  Created by Sam Green on 6/12/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Sugo.h"

typedef NS_ENUM(NSUInteger, MPNetworkEndpoint) {
    MPNetworkEndpointTrack,
    MPNetworkEndpointDecide,
    MPNetworkEndpointHeat,
    MPNetworkEndpointFirstLogin
};

@interface MPNetwork : NSObject

@property (nonatomic) BOOL shouldManageNetworkActivityIndicator;
@property (nonatomic) BOOL useIPAddressForGeoLocation;

- (instancetype)initWithServerURL:(NSURL *)serverURL andEventCollectionURL:(NSURL *)eventCollectionURL;

- (void)flushEventQueue:(NSArray *)events;

- (void)updateNetworkActivityIndicator:(BOOL)enabled;

- (NSURLRequest *)buildGetRequestForURL:(NSURL *)url
                               andEndpoint:(MPNetworkEndpoint)endpoint
                            withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems;

- (NSURLRequest *)buildPostRequestForURL:(NSURL *)url
                             andEndpoint:(MPNetworkEndpoint)endpoint
                          withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems
                                 andBody:(NSString *)body;

+ (id)convertFoundationTypesToJSON:(id)obj;

@end
