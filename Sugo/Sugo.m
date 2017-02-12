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

#import "MPLogger.h"
#import "MPFoundation.h"

#define SUGO_NO_APP_LIFECYCLE_SUPPORT (defined(SUGO_APP_EXTENSION))
#define SUGO_NO_UIAPPLICATION_ACCESS (defined(SUGO_APP_EXTENSION))


@implementation Sugo

static NSMutableDictionary *instances;
static NSString *defaultProjectToken;

+ (Sugo *)sharedInstanceWithID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(NSDictionary *)launchOptions
{
    if (instances[projectID] && instances[apiToken]) {
        return instances[apiToken];
    }

#if defined(DEBUG)
    const NSUInteger flushInterval = 1;
#else
    const NSUInteger flushInterval = 60;
#endif

    Sugo *instance = [[self alloc] initWithID:projectID token:apiToken launchOptions:launchOptions andFlushInterval:flushInterval];
    
    NSDictionary *value = [NSDictionary dictionaryWithDictionary:instance.sugoConfiguration[@"DimensionValue"]];
    if (value) {
        [instance trackEvent:value[@"AppEnter"]];
        [instance timeEvent:value[@"AppStay"]];
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

- (instancetype)initWithID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(NSDictionary *)launchOptions andFlushInterval:(NSUInteger)flushInterval
{
    if (apiToken.length == 0) {
        if (apiToken == nil) {
            apiToken = @"";
        }
        MPLogWarning(@"%@ empty api token", self);
    }
    if (self = [self init:apiToken]) {
#if !SUGO_NO_EXCEPTION_HANDLING
        // Install uncaught exception handlers first
        [[SugoExceptionHandler sharedHandler] addSugoInstance:self];
#endif
        self.projectID = projectID;
        self.apiToken = apiToken;
        self.sessionId = [[[NSUUID alloc] init] UUIDString];
        _flushInterval = flushInterval;
        self.useIPAddressForGeoLocation = YES;
        self.shouldManageNetworkActivityIndicator = YES;
        self.flushOnBackground = YES;
        
        [self setupConfiguration];
        
        self.miniNotificationPresentationTime = 6.0;

        self.distinctId = [self defaultDistinctId];
        self.superProperties = [NSMutableDictionary dictionary];
        self.automaticProperties = [self collectAutomaticProperties];
#if !SUGO_NO_REACHABILITY_SUPPORT
        self.telephonyInfo = [[CTTelephonyNetworkInfo alloc] init];
#endif
        self.taskId = UIBackgroundTaskInvalid;
        
        NSString *label = [NSString stringWithFormat:@"io.sugo.%@.%p", apiToken, (void *)self];
        self.serialQueue = dispatch_queue_create([label UTF8String], DISPATCH_QUEUE_SERIAL);
        self.isCodelessTesting = NO;
#if defined(DISABLE_SUGO_AB_DESIGNER) // Deprecated in v3.0.1
        self.enableVisualABTestAndCodeless = NO;
#else
        self.enableVisualABTestAndCodeless = YES;
#endif
        
        self.network = [[MPNetwork alloc] initWithServerURL:[NSURL URLWithString:self.serverURL]
                                      andEventCollectionURL:[NSURL URLWithString:self.eventCollectionURL]];
        self.people = [[SugoPeople alloc] initWithSugo:self];

        [self setUpListeners];
        [self unarchive];
#if !SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT
        [self executeCachedEventBindings];
#endif
        instances[apiToken] = self;
    }
    return self;
}

- (instancetype)initWithID:(NSString *)projectID token:(NSString *)apiToken andFlushInterval:(NSUInteger)flushInterval
{
    return [self initWithID:projectID token:apiToken launchOptions:nil andFlushInterval:flushInterval];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
#if !SUGO_NO_REACHABILITY_SUPPORT
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
#endif
}

+ (NSDictionary *)loadConfigurationPropertyListWithName:(NSString *)name
{
    NSMutableDictionary *configuration = [[NSMutableDictionary alloc] init];
    NSBundle *bundle = [NSBundle bundleForClass:[Sugo class]];
    NSString *path = [bundle pathForResource:name ofType:@"plist"];
    if (path) {
        configuration = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    }
    NSLog(@"%@ Property List: %@", name, configuration);
    return [NSDictionary dictionaryWithDictionary:configuration];
}

#if !SUGO_NO_AUTOMATIC_EVENTS_SUPPORT
- (void)setValidationEnabled:(BOOL)validationEnabled {
    _validationEnabled = validationEnabled;
    
    if (_validationEnabled) {
        [Sugo setSharedAutomatedInstance:self];
    } else {
        [Sugo setSharedAutomatedInstance:nil];
    }
}
#endif

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

- (NSString *)defaultDistinctId
{
    NSString *distinctId = [self IFA];

    if (!distinctId && NSClassFromString(@"UIDevice")) {
        distinctId = [[UIDevice currentDevice].identifierForVendor UUIDString];
    }
    if (!distinctId) {
        MPLogInfo(@"%@ error getting device identifier: falling back to uuid", self);
        distinctId = [[NSUUID UUID] UUIDString];
    }
    return distinctId;
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
#if SUGO_FLUSH_IMMEDIATELY
    [self flush];
#endif
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
#if SUGO_FLUSH_IMMEDIATELY
    [self flush];
#endif
}

- (void)rawTrack:(NSString *)eventID eventName:(NSString *)eventName properties:(NSDictionary *)properties
{
    NSDictionary *key = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKey"]];
    if (!key) {
        return;
    }
    
    NSLog(@"track:%@, %@, %@", eventID, eventName, properties);
    if (eventName.length == 0) {
        MPLogWarning(@"%@ sugo track called with empty event parameter. using 'mp_event'", self);
        eventName = @"mp_event";
    }
    
#if !SUGO_NO_AUTOMATIC_EVENTS_SUPPORT
    // Safety check
    BOOL isAutomaticEvent = [eventName isEqualToString:kAutomaticEventName];
    if (isAutomaticEvent && !self.isValidationEnabled) return;
#endif
    
    properties = [properties copy];
    [Sugo assertPropertyTypes:properties];
    NSDate *date = [NSDate date];
    NSTimeInterval epochInterval = [date timeIntervalSince1970];
    NSNumber *eventStartTime = self.timedEvents[eventName];
    
    NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
    p[key[@"PagePath"]] = NSStringFromClass([[UIViewController sugoCurrentViewController] class]);
    if ([SugoPageInfos global].infos.count > 0) {
        for (NSDictionary *info in [SugoPageInfos global].infos) {
            if ([info[@"page"] isEqualToString:p[key[@"PagePath"]]]) {
                p[key[@"PageName"]] = info[@"page_name"];
            }
        }
    }
    p[key[@"Token"]] = self.apiToken;
    p[key[@"SessionID"]] = self.sessionId;
    if (eventStartTime) {
        [self.timedEvents removeObjectForKey:eventName];
        p[key[@"Duration"]] = @([[NSString stringWithFormat:@"%.2f", epochInterval - [eventStartTime doubleValue]] floatValue]);
    }
    if (self.distinctId) {
        p[key[@"DistinctID"]] = self.distinctId;
    }

    [p addEntriesFromDictionary:self.superProperties];
    if (properties) {
        [p addEntriesFromDictionary:properties];
    }
    
#if !SUGO_NO_AUTOMATIC_EVENTS_SUPPORT
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
#endif
    NSMutableDictionary *event = [[NSMutableDictionary alloc]
                                  initWithDictionary:@{ key[@"EventName"]: eventName}];
    
    if (!self.abtestDesignerConnection.connected
        || !self.isCodelessTesting) {
        [p addEntriesFromDictionary:self.automaticProperties];
        p[key[@"EventTime"]] = date;
        [event addEntriesFromDictionary:[NSDictionary dictionaryWithDictionary:p]];
    } else {
        p[key[@"EventTime"]] = @(epochInterval);
        event[@"properties"] = p;
    }
    
    if (eventID) {
        event[key[@"EventID"]] = eventID;
    }
    
    //        MPLogInfo(@"%@ queueing event: %@", self, event);
    [self.eventsQueue addObject:event];
    if (self.eventsQueue.count > 5000) {
        [self.eventsQueue removeObjectAtIndex:0];
    }
    
    if (self.abtestDesignerConnection.connected
        && self.isCodelessTesting) {
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
            self.timer = [NSTimer scheduledTimerWithTimeInterval:self.flushInterval
                                                          target:self
                                                        selector:@selector(flush)
                                                        userInfo:nil
                                                         repeats:YES];
            MPLogInfo(@"%@ started flush timer: %@", self, self.timer);
        }
    });
}

