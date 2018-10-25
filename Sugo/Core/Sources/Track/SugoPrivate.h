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

#import "SugoExceptionHandler.h"

#if TARGET_OS_IPHONE
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "Sugo+AutomaticEvents.h"
#import "AutomaticEventsConstants.h"
#endif
#import <CoreData/CoreData.h>
#import "SugoEvents+CoreDataClass.h"

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
#import "WebViewBindings+UIWebView.h"

#import <CoreLocation/CoreLocation.h>

const static double locateDefaultInterval=30*60;//默认全局配置上传地理位置时间间隔

@interface Sugo () <CLLocationManagerDelegate>
{
    NSUInteger _flushInterval;
    NSUInteger _flushLimit;
    NSUInteger _flushMaxEvents;
    BOOL _enableVisualABTestAndCodeless;
    double _cacheInterval;
    double _locateInterval;
    NSNumber *latitude;
    NSNumber *longitude;
    long recentlySendLoacationTime;
}

@property (nonatomic, strong) CLLocationManager *locationManager;

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
@property (nonatomic, strong) NSTimer *locationTimer;
@property (nonatomic, strong) NSTimer *cacheTimer;
@property (nonatomic, strong) NSTimer *flushTimer;
@property (nonatomic, strong) NSMutableArray *eventsQueue;
@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonatomic) dispatch_queue_t serialQueue;
@property (nonatomic, strong) NSMutableDictionary *timedEvents;
@property (atomic, strong) NSMutableDictionary *sugoConfiguration;

@property (nonatomic) BOOL decideDimensionsResponseCached;
@property (nonatomic) BOOL decideBindingsResponseCached;

@property (nonatomic, strong) NSSet *eventBindings;

+ (void)assertPropertyTypes:(NSDictionary *)properties;

- (NSString *)deviceBrand;
- (NSString *)deviceModel;
- (NSString *)IFA;

- (void)archive;
- (NSString *)eventsFilePath;
- (NSString *)peopleFilePath;
- (NSString *)propertiesFilePath;

- (NSString *)defaultDeviceId;
- (NSString *)defaultDistinctId;

- (void)checkForDecideDimensionsResponseWithCompletion:(void (^)(void))completion;
- (void)checkForDecideDimensionsResponseWithCompletion:(void (^)(void))completion useCache:(BOOL)useCache;

- (void)checkForDecideBindingsResponseWithCompletion:(void (^)(NSSet *eventBindings))completion;
- (void)checkForDecideBindingsResponseWithCompletion:(void (^)(NSSet *eventBindings))completion useCache:(BOOL)useCache;

- (void)requestForHeatMapWithCompletion:(void (^)(NSData *heatMap))completion;
- (void)requestForFirstLoginWithIdentifer:(NSString *)identifer completion:(void (^)(NSData *firstLoginData))completion;

@end

