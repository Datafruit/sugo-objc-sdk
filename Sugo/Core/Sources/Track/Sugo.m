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
#import "ExceptionUtils.h"


NSString *SugoBindingsURL;
NSString *SugoCollectionURL;
NSString *SugoCodelessURL;
NSString *SugoExceptionTopic;
BOOL SugoCanTrackNativePage = true;
BOOL SugoCanTrackWebPage = true;
const static  NSString * ENTERBACKGROUNDTIME=@"enterBackgroundTime";

@implementation Sugo

static NSMutableDictionary *instances;
static NSString *defaultProjectToken;

+ (void)registerPriorityProperties:(NSDictionary *)priorityProperties
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:priorityProperties forKey:@"SugoPriorityProperties"];
    [userDefaults synchronize];
}

+ (Sugo *)sharedInstanceWithID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions {
    return [Sugo sharedInstanceWithEnable:YES projectID:projectID token:apiToken launchOptions:launchOptions];
}

+ (Sugo *)sharedInstanceWithEnable:(BOOL)enable projectID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions
{
    if (instances[projectID] && instances[apiToken]) {
        return instances[apiToken];
    }

    const NSUInteger flushInterval = 60;
    const double cacheInterval = 3600;

    Sugo *instance = [[self alloc] initWithEnable:enable
                                        projectID:projectID
                                            token:apiToken
                                    launchOptions:launchOptions
                                 andFlushInterval:flushInterval
                                 andCacheInterval:cacheInterval];
    
    NSDictionary *values = [NSDictionary dictionaryWithDictionary:instance.sugoConfiguration[@"DimensionValues"]];
    if (values) {
        [instance trackIntegration];
        [instance judgeWakeUpOrStartAppWithSugoStatus:YES];
//        [[WebViewBindings globalBindings] fillBindings];
        [instance checkForDecideDimensionsResponseWithCompletion:nil];
        [instance checkForDecideBindingsResponseWithCompletion:^(NSSet *eventBindings) {
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

+ (void)sharedInstanceWithID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions withCompletion:(void (^)())completion  {
    @try {
        [ExceptionUtils buildTokenId:apiToken projectId:projectID];
        [[[Sugo alloc]init:apiToken] initSugoRequestWithProject:projectID withToken:apiToken withCompletion:^() {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            bool isSugoInitialize = [userDefaults boolForKey:@"isSugoInitialize"];
            if (!isSugoInitialize) {
                
                return ;
            }
            [Sugo sharedInstanceWithEnable:YES projectID:projectID token:apiToken launchOptions:launchOptions];
            if (completion!=nil) {
                completion();
            }
        }];
    } @catch (NSException *exception) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        [userDefaults setBool:false forKey:@"isSugoInitialize"];
        [userDefaults synchronize];
        NSLog(@"SUGO_sharedInstanceWithID:%@",exception);
        @try {
            [ExceptionUtils exceptionToNetWork:exception];
        } @catch (NSException *exception) {
            
        }
    }
}

-(void)initSugoRequestWithProject:(NSString *)projectID withToken:(NSString *)token withCompletion:(void (^)())completion{
    @try {
        self.apiToken = token;
        self.projectID = projectID;
        dispatch_queue_t queue = dispatch_queue_create("io.sugo.SugoDemo", DISPATCH_QUEUE_SERIAL);
        dispatch_async(queue, ^{
            __block BOOL hadError = NO;
            __block NSData *resultData = [NSData data];
            __block NSDictionary *responseObject = [[NSMutableDictionary alloc] init];
            
            NSURLQueryItem *itemVersion = [NSURLQueryItem queryItemWithName:@"appVersion"
                                                                      value:[[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"]];
            NSURLQueryItem *itemProjectID = [NSURLQueryItem queryItemWithName:@"projectId" value:projectID];
            NSURLQueryItem *itemToken = [NSURLQueryItem queryItemWithName:@"tokenId" value:token];
            NSArray *queryItems = @[itemVersion,
                                    itemProjectID,
                                    itemToken];
            
            // Build a network request from the URL
            MPNetwork *mMPNetwork = [[MPNetwork alloc] initWithServerURL:[NSURL URLWithString:SugoBindingsURL]
                                                   andEventCollectionURL:[NSURL URLWithString:SugoCollectionURL]];
            NSURLRequest *request = [mMPNetwork buildGetRequestForURL:[NSURL URLWithString:SugoBindingsURL]
                                                          andEndpoint:MPNetworkEndpointInitSugo
                                                       withQueryItems:queryItems];
            
            // Send the network request
            dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                      NSURLResponse *urlResponse,
                                                                      NSError *error) {
                if (error) {
                    MPLogError(@"%@ request init sugo http error: %@", self, error);
                    hadError = YES;
                    dispatch_semaphore_signal(semaphore);
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    [userDefaults setBool:false forKey:@"isSugoInitialize"];
                    [userDefaults synchronize];
                    return;
                }
                MPLogDebug(@"request init sugo \n%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                
                // Handle network response
                @try {
                    responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:NSJSONReadingAllowFragments error:&error];
                    if (error) {
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setBool:false forKey:@"isSugoInitialize"];
                        [userDefaults synchronize];
                        MPLogError(@"%@ request init sugo json error: %@, data: %@", self, error, [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                        hadError = YES;
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                    if (responseObject[@"error"]) {
                        MPLogError(@"%@ request init sugo api error: %@", self, responseObject[@"error"]);
                        hadError = YES;
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                    if (responseObject[@"isSugoInitialize"]&&responseObject[@"isSugoInitialize"]!=[NSNull null]) {
                        [userDefaults setBool:[(NSNumber *)responseObject[@"isSugoInitialize"] boolValue]forKey:@"isSugoInitialize"];
                    }
                    
                    if (responseObject[@"isHeatMapFunc"]&&responseObject[@"isHeatMapFunc"]!=[NSNull null]) {
                        [userDefaults setBool:[(NSNumber *)responseObject[@"isHeatMapFunc"] boolValue] forKey:@"isHeatMapFunc"];
                    }
                    
                    if (responseObject[@"uploadLocation"]&&responseObject[@"uploadLocation"]!=[NSNull null]) {
                        long uploadLocation =[responseObject[@"uploadLocation"] longValue];
                        [userDefaults setInteger:uploadLocation forKey:@"uploadLocation"];
                    }
                    if(responseObject[@"latestEventBindingVersion"]&&responseObject[@"latestEventBindingVersion"]!=[NSNull null]){
                        long latestEventBindingVersion =[responseObject[@"latestEventBindingVersion"] longValue];
                        [userDefaults setInteger:latestEventBindingVersion forKey:@"latestEventBindingVersion"];
                    }
                    if(responseObject[@"latestDimensionVersion"]&&responseObject[@"latestDimensionVersion"]!=[NSNull null]){
                        long latestDimensionVersion =[responseObject[@"latestDimensionVersion"] longValue];
                        [userDefaults setInteger:latestDimensionVersion forKey:@"latestDimensionVersion"];
                    }
                    
                    if (responseObject[@"isUpdateConfig"]&&responseObject[@"isUpdateConfig"]!=[NSNull null]) {
                        [userDefaults setBool:[(NSNumber *)responseObject[@"isUpdateConfig"] boolValue]forKey:@"isUpdateConfig"];
                    }
                    [userDefaults synchronize];
                    
                    resultData = responseData;
                    
                } @catch (NSException *exception) {
                    @try {
                        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
                        [userDefaults setBool:false forKey:@"isSugoInitialize"];
                        [userDefaults synchronize];
                        NSLog(@"SUGO_initSugoRequestWithProject:%@",exception);
                        [ExceptionUtils exceptionToNetWork:exception];
                        MPLogError(@"exception: %@, request init sugo responseData: %@, object: %@",
                                   exception,
                                   responseData,
                                   responseObject);
                    } @catch (NSException *exception) {
                    }
                    
                }
                
                dispatch_semaphore_signal(semaphore);
            }] resume];
            
            dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
            if (!hadError) {
                if (completion!=nil) {
                    completion();
                }
            }
        });
    } @catch (NSException *exception) {
        @try {
            NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
            [userDefaults setBool:false forKey:@"isSugoInitialize"];
            [userDefaults synchronize];
            NSLog(@"SUGO_initSugoRequestWithProject:%@",exception);
            [ExceptionUtils exceptionToNetWork:exception];
        } @catch (NSException *exception) {
            
        }
    }
}

//when sugo instance ,judge this start time is more than the local leave app time
//isSugoInstance:when this param is yes ,is app instance
- (void)judgeWakeUpOrStartAppWithSugoStatus:(bool)isSugoInstance{
    NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
    NSTimeInterval currentTime = [self requireCurrentTime];
    NSTimeInterval beforeTime = [self requireBackgroundTime];
    if (currentTime-beforeTime>self.startupInterval) {
        if (values) {
            [self trackEvent:values[@"AppEnter"]];
            [self timeEvent:values[@"AppStay"]];
        }
    }else{
        if (values) {
            [self trackEvent:values[@"BackgroundStay"]];
            [self trackEvent:values[@"BackgroundExit"]];
        }
    }
    [self setupBackgroundTime];
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
        
        NSURL *modelURL = [[NSBundle bundleForClass: [self class]] URLForResource: @"Sugo" withExtension: @"momd"];
        if (modelURL != nil) {
            NSManagedObjectModel *mom  = [[NSManagedObjectModel alloc] initWithContentsOfURL: modelURL];
            NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: mom];
            NSString *dbPath = [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) lastObject]
                                stringByAppendingPathComponent: @"SugoEvents.sqlite"];
            NSLog(@"Events.sqlite path: %@", dbPath);
            NSURL *url = [NSURL fileURLWithPath: dbPath];
            NSError *error = nil;
            [psc addPersistentStoreWithType: NSSQLiteStoreType configuration:nil URL: url options: nil error: &error];
            if (error != nil) {
                NSLog(@"Failed to add persistent store. Error %@", error);
            } else {
                self.managedObjectContext  = [[NSManagedObjectContext alloc] initWithConcurrencyType: NSPrivateQueueConcurrencyType];
                self.managedObjectContext.persistentStoreCoordinator = psc;
            }
        }
        
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
    return [[Sugo alloc] initWithEnable:YES projectID:projectID token:apiToken launchOptions:launchOptions andFlushInterval:flushInterval andCacheInterval:cacheInterval];
}

- (instancetype)initWithEnable:(BOOL)enable projectID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions andFlushInterval:(NSUInteger)flushInterval  andCacheInterval:(double)cacheInterval
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
#if DEBUG
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        id overlayClass = NSClassFromString(@"UIDebuggingInformationOverlay");
        [overlayClass performSelector:NSSelectorFromString(@"prepareDebuggingOverlay")];
#pragma clang diagnostic pop
#endif
        self.enable = enable;
        self.projectID = projectID;
        self.apiToken = apiToken;
        self.sessionId = [[[NSUUID alloc] init] UUIDString];
        _flushInterval = flushInterval;
        _cacheInterval = cacheInterval;
        self.useIPAddressForGeoLocation = YES;
        self.shouldManageNetworkActivityIndicator = YES;
        self.flushOnBackground = YES;
        self.startupInterval = 30;
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

        self.decideDimensionsResponseCached = NO;
        self.decideBindingsResponseCached = NO;
        
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
        deviceId = @"";
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
    if (!self.enable) {
        return;
    }
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
    if (!self.enable) {
        return;
    }
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
    if (!self.enable) {
        return;
    }
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
    
    NSString *loginUserIdDimension = [NSUserDefaults.standardUserDefaults stringForKey:keys[@"LoginUserIdDimension"]];
    NSString *loginUserId = [NSUserDefaults.standardUserDefaults stringForKey:keys[@"LoginUserId"]];
    NSDictionary *firstLoginTimes = [NSUserDefaults.standardUserDefaults dictionaryForKey:keys[@"FirstLoginTime"]];
    if (loginUserIdDimension && loginUserId && firstLoginTimes && firstLoginTimes[loginUserId]) {
        p[loginUserIdDimension] = loginUserId;
        p[keys[@"FirstLoginTime"]] = firstLoginTimes[loginUserId];
    }
    NSTimeInterval firstVisitTime = [NSUserDefaults.standardUserDefaults doubleForKey:keys[@"FirstVisitTime"]];
    if (firstVisitTime) {
        p[keys[@"FirstVisitTime"]] = @([[NSString stringWithFormat:@"%.0f", firstVisitTime] integerValue]);
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
        if (self.abtestDesignerConnection.connected) {
            [self flushViaWebSocketEvent:event];
        } else {
            SugoEvents *sugoEvents = [NSEntityDescription insertNewObjectForEntityForName:@"SugoEvents" inManagedObjectContext:self.managedObjectContext];
            sugoEvents.token = self.apiToken;
            sugoEvents.event = [NSKeyedArchiver archivedDataWithRootObject:event];
            __weak Sugo *weakSelf = self;
            [self.managedObjectContext performBlockAndWait:^{
                __strong Sugo *strongSelf = weakSelf;
                if (![strongSelf.managedObjectContext save:nil]) {
                    MPLogError(@"%@ unable to save event data", self);
                }
                [strongSelf.managedObjectContext reset];
            }];
        }
    }
}

- (void)registerSuperProperties:(NSDictionary *)properties
{
    if (!self.enable) {
        return;
    }
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
    if (!self.enable) {
        return;
    }
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
    if (!self.enable) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        NSMutableDictionary *tmp = [NSMutableDictionary dictionaryWithDictionary:self.superProperties];
        tmp[propertyName] = nil;
        self.superProperties = [NSDictionary dictionaryWithDictionary:tmp];
        [self archiveProperties];
    });
}

