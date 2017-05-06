#include <arpa/inet.h>
#include <net/if.h>
#include <net/if_dl.h>
#include <sys/socket.h>
#include <sys/sysctl.h>

#import <UIKit/UIKit.h>

#import "Sugo.h"
#import "SugoPrivate.h"
#import "SugoPeople.h"
#import "SugoPeoplePrivate.h"
#import "MPNetworkPrivate.h"
#import "UIViewController+SugoHelpers.h"
#import "SugoConfigurationPropertyList.h"

#import "MPLogger.h"
#import "MPFoundation.h"


NSString *SugoBindingsURL;
NSString *SugoCollectionURL;
NSString *SugoCodelessURL;
BOOL SugoCanTrackNativePage = false;
BOOL SugoCanTrackWebPage = false;

@implementation Sugo

static NSMutableDictionary *instances;
static NSString *defaultProjectToken;

+ (void)registerPriorityProperties:(NSDictionary *)priorityProperties
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:priorityProperties forKey:@"SugoPriorityProperties"];
    [userDefaults synchronize];
}

+ (Sugo *)sharedInstanceWithID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(NSDictionary *)launchOptions
{
    if (instances[projectID] && instances[apiToken]) {
        return instances[apiToken];
    }

    const NSUInteger flushInterval = 60;
    const double cacheInterval = 3600;

    Sugo *instance = [[self alloc] initWithID:projectID token:apiToken launchOptions:launchOptions andFlushInterval:flushInterval andCacheInterval:cacheInterval];
    
    NSDictionary *values = [NSDictionary dictionaryWithDictionary:instance.sugoConfiguration[@"DimensionValues"]];
    if (values) {
        [instance trackIntegration];
        [instance trackEvent:values[@"AppEnter"]];
        [instance timeEvent:values[@"AppStay"]];
        
        [instance checkForDecideResponseWithCompletion:^(NSSet *eventBindings) {
            dispatch_sync(dispatch_get_main_queue(), ^{
                for (MPEventBinding *binding in eventBindings) {
                    [binding execute];
                }
                [[WebViewBindings globalBindings] fillBindings];
            });
        }];
        [instance startCacheTimer];
    }
    
    return instance;
}

+ (Sugo *)sharedInstanceWithID:(NSString *)projectID token:(NSString *)apiToken
{
    return [Sugo sharedInstanceWithID:projectID token:apiToken launchOptions:nil];
}

+ (Sugo *)sharedInstance
{
    if (instances.count == 0) {
        MPLogWarning(@"sharedInstance called before creating a Sugo instance");
        return nil;
    }

    if (instances.count > 1) {
        MPLogWarning([NSString stringWithFormat:@"sharedInstance called with multiple sugo instances. Using (the first) token %@", defaultProjectToken]);
    }

    return instances[defaultProjectToken];
}

- (instancetype)init:(NSString *)apiToken
{
    if (self = [super init]) {
        self.eventsQueue = [NSMutableArray array];
        self.timedEvents = [NSMutableDictionary dictionary];
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            instances = [NSMutableDictionary dictionary];
            defaultProjectToken = apiToken;
        });
    }

    return self;
}

