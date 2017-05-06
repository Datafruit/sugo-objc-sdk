//
//  MPNetwork.m
//  Sugo
//
//  Created by Sam Green on 6/12/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "MPNetwork.h"
#import "MPNetworkPrivate.h"
#import "MPLogger.h"
#import "Sugo.h"
#import <UIKit/UIKit.h>

#define SUGO_NO_NETWORK_ACTIVITY_INDICATOR (defined(SUGO_APP_EXTENSION))

static const NSUInteger kBatchSize = 50;

@implementation MPNetwork

- (instancetype)initWithServerURL:(NSURL *)serverURL andEventCollectionURL:(NSURL *)eventCollectionURL{
    self = [super init];
    if (self) {
        self.serverURL = serverURL;
        self.eventCollectionURL = eventCollectionURL;
        self.shouldManageNetworkActivityIndicator = YES;
        self.useIPAddressForGeoLocation = YES;
    }
    return self;
}

#pragma mark - Flush
- (void)flushEventQueue:(NSMutableArray *)events {
    
    NSURLQueryItem *queryItem = [[NSURLQueryItem alloc] initWithName:@"locate"
                                                               value:[Sugo sharedInstance].projectID];
    NSArray *queryItems = @[queryItem];
    [self flushQueue:events
               toURL:self.eventCollectionURL
         andEndpoint:MPNetworkEndpointTrack
      withQueryItems:queryItems];
}

- (void)flushQueue:(NSMutableArray *)queue
             toURL:(NSURL *)url
       andEndpoint:(MPNetworkEndpoint)endpoint
    withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems {
    if ([[NSDate date] timeIntervalSince1970] < self.requestsDisabledUntilTime) {
        MPLogDebug(@"Attempted to flush to %lu, when we still have a timeout. Ignoring flush.", endpoint);
        return;
    }
    
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"SugoDimensions"]) {
        return;
    }
    
    while (queue.count > 0) {
        NSUInteger batchSize = MIN(queue.count, kBatchSize);
        NSArray *batch = [queue subarrayWithRange:NSMakeRange(0, batchSize)];
        
        NSString *requestData = [MPNetwork encodeArrayForBatch: batch];//[MPNetwork encodeArrayForAPI:batch];
        NSString *postBody = [NSString stringWithFormat:@"%@", requestData];
        MPLogDebug(@"%@ flushing %lu of %lu to %lu: %@", self, (unsigned long)batch.count, (unsigned long)queue.count, endpoint, queue);
        NSURLRequest *request = [self buildPostRequestForURL:url
                                                 andEndpoint:endpoint
                                              withQueryItems:queryItems
                                                     andBody:postBody];
        [self updateNetworkActivityIndicator:YES];
        
        __block BOOL didFail = NO;
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                  NSURLResponse *urlResponse,
                                                                  NSError *error) {
            [self updateNetworkActivityIndicator:NO];
            
            BOOL success = [self handleNetworkResponse:(NSHTTPURLResponse *)urlResponse withError:error];
            if (error || !success) {
                MPLogError(@"%@ network failure: %@", self, error);
                didFail = YES;
            } else {
                NSString *response = [[NSString alloc] initWithData:responseData
                                                           encoding:NSUTF8StringEncoding];
                if ([response intValue] == 0) {
                    MPLogDebug(@"%@ %lu response value %d", self, endpoint, [response intValue]);
                }
            }
            
            dispatch_semaphore_signal(semaphore);
        }] resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (didFail) {
            break;
        }
        
        [queue removeObjectsInArray:batch];
    }
}

- (BOOL)handleNetworkResponse:(NSHTTPURLResponse *)response withError:(NSError *)error {
    MPLogDebug(@"HTTP Response: %@", response.allHeaderFields);
    MPLogDebug(@"HTTP Error: %@", error.localizedDescription);
    
    BOOL failed = [MPNetwork parseHTTPFailure:response withError:error];
    if (failed) {
        MPLogDebug(@"Consecutive network failures: %lu", self.consecutiveFailures);
        self.consecutiveFailures++;
    } else {
        MPLogDebug(@"Consecutive network failures reset to 0");
        self.consecutiveFailures = 0;
    }
    
    // Did the server response with an HTTP `Retry-After` header?
    NSTimeInterval retryTime = [MPNetwork parseRetryAfterTime:response];
    if (self.consecutiveFailures >= 2) {
        
        // Take the larger of exponential back off and server provided `Retry-After`
        retryTime = MAX(retryTime, [MPNetwork calculateBackOffTimeFromFailures:self.consecutiveFailures]);
    }
    
    NSDate *retryDate = [NSDate dateWithTimeIntervalSinceNow:retryTime];
    self.requestsDisabledUntilTime = [retryDate timeIntervalSince1970];
    
    MPLogDebug(@"Retry backoff time: %.2f - %@", retryTime, retryDate);
    
    return !failed;
}