- (void)clearSuperProperties
{
    if (!self.enable) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        self.superProperties = @{};
        [self archiveProperties];
    });
}

- (NSDictionary *)currentSuperProperties
{
    if (!self.enable) {
        return @{};
    }
    return [self.superProperties copy];
}

- (void)timeEvent:(NSString *)event
{
    if (!self.enable) {
        return;
    }
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
{
    if (!self.enable) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        self.timedEvents = [NSMutableDictionary dictionary];
    });
}

- (void)reset
{
    if (!self.enable) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        self.deviceId = [self defaultDeviceId];
        self.distinctId = [self defaultDistinctId];
        self.superProperties = [NSMutableDictionary dictionary];
        self.people.distinctId = nil;
        self.eventsQueue = [NSMutableArray array];;
        self.timedEvents = [NSMutableDictionary dictionary];
        self.decideDimensionsResponseCached = NO;
        self.decideBindingsResponseCached = NO;
        self.eventBindings = [NSSet set];
        [self archive];
    });
}
    
- (void)trackFirstLoginWith:(nullable NSString *)identifer dimension:(nullable NSString *)dimension {
    
    if (!self.enable) {
        return;
    }
    __block NSString *firstLoginKey = @"FirstLoginTime";
    __block NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
    __block NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
    __block NSMutableDictionary *firstLoginTimes = [NSMutableDictionary dictionary];
    NSDictionary *times = [NSUserDefaults.standardUserDefaults dictionaryForKey:firstLoginKey];
    if (times) {
        [firstLoginTimes addEntriesFromDictionary:times];
    }
    for (NSString *firstLoginTimeKey in firstLoginTimes.allKeys) {
        if ([identifer isEqualToString:firstLoginTimeKey]) {
            [NSUserDefaults.standardUserDefaults setObject:identifer forKey:keys[@"LoginUserId"]];
            [NSUserDefaults.standardUserDefaults synchronize];
            return;
        }
    }
    
    __weak Sugo *weakSelf = self;
    
    [self requestForFirstLoginWithIdentifer:identifer completion:^(NSData *firstLoginData) {
        
        __strong Sugo *strongSelf = weakSelf;
        if (!firstLoginData) {
            return;
        }
        @try {
            NSDictionary *firstLoginResult = [NSJSONSerialization JSONObjectWithData:firstLoginData
                                                                             options:(NSJSONReadingOptions)0
                                                                               error:nil][@"result"];
            [NSUserDefaults.standardUserDefaults setObject:dimension forKey:keys[@"LoginUserIdDimension"]];
            [NSUserDefaults.standardUserDefaults setObject:identifer forKey:keys[@"LoginUserId"]];
            [NSUserDefaults.standardUserDefaults synchronize];
            BOOL isFirstLogin = [firstLoginResult[@"isFirstLogin"] boolValue];
            if (isFirstLogin) {
                [strongSelf trackEvent:values[@"FirstLogin"]];
            }
            NSNumber *firstLoginTime = [NSNumber numberWithDouble:[firstLoginResult[@"firstLoginTime"] doubleValue]];
            firstLoginTimes[identifer] = firstLoginTime;
            [NSUserDefaults.standardUserDefaults setObject:firstLoginTimes forKey:keys[firstLoginKey]];
            [NSUserDefaults.standardUserDefaults synchronize];
            
        } @catch (NSException *exception) {
            MPLogError(@"unable to request first login with identifer");
        } @finally {
            return;
        }
        
    }];
}