- (instancetype)initWithID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(NSDictionary *)launchOptions andFlushInterval:(NSUInteger)flushInterval andCacheInterval:(double)cacheInterval
{
    if (apiToken.length == 0) {
        if (apiToken == nil) {
            apiToken = @"";
        }
        MPLogWarning(@"%@ empty api token", self);
    }
    if (self = [self init:apiToken]) {

        // Install uncaught exception handlers first
        [[SugoExceptionHandler sharedHandler] addSugoInstance:self];

        self.projectID = projectID;
        self.apiToken = apiToken;
        self.sessionId = [[[NSUUID alloc] init] UUIDString];
        _flushInterval = flushInterval;
        _cacheInterval = cacheInterval;
        self.useIPAddressForGeoLocation = YES;
        self.shouldManageNetworkActivityIndicator = YES;
        self.flushOnBackground = YES;
        
        [self setupConfiguration];
        
        self.miniNotificationPresentationTime = 6.0;

        self.deviceId = [self defaultDeviceId];
        self.distinctId = [self defaultDistinctId];
        self.superProperties = [NSMutableDictionary dictionary];
        self.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
        self.automaticProperties = [self collectAutomaticProperties];
        self.priorityProperties = [self obtainPriorityProperties];
        self.taskId = UIBackgroundTaskInvalid;
        
        NSString *label = [NSString stringWithFormat:@"io.sugo.%@.%p", apiToken, (void *)self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        
#if defined(DISABLE_SUGO_AB_DESIGNER) // Deprecated in v3.0.1
        self.enableVisualABTestAndCodeless = NO;
#else
        self.enableVisualABTestAndCodeless = YES;
#endif
        self.heatMap = [[HeatMap alloc] initWithData:[NSData data]];
        self.network = [[MPNetwork alloc] initWithServerURL:[NSURL URLWithString:self.serverURL]
                                      andEventCollectionURL:[NSURL URLWithString:self.eventCollectionURL]];
        self.people = [[SugoPeople alloc] initWithSugo:self];

        self.decideResponseCached = NO;
        
        [self setUpListeners];
        [self unarchive];

        instances[apiToken] = self;
    }
    return self;
}

- (instancetype)initWithID:(NSString *)projectID token:(NSString *)apiToken andFlushInterval:(NSUInteger)flushInterval andCacheInterval:(double)cacheInterval
{
    return [self initWithID:projectID token:apiToken launchOptions:nil andFlushInterval:flushInterval andCacheInterval:cacheInterval];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    if (_reachability != NULL) {
        if (!SCNetworkReachabilitySetCallback(_reachability, NULL, NULL)) {
            MPLogError(@"%@ error unsetting reachability callback", self);
        }
        if (!SCNetworkReachabilitySetDispatchQueue(_reachability, NULL)) {
            MPLogError(@"%@ error unsetting reachability dispatch queue", self);
        }
        CFRelease(_reachability);
        _reachability = NULL;
    }
}

- (void)setValidationEnabled:(BOOL)validationEnabled {
    _validationEnabled = validationEnabled;
    
    if (_validationEnabled) {
        [Sugo setSharedAutomatedInstance:self];
    } else {
        [Sugo setSharedAutomatedInstance:nil];
    }
}

- (BOOL)shouldManageNetworkActivityIndicator {
    return self.network.shouldManageNetworkActivityIndicator;
}

- (void)setShouldManageNetworkActivityIndicator:(BOOL)shouldManageNetworkActivityIndicator {
    self.network.shouldManageNetworkActivityIndicator = shouldManageNetworkActivityIndicator;
}

- (BOOL)useIPAddressForGeoLocation {
    return self.network.useIPAddressForGeoLocation;
}

- (void)setUseIPAddressForGeoLocation:(BOOL)useIPAddressForGeoLocation {
    self.network.useIPAddressForGeoLocation = useIPAddressForGeoLocation;
}

#pragma mark - Tracking
+ (void)assertPropertyTypes:(NSDictionary *)properties
{
    [Sugo assertPropertyTypesInDictionary:properties depth:0];
}

+ (void)assertPropertyType:(id)propertyValue depth:(NSUInteger)depth
{
    // Note that @YES and @NO pass as instances of NSNumber class.
    NSAssert([propertyValue isKindOfClass:[NSString class]] ||
             [propertyValue isKindOfClass:[NSNumber class]] ||
             [propertyValue isKindOfClass:[NSNull class]] ||
             [propertyValue isKindOfClass:[NSArray class]] ||
             [propertyValue isKindOfClass:[NSDictionary class]] ||
             [propertyValue isKindOfClass:[NSDate class]] ||
             [propertyValue isKindOfClass:[NSURL class]],
             @"%@ property values must be NSString, NSNumber, NSNull, NSArray, NSDictionary, NSDate or NSURL. got: %@ %@", self, [propertyValue class], propertyValue);

#ifdef DEBUG
    if (depth == 3) {
        MPLogWarning(@"Your properties are overly nested, specifically 3 or more levels deep. \
                     Generally this is not recommended due to its complexity.");
    }
    if ([propertyValue isKindOfClass:[NSDictionary class]]) {
        [Sugo assertPropertyTypesInDictionary:propertyValue depth:depth+1];
    } else if ([propertyValue isKindOfClass:[NSArray class]]) {
        [Sugo assertPropertyTypesInArray:propertyValue depth:depth+1];
    }
#endif
}

+ (void)assertPropertyTypesInDictionary:(NSDictionary *)properties depth:(NSUInteger)depth
{
    if([properties count] > 1000) {
        MPLogWarning(@"You have an NSDictionary in your properties that is bigger than 1000 in size. \
                     Generally this is not recommended due to its size.");
    }
    for (id key in properties) {
        id value = properties[key];
        NSAssert([key isKindOfClass:[NSString class]], @"%@ property keys must be NSString. got: %@ %@", self, [key class], key);
        [Sugo assertPropertyType:value depth:depth];
    }
}

+ (void)assertPropertyTypesInArray:(NSArray *)arrayOfProperties depth:(NSUInteger)depth
{
    if([arrayOfProperties count] > 1000) {
        MPLogWarning(@"You have an NSArray in your properties that is bigger than 1000 in size. \
                     Generally this is not recommended due to its size.");
    }
    for (id value in arrayOfProperties) {
        [Sugo assertPropertyType:value depth:depth];
    }
}

- (NSString *)defaultDeviceId
{
    NSString *deviceId = [self IFA];

    if (!deviceId && NSClassFromString(@"UIDevice")) {
        deviceId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    if (!deviceId) {
        MPLogDebug(@"%@ error getting device identifier: falling back to uuid", self);
        deviceId = [[NSUUID UUID] UUIDString];
    }
    return deviceId;
}

- (NSString *)defaultDistinctId
{
    NSString *distinctId;
    
    NSString *defaultKey = @"distinctId";
    if (![NSUserDefaults.standardUserDefaults stringForKey:defaultKey]) {
        
        distinctId = [[NSUUID UUID] UUIDString];
        
        [NSUserDefaults.standardUserDefaults setObject:distinctId
                                                forKey:defaultKey];
        [NSUserDefaults.standardUserDefaults synchronize];
        
        return distinctId;
        
    } else {
        
        distinctId = (NSString *) [NSUserDefaults.standardUserDefaults objectForKey:defaultKey];
        
        return distinctId;
    }
}


- (void)identify:(NSString *)distinctId
{
    if (distinctId.length == 0) {
        MPLogWarning(@"%@ cannot identify blank distinct id: %@", self, distinctId);
        return;
    }
    
    dispatch_async(self.serialQueue, ^{
        self.distinctId = distinctId;
        [self archiveProperties];
    });
}

- (void)createAlias:(NSString *)alias forDistinctID:(NSString *)distinctID
{
    if (alias.length == 0) {
        MPLogError(@"%@ create alias called with empty alias: %@", self, alias);
        return;
    }
    if (distinctID.length == 0) {
        MPLogError(@"%@ create alias called with empty distinct id: %@", self, distinctID);
        return;
    }
    [self trackEvent:@"create_alias" properties:@{ @"distinct_id": distinctID, @"alias": alias }];
    [self flush];
}

- (void)trackEvent:(NSString *)event
{
    [self trackEventID:nil eventName:event properties:nil];
}

- (void)trackEvent:(NSString *)event properties:(NSDictionary *)properties
{
    [self trackEventID:nil eventName:event properties:properties];
}

- (void)trackEventID:(nullable NSString *)eventID eventName:(NSString *)eventName
{
    [self trackEventID:eventID eventName:eventName properties:nil];
}

- (void)trackEventID:(nullable NSString *)eventID eventName:(NSString *)eventName properties:(nullable NSDictionary *)properties
{
    dispatch_async(self.serialQueue, ^{
        [self rawTrack:eventID eventName:eventName properties:properties];
    });
}

- (void)rawTrack:(NSString *)eventID eventName:(NSString *)eventName properties:(NSDictionary *)properties
{
    NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
    if (!keys) {
        return;
    }
    
    MPLogDebug(@"track:%@, %@, %@", eventID, eventName, properties);
    if (!eventName && eventName.length == 0) {
        MPLogWarning(@"sugo track called with nil or empty event name: %@", eventName);
        return;
    }
    
    // Safety check
    BOOL isAutomaticEvent = [eventName isEqualToString:kAutomaticEventName];
    if (isAutomaticEvent && !self.isValidationEnabled) return;
    
    properties = [properties copy];
    [Sugo assertPropertyTypes:properties];
    NSDate *date = [NSDate date];
    NSTimeInterval epochInterval = [date timeIntervalSince1970];
    NSNumber *eventStartTime = self.timedEvents[eventName];
    
    NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
    
    p[keys[@"Token"]] = self.apiToken;
    p[keys[@"SessionID"]] = self.sessionId;
    if (eventStartTime) {
        [self.timedEvents removeObjectForKey:eventName];
        p[keys[@"Duration"]] = @([[NSString stringWithFormat:@"%.2f", epochInterval - [eventStartTime doubleValue]] floatValue]);
    }
    
    if (self.deviceId) {
        p[keys[@"DeviceID"]] = self.deviceId;
    }
    
    if (self.distinctId) {
        p[keys[@"DistinctID"]] = self.distinctId;
    }

    if (!p[keys[@"EventType"]]) {
        p[keys[@"EventType"]] = eventName;
    }
    
    [p addEntriesFromDictionary:self.automaticProperties];
    [p addEntriesFromDictionary:self.superProperties];
    [p addEntriesFromDictionary:self.priorityProperties];
    if (properties) {
        [p addEntriesFromDictionary:properties];
    }
    
    if (self.validationEnabled) {
        if (self.validationMode == AutomaticEventModeCount) {
            if (isAutomaticEvent) {
                self.validationEventCount++;
            } else {
                if (self.validationEventCount > 0) {
                    p[@"__c"] = @(self.validationEventCount);
                    self.validationEventCount = 0;
                }
            }
        }
    }
    
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    event[keys[@"EventName"]] = eventName;
    
    if (!self.abtestDesignerConnection.connected) {
        p[keys[@"EventTime"]] = date;
        [event addEntriesFromDictionary:[NSDictionary dictionaryWithDictionary:p]];
    } else {
        p[keys[@"EventTime"]] = [NSString stringWithFormat:@"%.0f", date.timeIntervalSince1970 * 1000];
        event[@"properties"] = p;
    }
    
    if (eventID) {
        event[keys[@"EventID"]] = eventID;
    }
    
    MPLogDebug(@"%@ queueing event: %@", self, event);
    if (event) {
        [self.eventsQueue addObject:event];
    }
    if (self.eventsQueue.count > 5000) {
        [self.eventsQueue removeObjectAtIndex:0];
    }
    
    if (self.abtestDesignerConnection.connected) {
        [self flushQueueViaWebSocket];
    }
    // Always archive
    [self archiveEvents];
}

- (void)registerSuperProperties:(NSDictionary *)properties
{
    properties = [properties copy];
    [Sugo assertPropertyTypes:properties];
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        [tmp addEntriesFromDictionary:properties];
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveProperties];
    });
}