#pragma mark - Helpers
+ (NSArray<NSURLQueryItem *> *)buildDecideQueryForProperties:(NSDictionary *)properties
                                              withDistinctID:(NSString *)distinctID
                                                andProjectID:(NSString *)projectID
                                                    andToken:(NSString *)token
                                      andEventBindingVersion:(NSNumber *)eventBindingVersion {
    NSURLQueryItem *itemVersion = [NSURLQueryItem queryItemWithName:@"app_version"
                                                              value:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]];
    NSURLQueryItem *itemLib = [NSURLQueryItem queryItemWithName:@"lib" value:@"iphone"];
    NSURLQueryItem *itemProjectID = [NSURLQueryItem queryItemWithName:@"projectId" value:projectID];
    NSURLQueryItem *itemToken = [NSURLQueryItem queryItemWithName:@"token" value:token];
    NSURLQueryItem *itemDistinctID = [NSURLQueryItem queryItemWithName:@"distinct_id" value:distinctID];
    NSURLQueryItem *itemEventBindingsVersion = [NSURLQueryItem queryItemWithName:@"event_bindings_version" value:[eventBindingVersion stringValue]];
    
    // Convert properties dictionary to a string
    NSData *propertiesData = [NSJSONSerialization dataWithJSONObject:properties
                                                             options:0
                                                               error:NULL];
    NSString *propertiesString = [[NSString alloc] initWithData:propertiesData
                                                       encoding:NSUTF8StringEncoding];
    NSURLQueryItem *itemProperties = [NSURLQueryItem queryItemWithName:@"properties" value:propertiesString];
    
    return @[itemVersion,
             itemLib,
             itemProjectID,
             itemToken,
             itemDistinctID,
             itemEventBindingsVersion,
             itemProperties];
}

+ (NSString *)pathForEndpoint:(MPNetworkEndpoint)endpoint {
    static NSDictionary *endPointToPath = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        endPointToPath = @{ @(MPNetworkEndpointTrack): @"/post",
                            @(MPNetworkEndpointDecide): @"/api/sdk/decide" };
    });
    NSNumber *key = @(endpoint);
    return endPointToPath[key];
}

- (NSURLRequest *)buildGetRequestForURL:(NSURL *)url
                               andEndpoint:(MPNetworkEndpoint)endpoint
                              withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems {
    return [self buildRequestForURL:(NSURL *)url
                        andEndpoint:[MPNetwork pathForEndpoint:endpoint]
                            byHTTPMethod:@"GET"
                          withQueryItems:queryItems
                                 andBody:nil];
}

- (NSURLRequest *)buildPostRequestForURL:(NSURL *)url
                             andEndpoint:(MPNetworkEndpoint)endpoint
                          withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems
                                 andBody:(NSString *)body {
    return [self buildRequestForURL:(NSURL *)url
                        andEndpoint:[MPNetwork pathForEndpoint:endpoint]
                       byHTTPMethod:@"POST"
                     withQueryItems:queryItems
                            andBody:body];
}

- (NSURLRequest *)buildRequestForURL:(NSURL *)url
                         andEndpoint:(NSString *)endpoint
                        byHTTPMethod:(NSString *)method
                      withQueryItems:(NSArray <NSURLQueryItem *> *)queryItems
                             andBody:(NSString *)body {
    // Build URL from path and query items
    NSURL *urlWithEndpoint = [url URLByAppendingPathComponent:endpoint];
    NSURLComponents *components = [NSURLComponents componentsWithURL:urlWithEndpoint
                                             resolvingAgainstBaseURL:YES];
    components.queryItems = queryItems;

    // Build request from URL
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:components.URL];
    [request setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
    [request setHTTPMethod:method];
    [request setHTTPBody:[body dataUsingEncoding:NSUTF8StringEncoding]];
    
    MPLogDebug(@"build request: %@", [request URL].absoluteString);
    MPLogDebug(@"%@ http request: %@?%@", self, request, body);
    
    return [request copy];
}