- (void)requestForFirstStartTime {
    dispatch_async(self.serialQueue, ^{
        
        __block BOOL hadError = NO;
        NSDictionary *infoDictionary = [NSBundle mainBundle].infoDictionary;
        NSString *appVersion =  [infoDictionary objectForKey:@"CFBundleShortVersionString"];
        NSArray *queryItems = [MPNetwork buildFirsStartTimeQueryForAppId:self.apiToken andAppType:@"2" andDeviceId:self.deviceId andAppVersion:appVersion andProjectId:self.projectID];
        // Build a network request from the URL
        NSURLRequest *request = [self.network buildGetRequestForURL:[NSURL URLWithString:self.serverURL]
                                                        andEndpoint:MPNetworkEndpointFirstStartTime
                                                     withQueryItems:queryItems];
        // Send the network request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                  NSURLResponse *urlResponse,
                                                                  NSError *error) {
            if (error) {
                MPLogError(@"%@ first login request http error: %@", self, error);
                hadError = YES;
                dispatch_semaphore_signal(semaphore);
                return;
            }
            MPLogDebug(@"first login responseData\n%@",[[NSString alloc] initWithData:responseData
                                                                             encoding:NSUTF8StringEncoding]);
            NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
            NSDictionary *result = [NSJSONSerialization JSONObjectWithData:responseData
                                                                             options:(NSJSONReadingOptions)0
                                                                               error:nil];
            NSNumber * boolNum = result[@"isFirstStart"];
            BOOL isFirstInstallation = [boolNum boolValue];
            if (isFirstInstallation) {
                [self trackEvent:keys[@"FirstInstallation"]];
                [self trackEvent:keys[@"FirstVisit"]];
            }
            dispatch_semaphore_signal(semaphore);
        }] resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    });
}
    