- (void)registerSuperPropertiesOnce:(NSDictionary *)properties
{
    [self registerSuperPropertiesOnce:properties defaultValue:nil];
}

- (void)registerSuperPropertiesOnce:(NSDictionary *)properties defaultValue:(id)defaultValue
{
    properties = [properties copy];
    [Sugo assertPropertyTypes:properties];
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        for (NSString *key in properties) {
            id value = tmp[key];
            if (value == nil || [value isEqual:defaultValue]) {
                tmp[key] = properties[key];
            }
        }
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveProperties];
    });
}

- (void)unregisterSuperProperty:(NSString *)propertyName
{
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        tmp[propertyName] = nil;
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveProperties];
    });
}

- (void)clearSuperProperties
{
    dispatch_async(self.serialQueue, ^{
        self.superProperties = @{};
        [self archiveProperties];
    });
}

- (NSDictionary *)currentSuperProperties
{
    return [self.superProperties copy];
}

- (void)timeEvent:(NSString *)event
{
    NSNumber *startTime = @([[NSDate date] timeIntervalSince1970]);
    
    if (event.length == 0) {
        MPLogError(@"Sugo cannot time an empty event");
        return;
    }
    dispatch_async(self.serialQueue, ^{
        self.timedEvents[event] = startTime;
    });
}

- (void)clearTimedEvents
{   dispatch_async(self.serialQueue, ^{
        self.timedEvents = [NSMutableDictionary dictionary];
    });
}

- (void)reset
{
    dispatch_async(self.serialQueue, ^{
        self.deviceId = [self defaultDeviceId];
        self.distinctId = [self defaultDistinctId];
        self.superProperties = [NSMutableDictionary dictionary];
        self.people.distinctId = nil;
        self.eventsQueue = [NSMutableArray array];;
        self.timedEvents = [NSMutableDictionary dictionary];
        self.decideResponseCached = NO;
        self.eventBindings = [NSSet set];
        [self archive];
    });
}

#pragma mark - Network control
- (void)setServerURL:(NSString *)serverURL
{
    _serverURL = serverURL.copy;
}

- (double)cacheInterval {
    return _cacheInterval;
}

- (void)setCacheInterval:(double)interval
{
    @synchronized (self) {
        _cacheInterval = interval;
    }
}

- (void)startCacheTimer
{
    [self stopCacheTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.cacheInterval > 0) {
            self.cacheTimer = [NSTimer scheduledTimerWithTimeInterval:self.cacheInterval
                                                          target:self
                                                        selector:@selector(cache)
                                                        userInfo:nil
                                                         repeats:YES];
            MPLogDebug(@"%@ started cache timer: %f", self, self.cacheTimer.timeInterval);
        }
    });
}

- (void)stopCacheTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.cacheTimer) {
            [self.cacheTimer invalidate];
            MPLogDebug(@"%@ stopped cache timer: %f", self, self.cacheTimer.timeInterval);
            self.cacheTimer = nil;
        }
    });
}

- (void)cache
{
    self.decideResponseCached = NO;
    [self checkForDecideResponseWithCompletion:^(NSSet *eventBindings) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            for (MPEventBinding *binding in eventBindings) {
                [binding execute];
            }
            [WebViewBindings globalBindings].isWebViewNeedInject = NO;
            [[WebViewBindings globalBindings] fillBindings];
        });
    }];
}

- (NSUInteger)flushInterval {
    return _flushInterval;
}

- (void)setFlushInterval:(NSUInteger)interval
{
    @synchronized (self) {
        _flushInterval = interval;
    }
    [self flush];
    [self startFlushTimer];
}

- (void)startFlushTimer
{
    [self stopFlushTimer];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.flushInterval > 0) {
            self.flushTimer = [NSTimer scheduledTimerWithTimeInterval:self.flushInterval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            MPLogDebug(@"%@ started flush timer: %f", self, self.flushTimer.timeInterval);
        }
    });
}

- (void)stopFlushTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.flushTimer) {
            [self.flushTimer invalidate];
            MPLogDebug(@"%@ stopped flush timer: %f", self, self.flushTimer.timeInterval);
            self.flushTimer = nil;
        }
    });
}

- (void)flush
{
    [self flushWithCompletion:nil];
}

- (void)flushWithCompletion:(void (^)())handler
{
    dispatch_async(self.serialQueue, ^{
        __strong id<SugoDelegate> strongDelegate = self.delegate;
        if (strongDelegate && [strongDelegate respondsToSelector:@selector(sugoWillFlush:)]) {
            if (![strongDelegate sugoWillFlush:self]) {
                MPLogInfo(@"%@ flush deferred by delegate", self);
                return;
            }
        }
        [self.network flushEventQueue:self.eventsQueue];
        
        [self archive];
        
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), handler);
        }
    });
}

- (void)flushQueueViaWebSocket
{
    if (self.eventsQueue.count > 0) {
        NSDictionary *events = [NSDictionary dictionaryWithObject:self.eventsQueue
                                                           forKey:@"events"];
        [self.abtestDesignerConnection sendMessage:[MPDesignerTrackMessage messageWithPayload:events]];
        [self.eventsQueue removeAllObjects];
    }
}

#pragma mark - Persistence
- (NSString *)filePathFor:(NSString *)data
{
    NSString *filename = [NSString stringWithFormat:@"sugo-%@-%@.plist", self.apiToken, data];
    return [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
            stringByAppendingPathComponent:filename];
}

- (NSString *)eventsFilePath
{
    return [self filePathFor:@"events"];
}

- (NSString *)peopleFilePath
{
    return [self filePathFor:@"people"];
}

- (NSString *)propertiesFilePath
{
    return [self filePathFor:@"properties"];
}

- (NSString *)variantsFilePath
{
    return [self filePathFor:@"variants"];
}

- (NSString *)eventBindingsFilePath
{
    return [self filePathFor:@"event_bindings"];
}

- (void)archive
{
    [self archiveEvents];
    [self archiveProperties];
    [self archiveEventBindings];
}

- (void)archiveEvents
{
    NSString *filePath = [self eventsFilePath];
    NSMutableArray *eventsQueueCopy = [NSMutableArray arrayWithArray:[self.eventsQueue copy]];
//    MPLogInfo(@"%@ archiving events data to %@: %@", self, filePath, eventsQueueCopy);
    if (![self archiveObject:eventsQueueCopy withFilePath:filePath]) {
        MPLogError(@"%@ unable to archive event data", self);
    }
}

