//
//  MPNetworkPrivate.h
//  Sugo
//
//  Created by Sam Green on 6/17/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "MPNetwork.h"

@interface MPNetwork ()

@property (nonatomic, strong) NSURL *serverURL;
@property (nonatomic, strong) NSURL *eventCollectionURL;

@property (nonatomic) NSTimeInterval requestsDisabledUntilTime;
@property (nonatomic) NSUInteger consecutiveFailures;

- (BOOL)handleNetworkResponse:(NSHTTPURLResponse *)response withError:(NSError *)error;

+ (NSTimeInterval)calculateBackOffTimeFromFailures:(NSUInteger)failureCount;
+ (NSTimeInterval)parseRetryAfterTime:(NSHTTPURLResponse *)response;
+ (BOOL)parseHTTPFailure:(NSHTTPURLResponse *)response withError:(NSError *)error;

+ (NSString *)encodeArrayForAPI:(NSArray *)array;
+ (NSData *)encodeArrayAsJSONData:(NSArray *)array;
+ (NSString *)encodeJSONDataAsBase64:(NSData *)data;

+ (NSString *)encodeArrayForBatch:(NSArray *)batch;
+ (NSString *)encodeBase64ForDataString:(NSString *)dataString;

+ (NSArray<NSURLQueryItem *> *)buildDecideQueryForProperties:(NSDictionary *)properties
                                              withDistinctID:(NSString *)distinctID
                                                andProjectID:(NSString *)projectID
                                                    andToken:(NSString *)token
                                      andEventBindingVersion:(NSNumber *)eventBindingVersion;

+ (NSArray<NSURLQueryItem *> *)buildHeatQueryForToken:(NSString *)token andSecretKey:(NSString *)secretKey;
    
+ (NSArray<NSURLQueryItem *> *)buildFirstLoginQueryForIdentifer:(NSString *)identifer andProjectID: (NSString *)projectID  andToken: (NSString *)token;

+ (NSArray<NSURLQueryItem *> *)buildFirsStartTimeQueryForAppId:(NSString *)appId
                                                    andAppType: (NSString *)appType
                                                   andDeviceId: (NSString *)deviceId
                                                 andAppVersion:(NSString *)appVersion;

- (NSURLRequest *)buildRequestForURL:(NSURL *)url
                         andEndpoint:(NSString *)endpoint
                        byHTTPMethod:(NSString *)method
                      withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems
                             andBody:(NSString *)body;

@end