- (void)requestForFirstLoginWithIdentifer:(NSString *)identifer completion:(void (^)(NSData *firstLoginData))completion {
    
    dispatch_async(self.serialQueue, ^{
        
        __block BOOL hadError = NO;
        __block NSData *data = [[NSData alloc] init];
        
        NSArray *queryItems = [MPNetwork buildFirstLoginQueryForIdentifer:identifer andProjectID:self.projectID andToken:self.apiToken];
        // Build a network request from the URL
        NSURLRequest *request = [self.network buildGetRequestForURL:[NSURL URLWithString:self.serverURL]
                                                        andEndpoint:MPNetworkEndpointFirstLogin
                                                     withQueryItems:queryItems];
        // Send the network request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                  NSURLResponse *urlResponse,
                                                                  NSError *error) {
            if (error) {
                MPLogError(@"%@ first login request http error: %@", self, error);
                hadError = YES;
                dispatch_semaphore_signal(semaphore);
                return;
            }
            MPLogDebug(@"first login responseData\n%@",[[NSString alloc] initWithData:responseData
                                                                      encoding:NSUTF8StringEncoding]);
            
            // Handle network response
            data = responseData;
            
            dispatch_semaphore_signal(semaphore);
        }] resume];
        
        dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
        
        // handle response
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

- (void)untrackFirstLogin {
    
    if (!self.enable) {
        return;
    }
    NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
    [NSUserDefaults.standardUserDefaults removeObjectForKey:keys[@"LoginUserId"]];
    [NSUserDefaults.standardUserDefaults synchronize];
    
}

- (void)updateSessionId:(NSString *)sessionId {
    _sessionId = sessionId.copy;
}

