//
//  SugoPrivate.h
//  Sugo
//
//  Created by Sam Green on 6/16/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "Sugo.h"
#import "MPNetwork.h"
#import "HeatMap.h"

#if !SUGO_NO_EXCEPTION_HANDLING
#import "SugoExceptionHandler.h"
#endif

#if TARGET_OS_IPHONE
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

#if !SUGO_NO_AUTOMATIC_EVENTS_SUPPORT
#import "Sugo+AutomaticEvents.h"
#import "AutomaticEventsConstants.h"
#endif
#endif
#import <CoreData/CoreData.h>
#import "SugoEvents+CoreDataClass.h"

#if !SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT
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
#endif


@interface Sugo ()
{
    NSUInteger _flushInterval;
    BOOL _enableVisualABTestAndCodeless;
    double _cacheInterval;
}

@property (nonatomic, assign) SCNetworkReachabilityRef reachability;
@property (nonatomic, strong) CTTelephonyNetworkInfo *telephonyInfo;

#if !SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT
@property (nonatomic, strong) UILongPressGestureRecognizer *testDesignerGestureRecognizer;
@property (nonatomic, strong) MPABTestDesignerConnection *abtestDesignerConnection;
#endif

#if !SUGO_NO_AUTOMATIC_EVENTS_SUPPORT
@property (nonatomic) AutomaticEventMode validationMode;
@property (nonatomic) NSUInteger validationEventCount;
@property (nonatomic, getter=isValidationEnabled) BOOL validationEnabled;
#endif

@property (nonatomic, assign) UIBackgroundTaskIdentifier taskId;
@property (nonatomic, strong) UIViewController *notificationViewController;

// re-declare internally as readwrite
@property (atomic, strong) SugoPeople *people;
@property (atomic, strong) MPNetwork *network;
@property (atomic, strong) HeatMap *heatMap;
@property (atomic, copy) NSString *deviceId;
@property (atomic, copy) NSString *distinctId;
@property (atomic, strong) NSString *sessionId;

@property (nonatomic) BOOL enable;
@property (nonatomic, copy) NSString *apiToken;
@property (atomic, strong) NSString *urlCodelessSecretKey;
@property (atomic, strong) NSString *urlHeatMapSecretKey;
@property (atomic, strong) NSDictionary *superProperties;
@property (atomic, strong) NSDictionary *automaticProperties;
@property (atomic, strong) NSDictionary *priorityProperties;
@property (nonatomic, strong) NSTimer *cacheTimer;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
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

#if !SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT
- (void)checkForDecideResponseWithCompletion:(void (^)(NSSet *eventBindings))completion;
- (void)checkForDecideResponseWithCompletion:(void (^)(NSSet *eventBindings))completion useCache:(BOOL)useCache;
#endif

- (void)requestForHeatMapWithCompletion:(void (^)(NSData *heatMap))completion;

@end