- (void)stopFlushTimer
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.timer) {
            [self.timer invalidate];
            MPLogInfo(@"%@ stopped flush timer: %@", self, self.timer);
            self.timer = nil;
        }
    });
}

- (void)flush
{
    [self flushWithCompletion:nil];
}

- (void)flushWithCompletion:(void (^)())handler
{
    if (self.isCodelessTesting) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
//        MPLogInfo(@"%@ flush starting", self);
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
//        MPLogInfo(@"%@ flush complete", self);
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
        NSLog(@"Error excluding %@ from backup %@", [URL lastPathComponent], error);
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
        __weak Sugo *weakSelf = self;
        dispatch_async(self.serialQueue, ^{
            Sugo *strongSelf = weakSelf;
            [strongSelf.network trackIntegrationWithID:strongSelf.projectID
                                              andToken:strongSelf.apiToken
                                         andDistinctID:strongSelf.distinctId
                                         andCompletion:^(NSError *error) {
                if (!error) {
                    [NSUserDefaults.standardUserDefaults setBool:YES
                                                          forKey:defaultKey];
                    [NSUserDefaults.standardUserDefaults synchronize];
                }
            }];
        });
    }
}

- (void)trackStayTime
{
    void (^viewDidAppearBlock)(id, SEL) = ^(id viewController, SEL command) {
        UIViewController *vc = (UIViewController *)viewController;
        if (!vc) {
            return;
        }

        NSDictionary *value = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValue"]];
        if (value) {
            [self trackEvent:value[@"PageEnter"] properties:nil];
            [self timeEvent:value[@"PageStay"]];
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
        
        NSDictionary *value = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValue"]];
        if (value) {
            [self trackEvent:value[@"PageStay"] properties:nil];
            [self trackEvent:value[@"PageExit"] properties:nil];
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

- (NSString *)watchModel
{
    NSString *model = nil;
    Class WKInterfaceDeviceClass = NSClassFromString(@"WKInterfaceDevice");
    if (WKInterfaceDeviceClass) {
        SEL currentDeviceSelector = NSSelectorFromString(@"currentDevice");
        id device = ((id (*)(id, SEL))[WKInterfaceDeviceClass methodForSelector:currentDeviceSelector])(WKInterfaceDeviceClass, currentDeviceSelector);
        SEL screenBoundsSelector = NSSelectorFromString(@"screenBounds");
        if (device && [device respondsToSelector:screenBoundsSelector]) {
            NSInvocation *screenBoundsInvocation = [NSInvocation invocationWithMethodSignature:[device methodSignatureForSelector:screenBoundsSelector]];
            [screenBoundsInvocation setSelector:screenBoundsSelector];
            [screenBoundsInvocation invokeWithTarget:device];
            CGRect screenBounds;
            [screenBoundsInvocation getReturnValue:(void *)&screenBounds];
            if (screenBounds.size.width == 136.0f) {
                model = @"Apple Watch 38mm";
            } else if (screenBounds.size.width == 156.0f) {
                model = @"Apple Watch 42mm";
            }
        }
    }
    return model;
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
#if !SUGO_NO_REACHABILITY_SUPPORT
    NSString *radio = _telephonyInfo.currentRadioAccessTechnology;
    if (!radio) {
        radio = @"None";
    } else if ([radio hasPrefix:@"CTRadioAccessTechnology"]) {
        radio = [radio substringFromIndex:23];
    }
    return radio;
#else 
    return @"";
#endif
}

- (NSString *)libVersion
{
    return [Sugo libVersion];
}

+ (NSString *)libVersion
{
    return [[NSBundle bundleForClass:[Sugo class]] infoDictionary][@"CFBundleShortVersionString"];
}

- (NSDictionary *)collectDeviceProperties
{
    UIDevice *device = [UIDevice currentDevice];
    CGSize size = [UIScreen mainScreen].bounds.size;
    NSDictionary *key = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKey"]];
    return @{
             key[@"SystemName"]: [device systemName],
             key[@"SystemVersion"]: [device systemVersion],
             key[@"ScreenWidth"]: @((NSInteger)size.width),
             key[@"ScreenHeight"]: @((NSInteger)size.height),
             };
}

- (NSDictionary *)collectAutomaticProperties
{
    NSMutableDictionary *p = [NSMutableDictionary dictionary];
    NSString *deviceModel = [self deviceModel];
    NSDictionary *key = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKey"]];

    // Use setValue semantics to avoid adding keys where value can be nil.
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"] forKey:key[@"AppBundleVersion"]];
    [p setValue:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"] forKey:key[@"AppBundleShortVersionString"]];
//    [p setValue:[self IFA] forKey:@"ios_ifa"];
    
#if !SUGO_NO_REACHABILITY_SUPPORT
    CTCarrier *carrier = [self.telephonyInfo subscriberCellularProvider];
    [p setValue:carrier.carrierName forKey:key[@"Carrier"]];
#endif

    [p addEntriesFromDictionary:@{
                                  key[@"SDKType"]: @"Objective-C",
                                  key[@"SDKVersion"]: [self libVersion],
                                  key[@"Manufacturer"]: @"Apple",
                                  key[@"DeviceModel"]: deviceModel, //legacy
                                  }];
    [p addEntriesFromDictionary:[self collectDeviceProperties]];
    return [p copy];
}

+ (BOOL)inBackground
{
#if !SUGO_NO_UIAPPLICATION_ACCESS
    return [UIApplication sharedApplication].applicationState == UIApplicationStateBackground;
#else
    return NO;
#endif
}

- (void)setupConfiguration
{
    self.sugoConfiguration = [[NSMutableDictionary alloc] init];
    // For URLs
    self.sugoConfiguration[@"URLs"] = [Sugo loadConfigurationPropertyListWithName:@"SugoURLs"];
    NSDictionary *urls = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"URLs"]];
    self.serverURL = urls[@"Bindings"];
    self.eventCollectionURL = urls[@"Collection"];
    self.switchboardURL = urls[@"Codeless"];
    
    // For Custom dimension table
    self.sugoConfiguration[@"DimensionKey"] = [Sugo loadConfigurationPropertyListWithName:@"SugoCustomDimensionKeyTable"];
    self.sugoConfiguration[@"DimensionValue"] = [Sugo loadConfigurationPropertyListWithName:@"SugoCustomDimensionValueTable"];
}

#pragma mark - UIApplication Events

- (void)setUpListeners
{
    [self trackIntegration];
    [self trackStayTime];
#if !SUGO_NO_REACHABILITY_SUPPORT
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
#endif // SUGO_NO_REACHABILITY_SUPPORT

#if !SUGO_NO_APP_LIFECYCLE_SUPPORT
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
#endif // SUGO_NO_APP_LIFECYCLE_SUPPORT

    [self initializeGestureRecognizer];
}

- (void) initializeGestureRecognizer {
#if !SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT
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
#endif // SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT
}

#if !SUGO_NO_REACHABILITY_SUPPORT

static void SugoReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void *info)
{
    Sugo *sugo = (__bridge Sugo *)info;
    if (sugo && [sugo isKindOfClass:[Sugo class]]) {
        [sugo reachabilityChanged:flags];
    }
}

- (void)reachabilityChanged:(SCNetworkReachabilityFlags)flags
{
    
    NSDictionary *key = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKey"]];
    if (!key) {
        return;
    }
    
    // this should be run in the serial queue. the reason we don't dispatch_async here
    // is because it's only ever called by the reachability callback, which is already
    // set to run on the serial queue. see SCNetworkReachabilitySetDispatchQueue in init
    NSMutableDictionary *properties = [self.automaticProperties mutableCopy];
    if (properties) {
        BOOL wifi = (flags & kSCNetworkReachabilityFlagsReachable) && !(flags & kSCNetworkReachabilityFlagsIsWWAN);
        properties[@"wifi"] = @(wifi);
        MPLogInfo(@"%@ reachability changed, wifi=%d", self, wifi);
        
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
            network = @"WiFi";
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
                network = @"WiFi";
            }
        }
        
        if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
        {
            /*
             ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
             */
            NSString *currentStatus = self.telephonyInfo.currentRadioAccessTechnology;
            
            if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyGPRS"]) {
                
                network = @"2G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyEdge"]) {
                
                network = @"2G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyWCDMA"]){
                
                network = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSDPA"]){
                
                network = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyHSUPA"]){
                
                network = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMA1x"]){
                
                network = @"2G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORev0"]){
                
                network = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevA"]){
                
                network = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyCDMAEVDORevB"]){
                
                network = @"3G";
            }else if ([currentStatus isEqualToString:@"CTRadioAccessTechnologyLTE"]){
                
                network = @"4G";
            } else {
                
                network = @"other";
            }
        }
        //
        properties[key[@"Reachability"]] = network;
        
        self.automaticProperties = [properties copy];
        MPLogInfo(@"Reachability: %@", network);
    }
}

