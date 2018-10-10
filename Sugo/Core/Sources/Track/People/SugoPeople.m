//
//  SugoPeople.m
//  Sugo
//
//  Created by Sam Green on 6/16/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "SugoPeople.h"
#import "SugoPeoplePrivate.h"
#import "Sugo.h"
#import "SugoPrivate.h"
#import "MPLogger.h"

@implementation SugoPeople

- (instancetype)initWithSugo:(Sugo *)sugo
{
    if (self = [self init]) {
        self.sugo = sugo;
        self.automaticPeopleProperties = [self collectAutomaticPeopleProperties];
    }
    return self;
}

- (NSString *)deviceSystemVersion {
    return [UIDevice currentDevice].systemVersion;
}

- (NSString *)description
{
    __strong Sugo *strongSugo = self.sugo;
    return [NSString stringWithFormat:@"<SugoPeople: %p %@>", (void *)self, (strongSugo ? strongSugo.apiToken : @"")];
}

- (NSDictionary *)collectAutomaticPeopleProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionaryWithDictionary:@{
                                                                             @"ios_version": [self deviceSystemVersion],
                                                                             @"ios_lib_version": [Sugo libVersion],
                                                                             }];
    NSDictionary *infoDictionary = [NSBundle mainBundle].infoDictionary;
    if (infoDictionary[@"CFBundleVersion"]) {
        p[@"ios_app_version"] = infoDictionary[@"CFBundleVersion"];
    }
    if (infoDictionary[@"CFBundleShortVersionString"]) {
        p[@"ios_app_release"] = infoDictionary[@"CFBundleShortVersionString"];
    }
    __strong Sugo *strongSugo = self.sugo;
    NSString *deviceModel = [strongSugo deviceModel];
    if (deviceModel) {
        p[@"ios_device_model"] = deviceModel;
    }
//    NSString *ifa = [strongSugo IFA];
//    if (ifa) {
//        p[@"ios_ifa"] = ifa;
//    }
    return [p copy];
}

@end
