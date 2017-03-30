//
//  SugoPrivate.h
//  Sugo
//
//  Created by Sam Green on 6/16/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "Sugo.h"
#import "MPNetwork.h"

#import "SugoExceptionHandler.h"

#if TARGET_OS_IPHONE
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "Sugo+AutomaticEvents.h"
#import "AutomaticEventsConstants.h"
#endif

#import "MPResources.h"
#import "MPABTestDesignerConnection.h"
#import "UIView+MPHelpers.h"
#import "MPDesignerEventBindingMessage.h"
#import "WebViewBindings.h"
#import "SugoPageInfos.h"
#import "MPDesignerSessionCollection.h"
#import "MPEventBinding.h"
#import "MPSwizzler.h"
#import "MPWebSocket.h"


@interface Sugo ()
{
    NSUInteger _flushInterval;
    BOOL _enableVisualABTestAndCodeless;
    double _cacheInterval;
}

@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyInfo;

@property (nonatomic, strong) UILongPressGestureRecognizer *testDesignerGestureRecognizer;
@property (nonatomic, strong) MPABTestDesignerConnection *abtestDesignerConnection;

@property (nonatomic) AutomaticEventMode validationMode;
@property (nonatomic) NSUInteger validationEventCount;
@property (nonatomic, getter=isValidationEnabled) BOOL validationEnabled;

@property (nonatomic, assign) UIBackgroundTaskIdentifier taskId;
@property (nonatomic, strong) UIViewController *notificationViewController;

// re-declare internally as readwrite
@property (atomic, strong) SugoPeople *people;
@property (atomic, strong) MPNetwork *network;
@property (atomic, copy) NSString *deviceId;
@property (atomic, copy) NSString *distinctId;
@property (atomic, strong) NSString *sessionId;

@property (nonatomic, copy) NSString *apiToken;
@property (atomic, strong) NSString *urlSchemesKeyValue;
@property (atomic, strong) NSDictionary *superProperties;
@property (atomic, strong) NSDictionary *automaticProperties;
@property (atomic, strong) NSDictionary *priorityProperties;
@property (nonatomic, strong) NSTimer *cacheTimer;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableDictionary *timedEvents;
@property (atomic, strong) NSMutableDictionary *sugoConfiguration;

@property (nonatomic) BOOL decideResponseCached;

@property (nonatomic, strong) NSSet *eventBindings;

+ (void)assertPropertyTypes:(NSDictionary *)properties;

- (NSString *)deviceBrand;
- (NSString *)deviceModel;
- (NSString *)IFA;

- (NSString *)defaultDeviceId;
- (NSString *)defaultDistinctId;
- (void)archive;
- (NSString *)eventsFilePath;
- (NSString *)peopleFilePath;
- (NSString *)propertiesFilePath;

- (void)checkForDecideResponseWithCompletion:(void (^)(NSSet *eventBindings))completion;
- (void)checkForDecideResponseWithCompletion:(void (^)(NSSet *eventBindings))completion useCache:(BOOL)useCache;

@end

