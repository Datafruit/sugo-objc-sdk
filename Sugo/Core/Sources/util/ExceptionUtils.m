//
//  ExceptionUtils.m
//  Sugo
//
//  Created by 陈宇艺 on 2019/6/9.
//  Copyright © 2019 sugo. All rights reserved.
//

#import "ExceptionUtils.h"
#import "MPNetwork.h"
#import "macro.h"

@interface ExceptionUtils ()



@end

@implementation ExceptionUtils

static NSString *projectId;
static NSString *tokenId;


+(void)buildTokenId:(NSString *)tId projectId:(NSString *)pId{
    projectId = pId;
    tokenId = tId;
}



+(void)exceptionToNetWork:(NSException *)exception{
    @try {
        dispatch_queue_t queue = dispatch_queue_create("io.sugo.SugoDemo", DISPATCH_QUEUE_SERIAL);
        //        [self ExceptionInfoWithException:nil];
        dispatch_async(queue, ^{
            NSString *topic =@"sugo_exception";
            if (SugoExceptionTopic!=nil&&SugoExceptionTopic.length>0) {
                topic = SugoExceptionTopic;
            }
            
            NSURLQueryItem *queryItem = [[NSURLQueryItem alloc] initWithName:@"locate"
                                                                       value:topic];
            NSMutableDictionary *dict = [self exceptionInfoWithException:exception];
            NSArray *queryItems = @[queryItem];
            NSError *error;
            NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
            NSString *requestData = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
            NSString *postBody = [NSString stringWithFormat:@"%@", requestData];
            MPNetwork *mMPNetwork = [[MPNetwork alloc] initWithServerURL:[NSURL URLWithString:SugoBindingsURL]
                                                   andEventCollectionURL:[NSURL URLWithString:SugoCollectionURL]];
            NSURLRequest *request = [mMPNetwork buildPostRequestForURL:[NSURL URLWithString:SugoCollectionURL]
                                                           andEndpoint:MPNetworkEndpointTrack
                                                        withQueryItems:queryItems
                                                               andBody:postBody];
            NSURLSession *session = [NSURLSession sharedSession];
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                      NSURLResponse *urlResponse,
                                                                      NSError *error) {
                NSString *requestData = [[NSString alloc]initWithData:responseData encoding:NSUTF8StringEncoding];
                dispatch_semaphore_signal(semaphore);
            }] resume];
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        });
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    
}

+(NSMutableDictionary *)exceptionInfoWithException:(NSException *)exception{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    @try {
        [dict setObject:projectId forKey:@"token"];
        [dict setObject:tokenId forKey:@"projectId"];
        [dict setObject:[[NSBundle bundleForClass:[self class]] infoDictionary][@"CFBundleShortVersionString"] forKey:@"sdkVersion" ];
        [dict setObject:[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] forKey:@"appVersion" ];
        [dict setObject:[self defaultDeviceId] forKey:@"deviceId"];
        [dict setObject:SUGOSSystemVersion forKey:@"systemVersion"];
        [dict setObject:SUGODeviceModel forKey:@"PhoneModel"];
        [dict setObject:exception.description forKey:@"exception"];
    } @catch (NSException *exception) {
        NSLog(@"%@",exception);
    }
    return dict;
}

+ (NSString *)IFA
{
    @try {
        NSString *ifa = nil;
#if !defined(SUGO_NO_IFA)
        Class ASIdentifierManagerClass = NSClassFromString(@"ASIdentifierManager");
        if (ASIdentifierManagerClass) {
            SEL sharedManagerSelector = NSSelectorFromString(@"sharedManager");
            id sharedManager = ((id (*)(id, SEL))[ASIdentifierManagerClass methodForSelector:sharedManagerSelector])(ASIdentifierManagerClass, sharedManagerSelector);
            SEL advertisingTrackingEnabledSelector = NSSelectorFromString(@"isAdvertisingTrackingEnabled");
            BOOL isTrackingEnabled = ((BOOL (*)(id, SEL))[sharedManager methodForSelector:advertisingTrackingEnabledSelector])(sharedManager, advertisingTrackingEnabledSelector);
            if (isTrackingEnabled) {
                SEL advertisingIdentifierSelector = NSSelectorFromString(@"advertisingIdentifier");
                NSUUID *uuid = ((NSUUID* (*)(id, SEL))[sharedManager methodForSelector:advertisingIdentifierSelector])(sharedManager, advertisingIdentifierSelector);
                ifa = [uuid UUIDString];
            }
        }
#endif
        return ifa;
    } @catch (NSException *exception) {
        return nil;
    }
  
}

+ (NSString *)defaultDeviceId
{
    @try {
        NSString *deviceId = [self IFA];
        
        if (!deviceId && NSClassFromString(@"UIDevice")) {
            deviceId = [[UIDevice currentDevice].identifierForVendor UUIDString];
        }
        if (!deviceId) {
            deviceId = @"";
        }
        return deviceId;
    } @catch (NSException *exception) {
        return @"";
    }
    
}

@end