- (void)archiveProperties
{
    NSString *filePath = [self propertiesFilePath];
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    [p setValue:self.distinctId forKey:@"distinctId"];
    [p setValue:self.superProperties forKey:@"superProperties"];
    [p setValue:self.people.distinctId forKey:@"peopleDistinctId"];
    [p setValue:self.timedEvents forKey:@"timedEvents"];
//    MPLogInfo(@"%@ archiving properties data to %@: %@", self, filePath, p);
    if (![self archiveObject:p withFilePath:filePath]) {
        MPLogError(@"%@ unable to archive properties data", self);
    }
}

- (void)archiveEventBindings
{
    NSString *filePath = [self eventBindingsFilePath];
    if (![self archiveObject:self.eventBindings withFilePath:filePath]) {
        MPLogError(@"%@ unable to archive tracking events data", self);
    }
}

- (BOOL)archiveObject:(id)object withFilePath:(NSString *)filePath {
    @try {
        if (![NSKeyedArchiver archiveRootObject:object toFile:filePath]) {
            return NO;
        }
    } @catch (NSException* exception) {
        NSAssert(@"Got exception: %@, reason: %@. You can only send to Sugo values that inherit from NSObject and implement NSCoding.", exception.name, exception.reason);
        return NO;
    }

    [self addSkipBackupAttributeToItemAtPath:filePath];
    return YES;
}

- (BOOL)addSkipBackupAttributeToItemAtPath:(NSString *)filePathString
{
    NSURL *URL = [NSURL fileURLWithPath: filePathString];
    assert([[NSFileManager defaultManager] fileExistsAtPath: [URL path]]);

    NSError *error = nil;
    BOOL success = [URL setResourceValue: [NSNumber numberWithBool: YES]
                                  forKey: NSURLIsExcludedFromBackupKey error: &error];
    if (!success) {
        MPLogDebug(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
    }
    return success;
}

- (void)unarchive
{
    [self unarchiveEvents];
    [self unarchiveProperties];
    [self unarchiveEventBindings];
}

+ (nonnull id)unarchiveOrDefaultFromFile:(NSString *)filePath asClass:(Class)class
{
    return [self unarchiveFromFile:filePath asClass:class] ?: [class new];
}

+ (id)unarchiveFromFile:(NSString *)filePath asClass:(Class)class
{
    id unarchivedData = nil;
    @try {
        unarchivedData = [NSKeyedUnarchiver unarchiveObjectWithFile:filePath];
        // this check is inside the try-catch as the unarchivedData may be a non-NSObject, not responding to `isKindOfClass:` or `respondsToSelector:`
        if (![unarchivedData isKindOfClass:class]) {
            unarchivedData = nil;
        }
        MPLogInfo(@"%@ unarchived data from %@: %@", self, filePath, unarchivedData);
    }
    @catch (NSException *exception) {
        MPLogError(@"%@ unable to unarchive data in %@, starting fresh", self, filePath);
        // Reset un archived data
        unarchivedData = nil;
        // Remove the (possibly) corrupt data from the disk
        NSError *error = NULL;
        BOOL removed = [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
        if (!removed) {
            MPLogWarning(@"%@ unable to remove archived file at %@ - %@", self, filePath, error);
        }
    }
    return unarchivedData;
}

- (void)unarchiveEvents
{
    self.eventsQueue = (NSMutableArray *)[Sugo unarchiveOrDefaultFromFile:[self eventsFilePath] asClass:[NSMutableArray class]];
}

- (void)unarchiveProperties
{
    NSDictionary *properties = (NSDictionary *)[Sugo unarchiveFromFile:[self propertiesFilePath] asClass:[NSDictionary class]];
    if (properties) {
        self.deviceId = properties[@"deviceId"] ?: [self defaultDeviceId];
        self.distinctId = properties[@"distinctId"] ?: [self defaultDistinctId];
        self.superProperties = properties[@"superProperties"] ?: [NSMutableDictionary dictionary];
        self.people.distinctId = properties[@"peopleDistinctId"];
        self.eventBindings = properties[@"event_bindings"] ?: [NSSet set];
        self.timedEvents = properties[@"timedEvents"] ?: [NSMutableDictionary dictionary];
    }
}

- (void)unarchiveEventBindings
{
    self.eventBindings = (NSSet *)[Sugo unarchiveOrDefaultFromFile:[self eventBindingsFilePath] asClass:[NSSet class]];
}

- (void)trackIntegration
{
    NSString *defaultKey = @"trackedKey";
    if (![NSUserDefaults.standardUserDefaults boolForKey:defaultKey]) {
        
        NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
        if (values) {
            [self trackEvent:values[@"Integration"]];
            [NSUserDefaults.standardUserDefaults setBool:YES
                                                  forKey:defaultKey];
            [NSUserDefaults.standardUserDefaults synchronize];
        }
    }
}

- (void)trackStayTime
{
    void (^viewDidAppearBlock)(id, SEL) = ^(id viewController, SEL command) {
        UIViewController *vc = (UIViewController *)viewController;
        if (!vc) {
            return;
        }
        
        NSArray *vcBlackList = (NSArray *)self.sugoConfiguration[@"VCFilterList"][@"Black"];
        for (NSString *vcb in vcBlackList) {
            if ([vcb isEqualToString:NSStringFromClass([vc classForCoder])]) {
                return;
            }
        }
        
        NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
        NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
        NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
        if (keys && values) {
            p[keys[@"PagePath"]] = NSStringFromClass([vc class]);
            if ([SugoPageInfos global].infos.count > 0) {
                for (NSDictionary *info in [SugoPageInfos global].infos) {
                    if ([info[@"page"] isEqualToString:p[keys[@"PagePath"]]]) {
                        p[keys[@"PageName"]] = info[@"page_name"];
                    }
                }
            }
            [self trackEvent:values[@"PageEnter"] properties:p];
            [self timeEvent:values[@"PageStay"]];
        }
    };
    
    [MPSwizzler swizzleSelector:@selector(viewDidAppear:)
                        onClass:[UIViewController class]
                      withBlock:viewDidAppearBlock
                          named:[[NSUUID UUID] UUIDString]];
    
    void (^viewDidDisappearBlock)(id, SEL) = ^(id viewController, SEL command) {
        UIViewController *vc = (UIViewController *)viewController;
        if (!vc) {
            return;
        }
        
        NSArray *vcBlackList = (NSArray *)self.sugoConfiguration[@"VCFilterList"][@"Black"];
        for (NSString *vcb in vcBlackList) {
            if ([vcb isEqualToString:NSStringFromClass([vc classForCoder])]) {
                return;
            }
        }
        
        NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
        NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
        NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
        if (keys && values) {
            p[keys[@"PagePath"]] = NSStringFromClass([vc class]);
            if ([SugoPageInfos global].infos.count > 0) {
                for (NSDictionary *info in [SugoPageInfos global].infos) {
                    if ([info[@"page"] isEqualToString:p[keys[@"PagePath"]]]) {
                        p[keys[@"PageName"]] = info[@"page_name"];
                    }
                }
            }
            [self trackEvent:values[@"PageStay"] properties:p];
            [self trackEvent:values[@"PageExit"] properties:p];
        }
    };
    
    [MPSwizzler swizzleSelector:@selector(viewDidDisappear:)
                        onClass:[UIViewController class]
                      withBlock:viewDidDisappearBlock
                          named:[[NSUUID UUID] UUIDString]];
}

#pragma mark - Application Helpers

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Sugo: %p - Token: %@>", (void *)self, self.apiToken];
}

- (NSString *)deviceBrand
{
    UIDevice *device = [UIDevice currentDevice];
    
    switch (device.userInterfaceIdiom) {
        case UIUserInterfaceIdiomPhone:
            return @"iPhone";
        case UIUserInterfaceIdiomPad:
            return @"iPad";
        default:
            return @"Unrecognized";
    }
}

- (NSString *)deviceModel
{
    NSString *results = nil;
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char answer[size];
    sysctlbyname("hw.machine", answer, &size, NULL, 0);
    if (size) {
        results = @(answer);
    } else {
        MPLogError(@"Failed fetch hw.machine from sysctl.");
    }
    return results;
}

- (NSString *)IFA
{
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
}

- (void)setCurrentRadio
{
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *properties = [self.automaticProperties mutableCopy];
        if (properties) {
            properties[@"radio"] = [self currentRadio];
            self.automaticProperties = [properties copy];
        }
    });
}