+ (NSString *)encodeArrayForAPI:(NSArray *)array {
    NSData *data = [MPNetwork encodeArrayAsJSONData:array];
    return [MPNetwork encodeJSONDataAsBase64:data];
}

+ (NSData *)encodeArrayAsJSONData:(NSArray *)array {
    NSError *error = NULL;
    NSData *data = nil;
    @try {
        data = [NSJSONSerialization dataWithJSONObject:[self convertFoundationTypesToJSON:array]
                                               options:(NSJSONWritingOptions)0
                                                 error:&error];
    }
    @catch (NSException *exception) {
        MPLogError(@"exception encoding api data: %@", exception);
    }
    
    if (error) {
        MPLogError(@"error encoding api data: %@", error);
    }
    
    return data;
}

+ (NSString *)encodeJSONDataAsBase64:(NSData *)data {
    return [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
}

// Encode data for Sugo special need
+ (NSString *)encodeArrayForBatch:(NSArray *)batch
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSArray *dimensions = [userDefaults objectForKey:@"SugoDimensions"];
    
    NSMutableDictionary *types = [[NSMutableDictionary alloc] init];
    NSMutableArray *localKeys = [[NSMutableArray alloc] init];
    NSMutableArray *keys = [[NSMutableArray alloc] init];
    NSMutableArray *values = [[NSMutableArray alloc] init];
    NSMutableString *dataString = [[NSMutableString alloc] init];
    
    NSString *TypeSeperator = @"|";
    NSString *KeysSeperator = @",";
    NSString *ValuesSeperator = [NSString stringWithFormat:@"%c", 1];
    NSString *LinesSeperator = [NSString stringWithFormat:@"%c", 2];

    for (NSDictionary *object in batch) {
        if (![object isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        for (NSString *key in object.allKeys.reverseObjectEnumerator) {
            if (![localKeys containsObject:key]) {
                [localKeys addObject:key];
            }
        }
    }
    
    for (NSDictionary *dimension in dimensions) {
        NSString *dimensionKey = dimension[@"name"];
        for (NSString *key in localKeys) {
            if ([dimensionKey isEqualToString:key]) {
                [keys addObject:key];
            }
        }
    }
    
    for (NSDictionary *dimension in dimensions) {
        NSString *dimensionKey = dimension[@"name"];
        NSNumber *dimensionType = dimension[@"type"];
        NSString *type;
        for (NSString *key in keys) {
            if ([dimensionKey isEqualToString:key]) {
                switch (dimensionType.integerValue) {
                    case 0:
                        type = @"l";
                        break;
                    case 1:
                        type = @"f";
                        break;
                    case 2:
                        type = @"s";
                        break;
                    case 4:
                        type = @"d";
                        break;
                    case 5:
                        type = @"i";
                        break;
                    default:
                        break;
                }
                if (type) {
                    [types setValue:type forKey:key];
                }
                break;
            }
        }
    }
    
    for (NSString *key in keys) {
        if (types[key]) {
            dataString = [NSMutableString stringWithFormat:@"%@%@%@%@%@",
                          dataString,
                          types[key],
                          TypeSeperator,
                          key,
                          KeysSeperator];
        }
    }
    dataString = [NSMutableString stringWithString:[dataString substringToIndex:dataString.length - 1]];
    dataString = [NSMutableString stringWithString:[dataString stringByAppendingString:LinesSeperator]];
    
    for (NSDictionary *object in batch) {
        NSMutableDictionary *value = [[NSMutableDictionary alloc] init];
        for (NSString *key in keys) {
            if (object[key]) {
                if ([[[object[key] classForCoder] description] isEqualToString:@"NSNumber"]) {
                    if (strcmp([(NSNumber *)object[key] objCType], @encode(int)) == 0
                        && [types[key] isEqualToString:@"i"]) {
                        [value setValue:object[key] forKey:key];
                    } else if ((strcmp([(NSNumber *)object[key] objCType], @encode(long)) == 0)
                        && [types[key] isEqualToString:@"l"]) {
                        [value setValue:object[key] forKey:key];
                    } else if (((strcmp([(NSNumber *)object[key] objCType], @encode(float)) == 0
                          || (strcmp([(NSNumber *)object[key] objCType], @encode(double)) == 0)))
                        && [types[key] isEqualToString:@"f"]) {
                        [value setValue:object[key] forKey:key];
                    } else {
                        [value setValue:(NSNumber *)object[key] forKey:key];
                    }
                } else if ([[[object[key] classForCoder] description] isEqualToString:@"NSDate"]
                    && [types[key] isEqualToString:@"d"]) {
                    [value setValue:[NSString stringWithFormat:@"%.0f", [((NSDate *)object[key]) timeIntervalSince1970] * 1000] forKey:key];
                } else if ([types[key] isEqualToString:@"s"]) {
                    [value setValue:object[key] forKey:key];
                } else {
                    [value setValue:@"" forKey:key];
                }
            } else {
                if ([types[key] isEqualToString:@"s"]) {
                    [value setValue:@"" forKey:key];
                } else {
                    [value setValue:@"" forKey:key];
                }
            }
        }
        [values addObject:value];
    }
    
    for (NSDictionary *value in values) {
        for (NSString *key in keys) {
            dataString = [NSMutableString stringWithFormat:@"%@%@%@",
                          dataString,
                          value[key]?value[key]:@"",
                          ValuesSeperator];
        }
        dataString = [NSMutableString stringWithString:[dataString substringToIndex:dataString.length - 1]];
        dataString = [NSMutableString stringWithString:[dataString stringByAppendingString:LinesSeperator]];
    }
    MPLogDebug(@"Data:\n%@", dataString);
    return [MPNetwork encodeBase64ForDataString:dataString];
}

+ (NSString *)encodeBase64ForDataString:(NSString *)dataString
{
    NSData *data = [dataString dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return @"";
    }
    NSString *base64Encoded = [data base64EncodedStringWithOptions:NSDataBase64EncodingEndLineWithCarriageReturn];
    
    return base64Encoded;
}

+ (id)convertFoundationTypesToJSON:(id)obj {
    // valid json types
    if ([obj isKindOfClass:NSNull.class]) {
        return @"";
    }
    
    if ([obj isKindOfClass:NSString.class] || [obj isKindOfClass:NSNumber.class]) {
        return obj;
    }
    
    if ([obj isKindOfClass:NSDate.class]) {
        return [[self dateFormatter] stringFromDate:obj];
    } else if ([obj isKindOfClass:NSURL.class]) {
        return [obj absoluteString];
    }
    
    // recurse on containers
    if ([obj isKindOfClass:NSArray.class]) {
        NSMutableArray *a = [NSMutableArray array];
        for (id i in obj) {
            [a addObject:[self convertFoundationTypesToJSON:i]];
        }
        return [NSArray arrayWithArray:a];
    }
    
    if ([obj isKindOfClass:NSDictionary.class]) {
        NSMutableDictionary *d = [NSMutableDictionary dictionary];
        for (id key in obj) {
            NSString *stringKey = key;
            if (![key isKindOfClass:[NSString class]]) {
                stringKey = [key description];
                MPLogWarning(@"%@ property keys should be strings. got: %@. coercing to: %@", self, [key class], stringKey);
            }
            id v = [self convertFoundationTypesToJSON:obj[key]];
            d[stringKey] = v;
        }
        return [NSDictionary dictionaryWithDictionary:d];
    }
    
    // default to sending the object's description
    NSString *s = obj?[obj description]:@"";
    MPLogWarning(@"%@ property values should be valid json types. got: %@. coercing to: %@", self, [obj class], s);
    return s;
}

+ (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        formatter.timeZone = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
        formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    });
    return formatter;
}

+ (NSTimeInterval)calculateBackOffTimeFromFailures:(NSUInteger)failureCount {
    NSTimeInterval time = pow(2.0, failureCount - 1) * 60 + arc4random_uniform(30);
    return MIN(MAX(60, time), 600);
}

+ (NSTimeInterval)parseRetryAfterTime:(NSHTTPURLResponse *)response {
    return [response.allHeaderFields[@"Retry-After"] doubleValue];
}

+ (BOOL)parseHTTPFailure:(NSHTTPURLResponse *)response withError:(NSError *)error {
    return (error != nil || (500 <= response.statusCode && response.statusCode <= 599));
}

- (void)updateNetworkActivityIndicator:(BOOL)enabled {
#if !SUGO_NO_NETWORK_ACTIVITY_INDICATOR
    if (self.shouldManageNetworkActivityIndicator) {
        [UIApplication sharedApplication].networkActivityIndicatorVisible = enabled;
    }
#endif
}

@end