#endif // SUGO_NO_REACHABILITY_SUPPORT

#if !SUGO_NO_APP_LIFECYCLE_SUPPORT

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    MPLogInfo(@"%@ application did become active", self);
    [self startFlushTimer];

#if !SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT
    
    [self checkForDecideResponseWithCompletion:^(NSSet *eventBindings) {
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            for (MPEventBinding *binding in eventBindings) {
                [binding execute];
            }
        });
    }];
#endif // SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT
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
    
    NSDictionary *value = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValue"]];
    if (value) {
        [self trackEvent:value[@"BackgroundEnter"]];
        [self timeEvent:value[@"BackgroundStay"]];
    }
    
    dispatch_group_enter(bgGroup);
    dispatch_async(_serialQueue, ^{
        [self archive];
        self.decideResponseCached = NO;
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
    
    NSDictionary *value = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValue"]];
    if (value) {
        [self trackEvent:value[@"BackgroundStay"]];
        [self trackEvent:value[@"BackgroundExit"]];
        [self.network flushEventQueue:self.eventsQueue];
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
    
    NSDictionary *value = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValue"]];
    if (value) {
        [self rawTrack:nil eventName:value[@"BackgroundStay"] properties:nil];
        [self rawTrack:nil eventName:value[@"BackgroundExit"] properties:nil];
        [self rawTrack:nil eventName:value[@"AppStay"] properties:nil];
        [self rawTrack:nil eventName:value[@"AppExit"] properties:nil];
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

#endif // SUGO_NO_APP_LIFECYCLE_SUPPORT

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

#if !SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT

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
        NSMutableSet *newEventBindings = [NSMutableSet set];
        __block BOOL hadError = NO;

        if ([NSUserDefaults.standardUserDefaults dataForKey:@"EventBindings"]) {
            
            NSData *cacheData = [NSUserDefaults.standardUserDefaults dataForKey:@"EventBindings"];
            NSLog(@"Decide cacheData\n%@",[[NSString alloc] initWithData:cacheData encoding:NSUTF8StringEncoding]);
            NSDictionary *object = [NSJSONSerialization JSONObjectWithData:cacheData options:(NSJSONReadingOptions)0 error:nil];
            NSDictionary *config = object[@"config"];
            if (config && [config isKindOfClass:NSDictionary.class]) {
                NSDictionary *validationConfig = config[@"ce"];
                if (validationConfig && [validationConfig isKindOfClass:NSDictionary.class]) {
                    self.validationEnabled = [validationConfig[@"enabled"] boolValue];
                    
                    NSString *method = validationConfig[@"method"];
                    if (method && [method isKindOfClass:NSString.class]) {
                        if ([method isEqualToString:@"count"]) {
                            self.validationMode = AutomaticEventModeCount;
                        }
                    }
                }
            }
            
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
            
            // Finished bindings are those which should no longer be run.
            NSMutableSet *finishedEventBindings = [NSMutableSet setWithSet:self.eventBindings];
            [finishedEventBindings minusSet:parsedEventBindings];
            [finishedEventBindings makeObjectsPerformSelector:NSSelectorFromString(@"stop")];
            
            // New bindings are those we are running for the first time.
            [newEventBindings unionSet:parsedEventBindings];
            [newEventBindings minusSet:self.eventBindings];
            
            NSMutableSet *allEventBindings = [self.eventBindings mutableCopy];
            [allEventBindings unionSet:newEventBindings];
            
            id htmlEventBindings = object[@"h5_event_bindings"];
            if ([htmlEventBindings isKindOfClass:[NSArray class]]) {
                [[WebViewBindings globalBindings].designerBindings removeAllObjects];
                [[WebViewBindings globalBindings].designerBindings addObjectsFromArray:(NSArray *)htmlEventBindings];
                [[WebViewBindings globalBindings] fillBindings];
            }
            
            id pageInfos = object[@"page_info"];
            if ([pageInfos isKindOfClass:[NSArray class]]) {
                [[SugoPageInfos global].infos removeAllObjects];
                [[SugoPageInfos global].infos addObjectsFromArray:(NSArray *)pageInfos];
            }
            
            self.eventBindings = [allEventBindings copy];
        }
        
        if (!useCache || !self.decideResponseCached) {
            // Build a proper URL from our parameters
            NSArray *queryItems = [MPNetwork buildDecideQueryForProperties:self.people.automaticPeopleProperties
                                                            withDistinctID:self.people.distinctId ?: self.distinctId
                                                                  andToken:self.apiToken];
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
                NSLog(@"Decide responseData\n%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                // Handle network response
                NSDictionary *object = [NSJSONSerialization JSONObjectWithData:responseData options:(NSJSONReadingOptions)0 error:&error];
                if (error) {
                    MPLogError(@"%@ decide check json error: %@, data: %@", self, error, [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                    hadError = YES;
                    dispatch_semaphore_signal(semaphore);
                    return;
                }
                if (object[@"error"]) {
                    MPLogError(@"%@ decide check api error: %@", self, object[@"error"]);
                    hadError = YES;
                    dispatch_semaphore_signal(semaphore);
                    return;
                }
                
                [NSUserDefaults.standardUserDefaults setObject:responseData
                                                        forKey:@"EventBindings"];
                
                NSDictionary *config = object[@"config"];
                if (config && [config isKindOfClass:NSDictionary.class]) {
                    NSDictionary *validationConfig = config[@"ce"];
                    if (validationConfig && [validationConfig isKindOfClass:NSDictionary.class]) {
                        self.validationEnabled = [validationConfig[@"enabled"] boolValue];

                        NSString *method = validationConfig[@"method"];
                        if (method && [method isKindOfClass:NSString.class]) {
                            if ([method isEqualToString:@"count"]) {
                                self.validationMode = AutomaticEventModeCount;
                            }
                        }
                    }
                }

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

                // Finished bindings are those which should no longer be run.
                NSMutableSet *finishedEventBindings = [NSMutableSet setWithSet:self.eventBindings];
                [finishedEventBindings minusSet:parsedEventBindings];
                [finishedEventBindings makeObjectsPerformSelector:NSSelectorFromString(@"stop")];

                // New bindings are those we are running for the first time.
                [newEventBindings unionSet:parsedEventBindings];
                [newEventBindings minusSet:self.eventBindings];
                
                NSMutableSet *allEventBindings = [self.eventBindings mutableCopy];
                [allEventBindings unionSet:newEventBindings];
                
                id htmlEventBindings = object[@"h5_event_bindings"];
                if ([htmlEventBindings isKindOfClass:[NSArray class]]) {
                    [[WebViewBindings globalBindings].designerBindings removeAllObjects];
                    [[WebViewBindings globalBindings].designerBindings addObjectsFromArray:(NSArray *)htmlEventBindings];
                    [[WebViewBindings globalBindings] fillBindings];
                }
                
                id pageInfos = object[@"page_info"];
                if ([pageInfos isKindOfClass:[NSArray class]]) {
                    [[SugoPageInfos global].infos removeAllObjects];
                    [[SugoPageInfos global].infos addObjectsFromArray:(NSArray *)pageInfos];
                }
                
                self.eventBindings = [allEventBindings copy];
                
                self.decideResponseCached = YES;

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
            MPLogInfo(@"%@ decide check found %lu tracking events, and %lu h5 tracking events",
                      self,
                      (unsigned long)self.eventBindings.count,
                      [[WebViewBindings globalBindings].designerBindings count]);

            if (completion) {
                completion(newEventBindings);
            }
        }
    });
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
    // Ignore the gesture if the AB test designer is disabled.
    if (!self.enableVisualABTestAndCodeless) return;
    
    if ([self.abtestDesignerConnection isKindOfClass:[MPABTestDesignerConnection class]] && ((MPABTestDesignerConnection *)self.abtestDesignerConnection).connected) {
        MPLogWarning(@"A/B test designer connection already exists");
        return;
    }
    static NSUInteger oldInterval;
    NSString *designerURLString = [NSString stringWithFormat:@"%@/connect/%@", self.switchboardURL, self.apiToken];
    NSURL *designerURL = [NSURL URLWithString:designerURLString];
    __weak Sugo *weakSelf = self;
    void (^connectCallback)(void) = ^{
        __strong Sugo *strongSelf = weakSelf;
        oldInterval = strongSelf.flushInterval;
        strongSelf.flushInterval = 1;
        [UIApplication sharedApplication].idleTimerDisabled = YES;
        if (strongSelf) {
            for (MPEventBinding *binding in self.eventBindings) {
                [binding stop];
            }
        }
    };
    void (^disconnectCallback)(void) = ^{
        __strong Sugo *strongSelf = weakSelf;
        strongSelf.flushInterval = oldInterval;
        [UIApplication sharedApplication].idleTimerDisabled = NO;
        if (strongSelf) {
            for (MPEventBinding *binding in self.eventBindings) {
                [binding execute];
            }
            [MPSwizzler unswizzleSelector:@selector(track:eventName:properties:) onClass:[Sugo class] named:@"track_properties"];
        }
    };
    self.abtestDesignerConnection = [[MPABTestDesignerConnection alloc] initWithURL:designerURL
                                                                         keepTrying:reconnect
                                                                    connectCallback:connectCallback
                                                                 disconnectCallback:disconnectCallback];
}

- (BOOL)handleURL:(NSURL *)url
{
    if ([[url.query componentsSeparatedByString:@"="] lastObject]) {
        self.urlSchemesKeyValue = [[url.query componentsSeparatedByString:@"="] lastObject];
        [self connectToABTestDesigner];
        return true;
    }
    return false;
}

#pragma mark - Sugo Event Bindings

- (void)executeCachedEventBindings {
    for (id binding in self.eventBindings) {
        if ([binding isKindOfClass:[MPEventBinding class]]) {
            [binding execute];
        }
    }
}

#endif // SUGO_NO_SURVEY_NOTIFICATION_AB_TEST_SUPPORT

@end