- (NSString *)currentRadio
{
    NSString *radio = _telephonyInfo.currentRadioAccessTechnology;
    if (!radio) {
        radio = @"None";
    } else if ([radio hasPrefix:@"CTRadioAccessTechnology"]) {
        radio = [radio substringFromIndex:23];
    }
    return radio;
}

- (NSString *)libVersion
{
    return [Sugo libVersion];
}

+ (NSString *)libVersion
{
    return [[NSBundle bundleForClass:[Sugo class]] infoDictionary][@"CFBundleShortVersionString"];
}

- (NSDictionary *)obtainPriorityProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *priorityProperties = [userDefaults objectForKey:@"SugoPriorityProperties"];
    if (priorityProperties) {
        for (NSString *key in priorityProperties.allKeys) {
            [p setValue:priorityProperties[key] forKey:key];
        }
    }
    return [p copy];
}

- (NSDictionary *)collectDeviceProperties
{
    UIDevice *device = [UIDevice currentDevice];
    CGSize size = [UIScreen mainScreen].bounds.size;
    NSString *deviceBrand = [self deviceBrand];
    NSString *deviceModel = [self deviceModel];
    NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
    return @{
             keys[@"Manufacturer"]:  @"Apple",
             keys[@"DeviceBrand"]:   deviceBrand,
             keys[@"DeviceModel"]:   deviceModel,
             keys[@"SystemName"]:    [device systemName],
             keys[@"SystemVersion"]: [device systemVersion],
             keys[@"ScreenWidth"]:   [NSNumber numberWithInt:((int)size.width)],
             keys[@"ScreenHeight"]:  [NSNumber numberWithInt:((int)size.height)],
             };
}

- (NSDictionary *)collectAutomaticProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];

    // Use setValue semantics to avoid adding keys where value can be nil.
    NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
    [p setValue:info[@"CFBundleDisplayName"]?info[@"CFBundleDisplayName"]:info[@"Bundle name"] forKey:keys[@"AppBundleName"]];
    [p setValue:info[@"CFBundleVersion"] forKey:keys[@"AppBundleVersion"]];
    [p setValue:info[@"CFBundleShortVersionString"] forKey:keys[@"AppBundleShortVersionString"]];
    
    CTCarrier *carrier = [self.telephonyInfo subscriberCellularProvider];
    [p setValue:carrier.carrierName forKey:keys[@"Carrier"]];

    [p addEntriesFromDictionary:@{
                                  keys[@"SDKType"]:      @"Objective-C",
                                  keys[@"SDKVersion"]:   [self libVersion]
                                  }];
    [p addEntriesFromDictionary:[self collectDeviceProperties]];
    return [p copy];
}

+ (BOOL)inBackground
{
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
}

- (void)setupConfiguration
{
    self.sugoConfiguration = [[NSMutableDictionary alloc] init];
    // For URLs
    self.sugoConfiguration[@"URLs"] = [SugoConfigurationPropertyList loadWithName:@"SugoURLs"];
    NSDictionary *urls = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"URLs"]];
    if (SugoBindingsURL) {
        self.serverURL = SugoBindingsURL;
    } else {
        self.serverURL = urls[@"Bindings"];
    }
    if (SugoCollectionURL) {
        self.eventCollectionURL = SugoCollectionURL;
    } else {
        self.eventCollectionURL = urls[@"Collection"];
    }
    if (SugoCodelessURL) {
        self.switchboardURL = SugoCodelessURL;
    } else {
        self.switchboardURL = urls[@"Codeless"];
    }
    
    // For custom dimension table
    self.sugoConfiguration[@"DimensionKeys"] = [SugoConfigurationPropertyList loadWithName:@"SugoCustomDimensions" andKey:@"Keys"];
    self.sugoConfiguration[@"DimensionValues"] = [SugoConfigurationPropertyList loadWithName:@"SugoCustomDimensions" andKey:@"Values"];
    
    // For ViewController filter list
    self.sugoConfiguration[@"VCFilterList"] = [SugoConfigurationPropertyList loadWithName:@"SugoPageEventsViewControllerFilterList"];
    
    // For replacement of resources path
    NSString *homePathKey = @"HomePath";
    NSDictionary *rpr = @{NSHomeDirectory(): @""};
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:rpr forKey:homePathKey];
    [userDefaults synchronize];
    self.sugoConfiguration[@"ResourcesPathReplacements"] = [SugoConfigurationPropertyList loadWithName:@"SugoResourcesPathReplacements"];
}

#pragma mark - UIApplication Events

- (void)setUpListeners
{
    if (SugoCanTrackNativePage) {
        [self trackStayTime];
    }
    // cellular info
    [self setCurrentRadio];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setCurrentRadio)
                                                 name:CTRadioAccessTechnologyDidChangeNotification
                                               object:nil];
    // reachability
    if ((_reachability = SCNetworkReachabilityCreateWithName(NULL, [self.eventCollectionURL cStringUsingEncoding:NSUTF8StringEncoding])) != NULL) {
        SCNetworkReachabilityContext context = {0, (__bridge void*)self, NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(_reachability, SugoReachabilityCallback, &context)) {
            if (!SCNetworkReachabilitySetDispatchQueue(_reachability, self.serialQueue)) {
                // cleanup callback if setting dispatch queue failed
                SCNetworkReachabilitySetCallback(_reachability, NULL, NULL);
            }
        }
    }

    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    // Application lifecycle events
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillTerminate:)
                               name:UIApplicationWillTerminateNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillResignActive:)
                               name:UIApplicationWillResignActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidBecomeActive:)
                               name:UIApplicationDidBecomeActiveNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationDidEnterBackground:)
                               name:UIApplicationDidEnterBackgroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(applicationWillEnterForeground:)
                               name:UIApplicationWillEnterForegroundNotification
                             object:nil];
    [notificationCenter addObserver:self
                           selector:@selector(appLinksNotificationRaised:)
                               name:@"com.parse.bolts.measurement_event"
                             object:nil];

    [self initializeGestureRecognizer];
}