- (void)setPageInfos:(NSArray<NSDictionary *> *)pageInfos {
    [SugoPageInfos global].infos = [pageInfos copy];
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
    self.decideDimensionsResponseCached = NO;
    self.decideBindingsResponseCached = NO;
    [self checkForDecideBindingsResponseWithCompletion:^(NSSet *eventBindings) {
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

- (void)flush {
    [self flushWithCompletion:nil];
}

- (void)flushWithCompletion:(void (^)())handler
{
    if (!self.enable) {
        return;
    }
    dispatch_async(self.serialQueue, ^{
        __strong id<SugoDelegate> strongDelegate = self.delegate;
        if (strongDelegate && [strongDelegate respondsToSelector:@selector(sugoWillFlush:)]) {
            if (![strongDelegate sugoWillFlush:self]) {
                MPLogInfo(@"%@ flush deferred by delegate", self);
                return;
            }
        }
        
        NSArray *eventResult = [self fetchEventResultOfLimit: 50];
        while (eventResult.count > 0) {
            NSMutableArray *queue = [NSMutableArray array];
            if (eventResult != nil) {
                for (SugoEvents *event in eventResult) {
                    NSData *data = event.event;
                    if (data != nil) {
                        [queue addObject:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
                    }
                }
            }
            [self.network flushEventQueue:queue];
            
            if (eventResult != nil && queue.count == 0) {
                [self deleteEventResult:eventResult];
                [self.managedObjectContext reset];
                eventResult = [self fetchEventResultOfLimit: 50];
            } else {
                [self.managedObjectContext reset];
                break;
            }
        }
        
        if (handler) {
            dispatch_async(dispatch_get_main_queue(), handler);
        }
    });
}

- (void)flushViaWebSocketEvent:(NSDictionary *)event
{
    NSMutableArray *eq = [NSMutableArray array];
    [eq addObject:event];
    NSDictionary *events = [NSDictionary dictionaryWithObject:eq
                                                       forKey:@"events"];
    [self.abtestDesignerConnection sendMessage:[MPDesignerTrackMessage messageWithPayload:events]];
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
    if (!self.enable) {
        return;
    }
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

- (NSArray *)fetchEventResultOfLimit:(NSUInteger)limit {
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *sugoEventsEntity = [NSEntityDescription entityForName:@"SugoEvents" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:sugoEventsEntity];
    NSPredicate *predicate = [NSPredicate predicateWithFormat: @"(token = %@)", self.apiToken];
    [fetchRequest setPredicate:predicate];
    [fetchRequest setFetchLimit: limit];
    NSArray *eventResult = [self.managedObjectContext executeFetchRequest:fetchRequest error:nil].copy;
    return eventResult;
}

- (void)deleteEventResult:(NSArray *)eventResult {
    
    for (SugoEvents *event in eventResult) {
        [self.managedObjectContext deleteObject:event];
    }
    __weak Sugo *weakSelf = self;
    [self.managedObjectContext performBlockAndWait:^{
        __strong Sugo *strongSelf = weakSelf;
        [strongSelf.managedObjectContext save:nil];
    }];
}

- (void)unarchive
{
//    [self unarchiveEvents];
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
        [NSUserDefaults.standardUserDefaults setBool:YES forKey:defaultKey];
        NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
        NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
        NSDate *date = [NSDate date];
        NSTimeInterval firstVisitTime = [date timeIntervalSince1970] * 1000;
        [NSUserDefaults.standardUserDefaults setDouble:firstVisitTime forKey:keys[@"FirstVisitTime"]];
        [NSUserDefaults.standardUserDefaults synchronize];
        
        if (values) {
            [self trackEvent:values[@"Integration"]];
            [self requestForFirstStartTime];
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
                        if (info[@"page_category"]) {
                            p[keys[@"PageCategory"]] = info[@"page_category"];
                        }
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
                        if (info[@"page_category"]) {
                            p[keys[@"PageCategory"]] = info[@"page_category"];
                        }
                    }
                }
            }
            [self trackEvent:values[@"PageStay"] properties:p];
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
    return [[NSBundle bundleForClass:[self class]] infoDictionary][@"CFBundleShortVersionString"];
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
             keys[@"ScreenPixel"]: [NSString stringWithFormat:@"%@*%@", [NSNumber numberWithFloat:size.width], [NSNumber numberWithFloat:size.height]]
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

//    [self initializeGestureRecognizer];
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
    [self setupBackgroundTime];
}



- (void)applicationDidEnterBackground:(NSNotification *)notification
{
    MPLogInfo(@"%@ did enter background", self);
    NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
    // Page Stay
    if (values) {
        [self trackEvent:values[@"BackgroundEnter"]];
        [self timeEvent:values[@"BackgroundStay"]];
    }
    UIWebView *uiwv = WebViewBindings.globalBindings.uiWebView;
    WKWebView *wkwv = WebViewBindings.globalBindings.wkWebView;
    if (uiwv || wkwv) {
        if (uiwv && uiwv.window == UIApplication.sharedApplication.keyWindow) {
            [WebViewBindings.globalBindings trackStayEventOfWebView:uiwv];
        }
        if (wkwv && wkwv.window == UIApplication.sharedApplication.keyWindow) {
            [wkwv evaluateJavaScript:@"sugo.trackStayEvent();" completionHandler:nil];
        }
    } else if (values) {
        UIViewController *vc = [UIViewController sugoCurrentUIViewController];
        NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
        if (vc) {
            NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
            if (keys) {
                p[keys[@"PagePath"]] = NSStringFromClass([vc class]);
                if ([SugoPageInfos global].infos.count > 0) {
                    for (NSDictionary *info in [SugoPageInfos global].infos) {
                        if ([info[@"page"] isEqualToString:p[keys[@"PagePath"]]]) {
                            p[keys[@"PageName"]] = info[@"page_name"];
                            if (info[@"page_category"]) {
                                p[keys[@"PageCategory"]] = info[@"page_category"];
                            }
                        }
                    }
                }
                [self trackEvent:values[@"PageStay"] properties:p];
            }
        }
    }
    if (self.flushOnBackground) {
        [self flush];
    }
    
    __block UIBackgroundTaskIdentifier backgroundTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        MPLogInfo(@"%@ flush %lu cut short", self, (unsigned long) backgroundTask);
        [[UIApplication sharedApplication] endBackgroundTask:backgroundTask];
        self.taskId = UIBackgroundTaskInvalid;
    }];
    self.taskId = backgroundTask;
    MPLogInfo(@"%@ starting background cleanup task %lu", self, (unsigned long)self.taskId);
    
    dispatch_group_t bgGroup = dispatch_group_create();
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


//save current time ,use it to judge AppEnter events when back up
-(void) setupBackgroundTime{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString* timeString = [NSString stringWithFormat:@"%0.f", [self requireCurrentTime]];//转为字符型
    [userDefaults setValue:timeString forKey:ENTERBACKGROUNDTIME];
    [userDefaults synchronize];
}

-(NSTimeInterval) requireBackgroundTime{
    NSString *timeStr = (NSString *)[NSUserDefaults.standardUserDefaults objectForKey:ENTERBACKGROUNDTIME];
    NSTimeInterval time = (NSTimeInterval)[timeStr longLongValue];
    return time;
}


-(NSTimeInterval) requireCurrentTime{
    NSDate* time = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval timeNum=[time timeIntervalSince1970];
    return  timeNum;
}

- (void)applicationWillEnterForeground:(NSNotificationCenter *)notification
{
    MPLogInfo(@"%@ will enter foreground", self);
    NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
    
    [self judgeWakeUpOrStartAppWithSugoStatus:NO];
    
    UIWebView *uiwv = WebViewBindings.globalBindings.uiWebView;
    WKWebView *wkwv = WebViewBindings.globalBindings.wkWebView;
    if (uiwv || wkwv) {
        if (uiwv
            && uiwv.window == UIApplication.sharedApplication.keyWindow) {
            [uiwv stringByEvaluatingJavaScriptFromString:@"sugo.trackBrowseEvent();"];
        }
        if (wkwv
            && wkwv.window == UIApplication.sharedApplication.keyWindow) {
            [wkwv evaluateJavaScript:@"sugo.trackBrowseEvent();" completionHandler:nil];
        }
    } else if (values) {
        UIViewController *vc = [UIViewController sugoCurrentUIViewController];
        if (vc) {
            NSMutableDictionary *p = [[NSMutableDictionary alloc] init];
            NSDictionary *keys = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionKeys"]];
            NSDictionary *values = [NSDictionary dictionaryWithDictionary:self.sugoConfiguration[@"DimensionValues"]];
            if (keys && values) {
                p[keys[@"PagePath"]] = NSStringFromClass([vc class]);
                if ([SugoPageInfos global].infos.count > 0) {
                    for (NSDictionary *info in [SugoPageInfos global].infos) {
                        if ([info[@"page"] isEqualToString:p[keys[@"PagePath"]]]) {
                            p[keys[@"PageName"]] = info[@"page_name"];
                            if (info[@"page_category"]) {
                                p[keys[@"PageCategory"]] = info[@"page_category"];
                            }
                        }
                    }
                }
                [self trackEvent:values[@"PageEnter"] properties:p];
                [self timeEvent:values[@"PageStay"]];
            }
        }
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

- (void)checkForDecideDimensionsResponseWithCompletion:(void (^)(void))completion {
    
    [self checkForDecideDimensionsResponseWithCompletion:completion useCache:YES];
}

- (void)checkForDecideDimensionsResponseWithCompletion:(void (^)(void))completion useCache:(BOOL)useCache {
    
    dispatch_async(self.serialQueue, ^{
        // Send the network request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        
        @try {
            NSUserDefaults *uDefaults = [NSUserDefaults standardUserDefaults];
            bool isUpdateConfig = [uDefaults boolForKey:@"isUpdateConfig"];
            long latestDimensionVersion = [uDefaults integerForKey:@"latestDimensionVersion"];
            NSData *cacheDa = [uDefaults dataForKey:@"SugoEventDimensions"];
            NSMutableDictionary *cachedObj = [[NSMutableDictionary alloc] init];
            if (cacheDa) {
                NSError *caError = nil;
                cachedObj = [NSJSONSerialization JSONObjectWithData:cacheDa
                                                            options:(NSJSONReadingOptions)0
                                                              error:&caError];
                if (isUpdateConfig) {
                    NSMutableDictionary * mdic = [NSMutableDictionary dictionaryWithDictionary:cachedObj];
                    mdic[@"dimension_version"]=@(-1);
                    NSData *newData= [NSJSONSerialization dataWithJSONObject:mdic options:NSJSONWritingPrettyPrinted error:nil];
                    [uDefaults setObject:newData forKey:@"SugoEventDimensions"];
                    [uDefaults synchronize];
                }else{
                    if([cachedObj objectForKey:@"dimension_version"]){
                        long localVersion = [cachedObj[@"dimension_version"] longLongValue];
                        if (localVersion == latestDimensionVersion) {
                            [self handleDecideDimensionsObject:cachedObj];
                            if (completion) {
                                completion();
                            }
                            dispatch_semaphore_signal(semaphore);
                            return ;
                        }
                    }
                }
            }
            
        } @catch (NSException *exception) {
            NSLog(@"%@",exception);
        }
        
        __block BOOL hadError = NO;
        __block NSData *resultData = [NSData data];
        __block NSMutableDictionary *responseObject = [[NSMutableDictionary alloc] init];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSNumber *cachedVersion = @(-1);
        NSMutableDictionary *cachedObject = [[NSMutableDictionary alloc] init];
        
        if (useCache && [userDefaults dataForKey:@"SugoEventDimensions"]) {
            
            NSError *cacheError = nil;
            NSData *cachedData = [userDefaults dataForKey:@"SugoEventDimensions"];
            MPLogDebug(@"Decide dimensions cached Data\n%@", [[NSString alloc] initWithData:cachedData
                                                                      encoding:NSUTF8StringEncoding]);
            @try {
                cachedObject = [NSJSONSerialization JSONObjectWithData:cachedData
                                                              options:(NSJSONReadingOptions)0
                                                                error:&cacheError];
                cachedVersion = cachedObject[@"dimension_version"];
            } @catch (NSException *exception) {
                self.decideDimensionsResponseCached = NO;
                MPLogError(@"exception: %@, cachedData: %@, object: %@, version: %@",
                           exception,
                           cachedData,
                           cachedObject,
                           cachedVersion);
            }
        }
        
        if (!useCache || !self.decideDimensionsResponseCached) {
            // Build a proper URL from our parameters
            NSArray *queryItems = [MPNetwork buildDecideQueryForProperties:self.people.automaticPeopleProperties
                                                            withDistinctID:self.people.distinctId ?: self.distinctId
                                                              andProjectID:self.projectID
                                                                  andToken:self.apiToken
                                                    andEventBindingVersion:cachedVersion];
            // Build a network request from the URL
            NSURLRequest *request = [self.network buildGetRequestForURL:[NSURL URLWithString:self.serverURL]
                                                            andEndpoint:MPNetworkEndpointDecideDimension
                                                         withQueryItems:queryItems];
            
            
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithRequest:request completionHandler:^(NSData *responseData,
                                                                      NSURLResponse *urlResponse,
                                                                      NSError *error) {
                if (error) {
                    MPLogError(@"%@ decide check dimensions http error: %@", self, error);
                    hadError = YES;
                    dispatch_semaphore_signal(semaphore);
                    return;
                }
                MPLogDebug(@"Decide dimensions responseData\n%@", [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                
                // Handle network response
                @try {
                    responseObject = [NSJSONSerialization JSONObjectWithData:responseData options:(NSJSONReadingOptions)0 error:&error];
                    if (error) {
                        MPLogError(@"%@ decide check dimensions json error: %@, data: %@", self, error, [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                        hadError = YES;
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                    if (responseObject[@"error"]) {
                        MPLogError(@"%@ decide check dimensions api error: %@", self, responseObject[@"error"]);
                        hadError = YES;
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                    resultData = responseData;
                    self.decideDimensionsResponseCached = YES;
                    
                } @catch (NSException *exception) {
                    MPLogError(@"exception: %@, dimensions responseData: %@, object: %@",
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
        
        if (!hadError) {
            NSNumber *responseVersion = responseObject[@"dimension_version"];
            if ((cachedVersion != responseVersion)) {
                [userDefaults setObject:resultData forKey:@"SugoEventDimensions"];
                [userDefaults synchronize];
                [self handleDecideDimensionsObject:responseObject];
            } else {
                [self handleDecideDimensionsObject:cachedObject];
            }
        }
        if (completion) {
            completion();
        }
    });
}

- (void)checkForDecideBindingsResponseWithCompletion:(void (^)(NSSet *eventBindings))completion
{
    [self checkForDecideBindingsResponseWithCompletion:completion useCache:YES];
}

- (void)checkForDecideBindingsResponseWithCompletion:(void (^)(NSSet *eventBindings))completion useCache:(BOOL)useCache
{
    dispatch_async(self.serialQueue, ^{
        // Send the network request
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        @try {
            NSUserDefaults *uDefaults = [NSUserDefaults standardUserDefaults];
            bool isUpdateConfig = [uDefaults boolForKey:@"isUpdateConfig"];
            long latestEventBindingVersion = [uDefaults integerForKey:@"latestEventBindingVersion"];
            NSData *cacheDa = [uDefaults dataForKey:@"SugoEventBindings"];
            if (cacheDa) {
                NSError *caError = nil;
                NSMutableDictionary *cachedObj = [[NSMutableDictionary alloc] init];
                cachedObj = [NSJSONSerialization JSONObjectWithData:cacheDa
                                                            options:(NSJSONReadingOptions)0
                                                              error:&caError];
                if (isUpdateConfig) {
                    NSMutableDictionary * mdic = [NSMutableDictionary dictionaryWithDictionary:cachedObj];
                    mdic[@"event_bindings_version"]=@(-1);
                    NSData *newData= [NSJSONSerialization dataWithJSONObject:mdic options:NSJSONWritingPrettyPrinted error:nil];
                    [uDefaults setObject:newData forKey:@"SugoEventBindings"];
                    [uDefaults synchronize];
                }else{
                    if (cachedObj[@"event_bindings_version"]) {
                        long localVersion = [cachedObj[@"event_bindings_version"] longLongValue];
                        if (localVersion==latestEventBindingVersion) {
                            [self handleDecideDimensionsObject:cachedObj];
                            if (completion) {
                                completion(self.eventBindings);
                            }
                            dispatch_semaphore_signal(semaphore);
                            return;
                        }
                    }
                }
            }
        } @catch (NSException *exception) {
            NSLog(@"%@",exception);
        }
        __block BOOL hadError = NO;
        __block NSData *resultData = [NSData data];
        __block NSMutableDictionary *responseObject = [[NSMutableDictionary alloc] init];
        
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        NSString *cacheAppVersion = nil;
        NSString *currentAppVersion = [[NSBundle mainBundle] infoDictionary][@"CFBundleShortVersionString"];
        NSNumber *cacheVersion = @(-1);
        NSMutableDictionary *cachedObject = [[NSMutableDictionary alloc] init];
        
        if (useCache && [userDefaults dataForKey:@"SugoEventBindings"]) {
            
            cacheAppVersion = [userDefaults stringForKey:@"SugoEventBindingsAppVersion"];
            NSError *cacheError = nil;
            NSData *cachedData = [userDefaults dataForKey:@"SugoEventBindings"];
            MPLogDebug(@"Decide bindings cached Data\n%@", [[NSString alloc] initWithData:cachedData
                                                                      encoding:NSUTF8StringEncoding]);
            @try {
                cachedObject = [NSJSONSerialization JSONObjectWithData:cachedData
                                                         options:(NSJSONReadingOptions)0
                                                           error:&cacheError];
                if (cachedObject[@"event_bindings_version"] && cacheAppVersion == currentAppVersion) {
                    cacheVersion = cachedObject[@"event_bindings_version"];
                }
            } @catch (NSException *exception) {
                self.decideBindingsResponseCached = NO;
                MPLogError(@"exception: %@, bindings cacheData: %@, object: %@",
                           exception,
                           cachedData,
                           cachedObject);
            }
        }
        
        if (!useCache || !self.decideBindingsResponseCached) {
            // Build a proper URL from our parameters
            NSArray *queryItems = [MPNetwork buildDecideQueryForProperties:self.people.automaticPeopleProperties
                                                            withDistinctID:self.people.distinctId ?: self.distinctId
                                                              andProjectID:self.projectID
                                                                  andToken:self.apiToken
                                                    andEventBindingVersion:cacheVersion];
            // Build a network request from the URL
            NSURLRequest *request = [self.network buildGetRequestForURL:[NSURL URLWithString:self.serverURL]
                                                            andEndpoint:MPNetworkEndpointDecideEvent
                                                         withQueryItems:queryItems];
            
            
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
                MPLogDebug(@"Decide bindings responseData\n%@",[[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding]);
                
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
                        MPLogError(@"%@ decide bindings check api error: %@", self, responseObject[@"error"]);
                        hadError = YES;
                        dispatch_semaphore_signal(semaphore);
                        return;
                    }
                    resultData = responseData;
                    self.decideBindingsResponseCached = YES;
                    
                } @catch (NSException *exception) {
                    MPLogError(@"exception: %@, bindings responseData: %@, object: %@",
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
            if ((cacheVersion != responseVersion) || (cacheAppVersion != currentAppVersion)) {
                [userDefaults setObject:currentAppVersion forKey:@"SugoEventBindingsAppVersion"];
                [userDefaults setObject:resultData forKey:@"SugoEventBindings"];
                [userDefaults synchronize];
                [self handleDecideBindingsObject:responseObject];
            } else {
                [self handleDecideBindingsObject:cachedObject];
            }
            
            MPLogInfo(@"%@ decide bindings check found %lu tracking events, and %lu h5 tracking events",
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
    if (self.heatMap.mode) return;
    
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

- (void)handleDecideDimensionsObject:(NSDictionary *)object
{
    id dimensions = object[@"dimensions"];
    if (dimensions
        && [dimensions isKindOfClass:[NSArray class]]
        && ((NSArray *)dimensions).count > 0) {
        
        [[NSUserDefaults standardUserDefaults] setObject:dimensions
                                                  forKey:@"SugoDimensions"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        MPLogInfo(@"%@ decide check dimensions found %lu dimensions",
                  self,
                  ((NSArray *)dimensions).count);
    }
}

- (void)handleDecideBindingsObject:(NSDictionary *)object
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

#pragma mark - Sugo Codeless and Heat Map
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
    if (!self.enable) {
        return false;
        
    }
    
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
        self.urlHeatMapSecretKey = (NSString *)querys[@"sKey"];
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
    if (!self.enable) {
        return;
    }
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
    if (!self.enable) {
        return;
    }
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