- (void) initializeGestureRecognizer {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.testDesignerGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(connectGestureRecognized:)];
        self.testDesignerGestureRecognizer.minimumPressDuration = 1;
        self.testDesignerGestureRecognizer.cancelsTouchesInView = NO;
#if TARGET_IPHONE_SIMULATOR
        self.testDesignerGestureRecognizer.numberOfTouchesRequired = 2;
#else
        self.testDesignerGestureRecognizer.numberOfTouchesRequired = 4;
#endif
        // because this is in a dispatch_async, if the user sets enableVisualABTestAndCodeless in the first run
        // loop then this is initialized after that is set so we have to check here
        self.testDesignerGestureRecognizer.enabled = self.enableVisualABTestAndCodeless;
        [[UIApplication sharedApplication].keyWindow addGestureRecognizer:self.testDesignerGestureRecognizer];
    });
}

static void SugoReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    Sugo *sugo = (__bridge Sugo *)info;
    if (sugo && [sugo isKindOfClass:[Sugo class]]) {
        [sugo reachabilityChanged:flags];
    }
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    
    NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
    if (!keys) {
        return;
    }
    
    // this should be run in the serial queue. the reason we don't dispatch_async here
    // is because it's only ever called by the reachability callback, which is already
    // set to run on the serial queue. see SCNetworkReachabilitySetDispatchQueue in init
    NSMutableDictionary *properties = [self.automaticProperties mutableCopy];
    if (properties) {
        
        properties[@"has_wifi"] = @"false";
        
        NSString *network = @"";
        if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
        {
            // The target host is not reachable.
            network = @"";
        }
        
        if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
        {
            /*
             If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
             */
            network = @"wifi";
            properties[@"has_wifi"] = @"true";
        }
        
        if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
             (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
        {
            /*
             ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
             */
            
            if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
            {
                /*
                 ... and no [user] intervention is needed...
                 */
                network = @"wifi";
                properties[@"has_wifi"] = @"true";
            }
        }
        
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
        {
            /*
             ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
             */
            NSString *currentStatus = self.telephonyInfo.currentRadioAccessTechnology;
            
            NSArray *status2G = @[CTRadioAccessTechnologyEdge,
                                  CTRadioAccessTechnologyGPRS,
                                  CTRadioAccessTechnologyCDMA1x];
            
            NSArray *status3G = @[CTRadioAccessTechnologyHSDPA,
                                  CTRadioAccessTechnologyWCDMA,
                                  CTRadioAccessTechnologyHSUPA,
                                  CTRadioAccessTechnologyCDMAEVDORev0,
                                  CTRadioAccessTechnologyCDMAEVDORevA,
                                  CTRadioAccessTechnologyCDMAEVDORevB,
                                  CTRadioAccessTechnologyeHRPD];
            
            NSArray *status4G = @[CTRadioAccessTechnologyLTE];
            
            if ([status4G containsObject:currentStatus]) {
                network = @"4G";
            } else if ([status3G containsObject:currentStatus]) {
                network = @"3G";
            } else if ([status2G containsObject:currentStatus]) {
                network = @"2G";
            } else {
                network = @"other";
            }
        }
        
        properties[keys[@"Reachability"]] = network;
        
        self.automaticProperties = [properties copy];
        MPLogDebug(@"Reachability: %@", network);
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    MPLogInfo(@"%@ application did become active", self);
    [self startFlushTimer];
}

- (void)applicationWillResignActive:(NSNotification *)notification
{
    MPLogInfo(@"%@ application will resign active", self);
    [self stopFlushTimer];
}

- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    MPLogInfo(@"%@ did enter background", self);
    __block UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        MPLogInfo(@"%@ flush %lu cut short", self, (unsigned long) backgroundTask);
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        self.taskId = UIBackgroundTaskInvalid;
    }];
    self.taskId = backgroundTask;
    MPLogInfo(@"%@ starting background cleanup task %lu", self, (unsigned long)self.taskId);
    
    dispatch_group_t bgGroup = dispatch_group_create();
    
    if (self.flushOnBackground) {
        [self flush];
    }
    
    NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
    if (values) {
        [self trackEvent:values[@"BackgroundEnter"]];
        [self timeEvent:values[@"BackgroundStay"]];
    }
    
    dispatch_group_enter(bgGroup);
    dispatch_async(_serialQueue, ^{
        [self archive];
        dispatch_group_leave(bgGroup);
    });
    
    dispatch_group_notify(bgGroup, dispatch_get_main_queue(), ^{
        MPLogInfo(@"%@ ending background cleanup task %lu", self, (unsigned long)self.taskId);
        if (self.taskId != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
            self.taskId = UIBackgroundTaskInvalid;
        }
    });
}

- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification
{
    MPLogInfo(@"%@ will enter foreground", self);
    
    NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
    if (values) {
        [self trackEvent:values[@"BackgroundStay"]];
        [self trackEvent:values[@"BackgroundExit"]];
    }
    
    dispatch_async(self.serialQueue, ^{
        if (self.taskId != UIBackgroundTaskInvalid) {
            [[UIApplication sharedApplication] endBackgroundTask:self.taskId];
            self.taskId = UIBackgroundTaskInvalid;
            [self.network updateNetworkActivityIndicator:NO];
        }
    });
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    MPLogInfo(@"%@ application will terminate", self);
    
    NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
    if (values) {
//        [self rawTrack:nil eventName:values[@"BackgroundStay"] properties:nil];
//        [self rawTrack:nil eventName:values[@"BackgroundExit"] properties:nil];
        [self rawTrack:nil eventName:values[@"AppStay"] properties:nil];
        [self rawTrack:nil eventName:values[@"AppExit"] properties:nil];
    }
    
    dispatch_async(_serialQueue, ^{
       [self archive];
    });
}

- (void)appLinksNotificationRaised:(NSNotification *)notification
{
    NSDictionary *eventMap = @{@"al_nav_out": @"al_nav_out",
                               @"al_nav_in": @"al_nav_in",
                               @"al_ref_back_out": @"al_ref_back_out"
                               };
    NSDictionary *userInfo = notification.userInfo;
    if (userInfo[@"event_name"] && userInfo[@"event_args"] && eventMap[userInfo[@"event_name"]]) {
        [self trackEvent:eventMap[userInfo[@"event_name"]] properties:userInfo[@"event_args"]];
    }
}

#pragma mark - Logging
- (void)setEnableLogging:(BOOL)enableLogging {
    gLoggingEnabled = enableLogging;

    if (gLoggingEnabled) {
        asl_add_log_file(NULL, STDERR_FILENO);
        asl_set_filter(NULL, ASL_FILTER_MASK_UPTO(ASL_LEVEL_DEBUG));
    } else {
        asl_remove_log_file(NULL, STDERR_FILENO);
    }
}

- (BOOL)enableLogging {
    return gLoggingEnabled;
}


#pragma mark - Decide

+ (UIViewController *)topPresentedViewController
{
    UIViewController *controller = [UIApplication sharedApplication].keyWindow.rootViewController;
    while (controller.presentedViewController) {
        controller = controller.presentedViewController;
    }
    return controller;
}

+ (BOOL)canPresentFromViewController:(UIViewController *)viewController
{
    // This fixes the NSInternalInconsistencyException caused when we try present a
    // survey on a viewcontroller that is itself being presented.
    if ([viewController isBeingPresented] || [viewController isBeingDismissed]) {
        return NO;
    }

    if ([viewController isKindOfClass:UIAlertController.class]) {
        return NO;
    }

    return YES;
}

- (void)checkForDecideResponseWithCompletion:(void (^)(NSSet *eventBindings))completion
{
    [self checkForDecideResponseWithCompletion:completion useCache:YES];
}

- (void)checkForDecideResponseWithCompletion:(void (^)(NSSet *eventBindings))completion useCache:(BOOL)useCache
{
    dispatch_async(self.serialQueue, ^{
        
        __block BOOL hadError = NO;
        __block NSMutableDictionary *responseObject = [[NSMutableDictionary alloc] init];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSMutableDictionary *cacheObject = [[NSMutableDictionary alloc] init];
        NSNumber *cacheVersion = @(-1);
        
        if (useCache && [userDefaults dataForKey:@"SugoEventBindings"]) {
            
            NSError *cacheError = nil;
            NSData *cacheData = [userDefaults dataForKey:@"SugoEventBindings"];
            MPLogDebug(@"Decide cacheData\n%@", [[NSString alloc] initWithData:cacheData
                                                                      encoding:NSUTF8StringEncoding]);
            @try {
                cacheObject = [NSJSONSerialization JSONObjectWithData:cacheData
                                                         options:(NSJSONReadingOptions)0
                                                           error:&cacheError];
                if (cacheObject[@"event_bindings_version"]) {
                    cacheVersion = cacheObject[@"event_bindings_version"];
                }
            } @catch (NSException *exception) {
                self.decideResponseCached = NO;
                MPLogError(@"exception: %@, cacheData: %@, object: %@",
                           exception,
                           cacheData,
                           cacheObject);
            }
        }
        
        if (!useCache || !self.decideResponseCached) {
            // Build a proper URL from our parameters
            NSArray *queryItems = [MPNetwork buildDecideQueryForProperties:self.people.automaticPeopleProperties
                                                            withDistinctID:self.people.distinctId ?: self.distinctId
                                                              andProjectID:self.projectID
                                                                  andToken:self.apiToken
                                                    andEventBindingVersion:cacheVersion];
            // Build a network request from the URL
            NSURLRequest *request = [self.network buildGetRequestForURL:[NSURL URLWithString:self.serverURL]
                                                            andEndpoint:MPNetworkEndpointDecide
                                                         withQueryItems:queryItems];
            
            // Send the network request
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                      NSURLResponse *urlResponse,
                                                                      NSError *error) {
                if (error) {
                    MPLogError(@"%@ decide check http error: %@", self, error);
                    hadError = YES;
                    dispatch_semaphore_signal(semaphore);
                    return;
                }
                MPLogDebug(@"Decide responseData\n%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                
                // Handle network response
                @try {
                    responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:(NSJSONReadingOptions)0 error:&error];
                    if (error) {
                        MPLogError(@"%@ decide check json error: %@, data: %@", self, error, [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                        hadError = YES;
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                    if (responseObject[@"error"]) {
                        MPLogError(@"%@ decide check api error: %@", self, responseObject[@"error"]);
                        hadError = YES;
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                    
                    [userDefaults setObject:responseData forKey:@"SugoEventBindings"];
                    [userDefaults synchronize];
                    self.decideResponseCached = YES;
                    
                } @catch (NSException *exception) {
                    MPLogError(@"exception: %@, responseData: %@, object: %@",
                               exception,
                               responseData,
                               responseObject);
                }
                
                dispatch_semaphore_signal(semaphore);
            }] resume];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            
        } else {
            MPLogInfo(@"%@ decide cache found, skipping network request", self);
        }
        
        if (hadError) {
            if (completion) {
                completion(nil);
            }
        } else {
            NSNumber *responseVersion = responseObject[@"event_bindings_version"];
            if (cacheVersion != responseVersion) {
                [self handleDecideObject:responseObject];
            } else {
                [self handleDecideObject:cacheObject];
            }
            
            MPLogInfo(@"%@ decide check found %lu tracking events, and %lu h5 tracking events",
                      self,
                      (unsigned long)self.eventBindings.count,
                      [[WebViewBindings globalBindings].designerBindings count]);
            
            if (completion) {
                completion(self.eventBindings);
            }
        }
    });
}

- (void)requestForHeatMapWithCompletion:(void (^)(NSData *heatMap))completion {
    
    if (self.abtestDesignerConnection.connected) return;
    
    dispatch_async(self.serialQueue, ^{
        
        __block BOOL hadError = NO;
        __block NSData *data = [[NSData alloc] init];
        
        NSArray *queryItems = [MPNetwork buildHeatQueryForToken:self.apiToken
                                                   andSecretKey:self.urlHeatMapSecretKey];
        // Build a network request from the URL
        NSURLRequest *request = [self.network buildGetRequestForURL:[NSURL URLWithString:self.serverURL]
                                                        andEndpoint:MPNetworkEndpointHeat
                                                     withQueryItems:queryItems];
        
        // Send the network request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                  NSURLResponse *urlResponse,
                                                                  NSError *error) {
            if (error) {
                MPLogError(@"%@ heat request http error: %@", self, error);
                hadError = YES;
                dispatch_semaphore_signal(semaphore);
                return;
            }
            MPLogDebug(@"Heat responseData\n%@",[[NSString alloc] initWithData:responseData
                                                                      encoding:NSUTF8StringEncoding]);
            
            // Handle network response
            data = responseData;
            
            dispatch_semaphore_signal(semaphore);
        }] resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        if (hadError) {
            if (completion) {
                completion(nil);
            }
        } else {
            if (completion) {
                completion(data);
            }
        }
    });
}

- (void)handleDecideObject:(NSDictionary *)object
{
    id commonEventBindings = object[@"event_bindings"];
    NSMutableSet *parsedEventBindings = [NSMutableSet set];
    if ([commonEventBindings isKindOfClass:[NSArray class]]) {
        for (id obj in commonEventBindings) {
            MPEventBinding *binder = [MPEventBinding bindingWithJSONObject:obj];
            if (binder) {
                [parsedEventBindings addObject:binder];
            }
        }
    } else {
        MPLogDebug(@"%@ tracking events check response format error: %@", self, object);
    }
    
    id htmlEventBindings = object[@"h5_event_bindings"];
    if ([htmlEventBindings isKindOfClass:[NSArray class]]) {
        [[WebViewBindings globalBindings].designerBindings removeAllObjects];
        [[WebViewBindings globalBindings].designerBindings addObjectsFromArray:(NSArray *)htmlEventBindings];
    }
    
    id pageInfos = object[@"page_info"];
    if ([pageInfos isKindOfClass:[NSArray class]]) {
        [[SugoPageInfos global].infos removeAllObjects];
        [[SugoPageInfos global].infos addObjectsFromArray:(NSArray *)pageInfos];
    }
    
    id dimensions = object[@"dimensions"];
    if (dimensions
        && [dimensions isKindOfClass:[NSArray class]]
        && ((NSArray *)dimensions).count > 0) {
        
        [[NSUserDefaults standardUserDefaults] setObject:dimensions
                                                  forKey:@"SugoDimensions"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    // Finished bindings are those which should no longer be run.
    NSMutableSet *finishedEventBindings = [NSMutableSet setWithSet:self.eventBindings];
    [finishedEventBindings minusSet:parsedEventBindings];
    [finishedEventBindings makeObjectsPerformSelector:NSSelectorFromString(@"stop")];
    
    // New bindings are those we are running for the first time.
    NSMutableSet *newEventBindings = [NSMutableSet set];
    [newEventBindings unionSet:parsedEventBindings];
    [newEventBindings minusSet:self.eventBindings];
    
    NSMutableSet *allEventBindings = [self.eventBindings mutableCopy];
    [allEventBindings minusSet:finishedEventBindings];
    [allEventBindings unionSet:newEventBindings];
    
    self.eventBindings = [allEventBindings copy];
}

#pragma mark - Sugo A/B Testing and Codeless (Designer)
- (void)setEnableVisualABTestAndCodeless:(BOOL)enableVisualABTestAndCodeless {
    _enableVisualABTestAndCodeless = enableVisualABTestAndCodeless;

    self.testDesignerGestureRecognizer.enabled = _enableVisualABTestAndCodeless;
    if (!_enableVisualABTestAndCodeless) {
        // Note that the connection will be closed and cleaned up properly in the dealloc method
        [self.abtestDesignerConnection close];
        self.abtestDesignerConnection = nil;
    }
}

- (BOOL)enableVisualABTestAndCodeless {
    return _enableVisualABTestAndCodeless;
}

- (void)connectGestureRecognized:(id)sender
{
    if (!sender || ([sender isKindOfClass:[UIGestureRecognizer class]] && ((UIGestureRecognizer *)sender).state == UIGestureRecognizerStateBegan)) {
        [self connectToABTestDesigner];
    }
}

- (void)connectToABTestDesigner
{
    [self connectToABTestDesigner:NO];
}

- (void)connectToABTestDesigner:(BOOL)reconnect
{
    if (self.heatMap.mode) return;
    
    // Ignore the gesture if the AB test designer is disabled.
    if (!self.enableVisualABTestAndCodeless) return;
    
    if ([self.abtestDesignerConnection isKindOfClass:[MPABTestDesignerConnection class]] && ((MPABTestDesignerConnection *)self.abtestDesignerConnection).connected) {
        MPLogWarning(@"A/B test designer connection already exists");
        return;
    }

    NSString *designerURLString = [NSString stringWithFormat:@"%@/connect/%@", self.switchboardURL, self.apiToken];
    NSURL *designerURL = [NSURL URLWithString:designerURLString];
    __weak Sugo *weakSelf = self;
    void (^connectCallback)(void) = ^{
        __strong Sugo *strongSelf = weakSelf;
        [strongSelf.eventsQueue removeAllObjects];
        [strongSelf stopFlushTimer];
        [strongSelf stopCacheTimer];
        [UIApplication sharedApplication].idleTimerDisabled = YES;
    };
    void (^disconnectCallback)(void) = ^{
        __strong Sugo *strongSelf = weakSelf;
        [strongSelf.eventsQueue removeAllObjects];
        [strongSelf startFlushTimer];
        [strongSelf startCacheTimer];
        [UIApplication sharedApplication].idleTimerDisabled = NO;
    };
    self.abtestDesignerConnection = [[MPABTestDesignerConnection alloc] initWithURL:designerURL
                                                                         keepTrying:reconnect
                                                                    connectCallback:connectCallback
                                                                 disconnectCallback:disconnectCallback];
}

- (BOOL)handleURL:(NSURL *)url
{
    NSLog(@"url: %@", url.absoluteString);
    NSArray *rawQuerys = [url.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *querys = [NSMutableDictionary dictionary];
    
    for (NSString *query in rawQuerys) {
        NSArray *item = [query componentsSeparatedByString:@"="];
        if (item.count != 2) {
            continue;
        }
        [querys addEntriesFromDictionary:@{[item firstObject]: [item lastObject]}];
    }
    
    if (querys[@"type"]
        && [querys[@"type"] isEqualToString:@"heatmap"]
        && querys[@"sKey"]) {
        self.urlCodelessSecretKey = (NSString *)querys[@"sKey"];
        [self requestForHeatMapWithCompletion:^(NSData *heatMap) {
            if (heatMap) {
                self.heatMap.data = heatMap;
                [self.heatMap switchMode:true];
                [[WebViewBindings globalBindings] switchHeatMapMode:self.heatMap.mode
                                                           withData:self.heatMap.data];
            }
        }];
        return true;
    } else if (querys[@"sKey"]) {
        self.urlCodelessSecretKey = (NSString *)querys[@"sKey"];
        [self connectToABTestDesigner];
        return true;
    }

    return false;
}

- (void)connectToCodelessViaURL:(NSURL *)url
{
    NSLog(@"url: %@", url.absoluteString);
    NSArray *rawQuerys = [url.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *querys = [NSMutableDictionary dictionary];
    
    for (NSString *query in rawQuerys) {
        NSArray *item = [query componentsSeparatedByString:@"="];
        if (item.count != 2) {
            continue;
        }
        [querys addEntriesFromDictionary:@{[item firstObject]: [item lastObject]}];
    }
    
    if (querys.count <= 0) {
        return;
    }
    
    if (querys[@"sKey"] && ((NSString *)querys[@"sKey"]).length > 0) {
        self.urlCodelessSecretKey = (NSString *)querys[@"sKey"];
    }
    
    if (querys[@"token"] && [querys[@"token"] isEqualToString:self.apiToken]) {
        [self connectToABTestDesigner];
    }
}

- (void)requestForHeatMapViaURL:(NSURL *)url
{
    NSLog(@"url: %@", url.absoluteString);
    NSArray *rawQuerys = [url.query componentsSeparatedByString:@"&"];
    NSMutableDictionary *querys = [NSMutableDictionary dictionary];
    
    for (NSString *query in rawQuerys) {
        NSArray *item = [query componentsSeparatedByString:@"="];
        if (item.count != 2) {
            continue;
        }
        [querys addEntriesFromDictionary:@{[item firstObject]: [item lastObject]}];
    }
    
    if (querys.count <= 0) {
        return;
    }
    
    if (querys[@"sKey"] && ((NSString *)querys[@"sKey"]).length > 0) {
        self.urlHeatMapSecretKey = (NSString *)querys[@"sKey"];
    }
    
    if (querys[@"token"] && [querys[@"token"] isEqualToString:self.apiToken]) {
        [self requestForHeatMapWithCompletion:^(NSData *heatMap) {
            if (heatMap) {
                self.heatMap.data = heatMap;
                [self.heatMap switchMode:true];
                [[WebViewBindings globalBindings] switchHeatMapMode:self.heatMap.mode
                                                           withData:self.heatMap.data];
            }
        }];
    }
}

@end










