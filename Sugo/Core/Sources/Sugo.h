//
//  Sugo.h
//  Sugo
//
//  Created by Zack on 28/12/16.
//  Copyright © 2016年 sugo. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for Sugo.
FOUNDATION_EXPORT double SugoVersionNumber;

//! Project version string for Sugo.
FOUNDATION_EXPORT const unsigned char SugoVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Sugo/PublicHeader.h>


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "SugoPeople.h"


@class    SugoPeople;
@protocol SugoDelegate;

NS_ASSUME_NONNULL_BEGIN

extern NSString *SugoBindingsURL;
extern NSString *SugoCollectionURL;
extern NSString *SugoCodelessURL;
extern BOOL SugoCanTrackNativePage;
extern BOOL SugoCanTrackWebPage;

/*!
 @class
 Sugo API.
 
 @abstract
 The primary interface for integrating Sugo with your app.
 
 @discussion
 Use the Sugo class to set up your project and track events in Sugo
 Engagement. It now also includes a <code>people</code> property for accessing
 the Sugo People API.
 
 <pre>
 // Initialize the API
 Sugo *sugo = [Sugo sharedInstanceWithToken:@"YOUR API TOKEN"];
 
 // Track an event in Sugo Engagement
 [sugo trackEvent:@"Button Clicked"];
 
 // Set properties on a user in Sugo People
 [sugo identify:@"CURRENT USER DISTINCT ID"];
 [sugo.people set:@"Plan" to:@"Premium"];
 </pre>
 
 For more advanced usage, please see the <a
 href="https://sugo.com/docs/integration-libraries/iphone">Sugo iPhone
 Library Guide</a>.
 */
@interface Sugo : NSObject

#pragma mark Properties

/*!
 @property
 
 @abstract
 Accessor to the Sugo People API object.
 
 @discussion
 See the documentation for SugoDelegate below for more information.
 */
@property (atomic, readonly, strong) SugoPeople *people;

/*!
 @property
 
 @abstract
 The distinct ID of the current user.
 
 @discussion
 A distinct ID is a string that uniquely identifies one of your users.
 Typically, this is the user ID from your database. By default, we'll use
 the device's advertisingIdentifier UUIDString, if that is not available
 we'll use the device's identifierForVendor UUIDString, and finally if that
 is not available we will generate a new random UUIDString. To change the
 current distinct ID, use the <code>identify:</code> method.
 */
@property (atomic, readonly, copy) NSString *deviceId;

@property (atomic, readonly, copy) NSString *distinctId;

/*!
 @property
 
 @abstract
 The base URL used for Sugo API requests.
 
 @discussion
 Useful if you need to proxy Sugo requests.
 */
@property (nonatomic, copy) NSString *serverURL;

/*!
 @property
 
 @abstract
 The base URL used for Sugo events collection.
 
 @discussion
 Useful if you need to proxy Sugo requests.
 */
@property (nonatomic, copy) NSString *eventCollectionURL;

/*!
 @property
 
 @abstract
 The base URL used for Sugo codeless bindings.
 
 @discussion
 Useful if you need to proxy Sugo requests.
 */
@property (nonatomic, copy) NSString *switchboardURL;

/*!
 @property
 
 @abstract
 The project ID used for Sugo API requests.
 */
@property (nonatomic, copy) NSString *projectID;

/*!
 @property
 
 @abstract
 Flush timer's interval.
 
 @discussion
 Setting a flush interval of 0 will turn off the flush timer.
 */
@property (atomic) NSUInteger flushInterval;

/*!
 @property
 
 @abstract
 Cache interval.
 
 @discussion
 Setting a cache interval, default to 3600.
 */
@property (atomic) double cacheInterval;

/*!
 @property
 
 @abstract
 Control whether the library should flush data to Sugo when the app
 enters the background.
 
 @discussion
 Defaults to YES. Only affects apps targeted at iOS 4.0, when background
 task support was introduced, and later.
 */
@property (atomic) BOOL flushOnBackground;

/*!
 @property
 
 @abstract
 Controls whether to show spinning network activity indicator when flushing
 data to the Sugo servers.
 
 @discussion
 Defaults to YES.
 */
@property (atomic) BOOL shouldManageNetworkActivityIndicator;

/*!
 @property
 
 @abstract
 Controls whether to automatically send the client IP Address as part of
 event tracking. With an IP address, geo-location is possible down to neighborhoods
 within a city, although the Sugo Dashboard will just show you city level location
 specificity. For privacy reasons, you may be in a situation where you need to forego
 effectively having access to such granular location information via the IP Address.
 
 @discussion
 Defaults to YES.
 */
@property (atomic) BOOL useIPAddressForGeoLocation;

/*!
 @property
 
 @abstract
 Controls whether to enable the visual test designer for A/B testing and codeless on sugo.com.
 You will be unable to edit A/B tests and codeless events with this disabled, however *previously*
 created A/B tests and codeless events will still be delivered.
 
 @discussion
 Defaults to YES.
 */
@property (atomic) BOOL enableVisualABTestAndCodeless;

/*!
 @property
 
 @abstract
 Controls whether to enable the run time debug logging at all levels. Note that the
 Sugo SDK uses Apple System Logging to forward log messages to `STDERR`, this also
 means that sugo logs are segmented by log level. Settings this to `YES` will enable
 Sugo logging at the following levels:
 
 * Error - Something has failed
 * Warning - Something is amiss and might fail if not corrected
 * Info - The lowest priority that is normally logged, purely informational in nature
 * Debug - Information useful only to developers, and normally not logged.
 
 
 @discussion
 Defaults to NO.
 */
@property (atomic) BOOL enableLogging;

/*!
 @property
 
 @abstract
 Determines the time, in seconds, that a mini notification will remain on
 the screen before automatically hiding itself.
 
 @discussion
 Defaults to 6.0.
 */
@property (atomic) CGFloat miniNotificationPresentationTime;

/*!
 @property
 
 @abstract
 If set, determines the background color of mini notifications.
 
 @discussion
 If this isn't set, we default to either the color of the UINavigationBar of the top
 UINavigationController that is showing when the notification is presented, the
 UINavigationBar default color for the app or the UITabBar default color.
 */
@property (atomic, strong, nullable) UIColor *miniNotificationBackgroundColor;

/*!
 @property
 
 @abstract
 The a SugoDelegate object that can be used to assert fine-grain control
 over Sugo network activity.
 
 @discussion
 Using a delegate is optional. See the documentation for SugoDelegate
 below for more information.
 */
@property (atomic, weak) id<SugoDelegate> delegate; // allows fine grain control over uploading (optional)

#pragma mark Tracking

/*!
 @method
 
 @abstract
 Register an immutable NSDictionary with highest priority before object initialized.
 
 @discussion
 The API must be called before initializer.
 
 @param priorityProperties  highest priority properties
 */
+ (void)registerPriorityProperties:(NSDictionary *)priorityProperties;

/*!
 @method
 
 @abstract
 Returns (and creates, if needed) a singleton instance of the API.
 
 @discussion
 This method will return a singleton instance of the <code>Sugo</code> class for
 you using the given project token. If an instance does not exist, this method will create
 one using <code>sharedInstanceWithID:launchOptions:andFlushInterval:andCacheInterval:</code>. If you only have one
 instance in your project, you can use <code>sharedInstance</code> to retrieve it.
 
 <pre>
 [Sugo sharedInstance] trackEvent:@"Something Happened"]];
 </pre>
 
 If you are going to use this singleton approach,
 <code>sharedInstanceWithToken:</code> <b>must be the first call</b> to the
 <code>Sugo</code> class, since it performs important initializations to
 the API.
 
 @param projectID       your project id
 @param apiToken        your project token
 */
+ (Sugo *)sharedInstanceWithID:(NSString *)projectID token:(NSString *)apiToken;

/*!
 @method
 
 @abstract
 Initializes a singleton instance of the API, uses it to track launchOptions information,
 and then returns it.
 
 @discussion
 This is the preferred method for creating a sharedInstance with a sugo
 like above. With the launchOptions parameter, Sugo can track referral
 information created by push notifications.
 
 @param projectID       your project id
 @param apiToken        your project token
 @param launchOptions   your application delegate's launchOptions
 
 */
+ (Sugo *)sharedInstanceWithID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions;

/*!
 @method
 
 @abstract
 Initializes a singleton instance of the API, uses it to track launchOptions information,
 and then returns it.
 
 @discussion
 This is the preferred method for creating a sharedInstance with a sugo
 like above. With the launchOptions parameter, Sugo can track referral
 information created by push notifications.
 
 @param enable          whether enable SDK
 @param projectID       your project id
 @param apiToken        your project token
 @param launchOptions   your application delegate's launchOptions
 
 */
+ (Sugo *)sharedInstanceWithEnable:(BOOL)enable projectID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions;
/*!
 @method
 
 @abstract
 Returns a previously instantiated singleton instance of the API.
 
 @discussion
 The API must be initialized with initializer before calling this class method.
 This method will return <code>nil</code> if there are no instances created. If there is more than
 one instace, it will return the first one that was created by using initializer.
 */
+ (Sugo *)sharedInstance;

/*!
 @method
 
 @abstract
 Initializes an instance of the API with the given project token.
 
 @discussion
 Creates and initializes a new API object. See also initializer.
 
 @param projectID       your project ID
 @param apiToken        your project token
 @param launchOptions   optional app delegate launchOptions
 @param flushInterval   interval to run background flushing
 @param cacheInterval   interval to cache event data
 */
- (instancetype)initWithID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions andFlushInterval:(NSUInteger)flushInterval  andCacheInterval:(double)cacheInterval;

/*!
 @method
 
 @abstract
 Initializes an instance of the API with the given project token.
 
 @discussion
 Creates and initializes a new API object. See also initializer.
 
 @param enable          whether enable SDK
 @param projectID       your project ID
 @param apiToken        your project token
 @param launchOptions   optional app delegate launchOptions
 @param flushInterval   interval to run background flushing
 @param cacheInterval   interval to cache event data
 */
- (instancetype)initWithEnable:(BOOL)enable projectID:(NSString *)projectID token:(NSString *)apiToken launchOptions:(nullable NSDictionary *)launchOptions andFlushInterval:(NSUInteger)flushInterval  andCacheInterval:(double)cacheInterval;

/*!
 @method
 
 @abstract
 Initializes an instance of the API with the given project token.
 
 @discussion
 Supports for the old initWithToken method format but really just passes
 launchOptions to the above method as nil.
 
 @param projectID       your project ID
 @param apiToken        your project token
 @param flushInterval   interval to run background flushing
 @param cacheInterval   interval to cache event data
 */
- (instancetype)initWithID:(NSString *)projectID token:(NSString *)apiToken andFlushInterval:(NSUInteger)flushInterval  andCacheInterval:(double)cacheInterval;

/*!
 @property
 
 @abstract
 Sets the distinct ID of the current user.
 
 @discussion
 As of version 2.3.1, Sugo will choose a default distinct ID based on
 whether you are using the AdSupport.framework or not.
 
 If you are not using the AdSupport Framework (iAds), then we use the
 <code>[UIDevice currentDevice].identifierForVendor</code> (IFV) string as the
 default distinct ID.  This ID will identify a user across all apps by the same
 vendor, but cannot be used to link the same user across apps from different
 vendors.
 
 If you are showing iAds in your application, you are allowed use the iOS ID
 for Advertising (IFA) to identify users. If you have this framework in your
 app, Sugo will use the IFA as the default distinct ID. If you have
 AdSupport installed but still don't want to use the IFA, you can define the
 <code>SUGO_NO_IFA</code> preprocessor flag in your build settings, and
 Sugo will use the IFV as the default distinct ID.
 
 If we are unable to get an IFA or IFV, we will fall back to generating a
 random persistent UUID.
 
 For tracking events, you do not need to call <code>identify:</code> if you
 want to use the default.  However, <b>Sugo People always requires an
 explicit call to <code>identify:</code></b>. If calls are made to
 <code>set:</code>, <code>increment</code> or other <code>SugoPeople</code>
 methods prior to calling <code>identify:</code>, then they are queued up and
 flushed once <code>identify:</code> is called.
 
 If you'd like to use the default distinct ID for Sugo People as well
 (recommended), call <code>identify:</code> using the current distinct ID:
 <code>[sugo identify:sugo.distinctId]</code>.
 
 @param distinctId string that uniquely identifies the current user
 */
- (void)identify:(NSString *)distinctId;

/*!
 @method
 
 @abstract
 Tracks an event.
 
 @param event       event name
 */
- (void)trackEvent:(NSString *)event;

/*!
 @method
 
 @abstract
 Tracks an event.
 
 @param event       event name
 @param properties      properties dictionary
 */
- (void)trackEvent:(NSString *)event properties:(nullable NSDictionary *)properties;

/*!
 @method
 
 @abstract
 Tracks an event.
 
 @param eventID         event ID
 @param eventName       event name
 */
- (void)trackEventID:(nullable NSString *)eventID eventName:(NSString *)eventName;

/*!
 @method
 
 @abstract
 Tracks an event with properties.
 
 @discussion
 Properties will allow you to segment your events in your Sugo reports.
 Property keys must be <code>NSString</code> objects and values must be
 <code>NSString</code>, <code>NSNumber</code>, <code>NSNull</code>,
 <code>NSArray</code>, <code>NSDictionary</code>, <code>NSDate</code> or
 <code>NSURL</code> objects. If the event is being timed, the timer will
 stop and be added as a property.
 
 @param eventID         event ID
 @param eventName       event name
 @param properties      properties dictionary
 */
- (void)trackEventID:(nullable NSString *)eventID eventName:(NSString *)eventName properties:(nullable NSDictionary *)properties;

/*!
 @method
 
 @abstract
 Registers super properties, overwriting ones that have already been set.
 
 @discussion
 Super properties, once registered, are automatically sent as properties for
 all event tracking calls. They save you having to maintain and add a common
 set of properties to your events. Property keys must be <code>NSString</code>
 objects and values must be <code>NSString</code>, <code>NSNumber</code>,
 <code>NSNull</code>, <code>NSArray</code>, <code>NSDictionary</code>,
 <code>NSDate</code> or <code>NSURL</code> objects.
 
 @param properties      properties dictionary
 */
- (void)registerSuperProperties:(NSDictionary *)properties;

/*!
 @method
 
 @abstract
 Registers super properties without overwriting ones that have already been
 set.
 
 @discussion
 Property keys must be <code>NSString</code> objects and values must be
 <code>NSString</code>, <code>NSNumber</code>, <code>NSNull</code>,
 <code>NSArray</code>, <code>NSDictionary</code>, <code>NSDate</code> or
 <code>NSURL</code> objects.
 
 @param properties      properties dictionary
 */
- (void)registerSuperPropertiesOnce:(NSDictionary *)properties;

/*!
 @method
 
 @abstract
 Registers super properties without overwriting ones that have already been set
 unless the existing value is equal to defaultValue.
 
 @discussion
 Property keys must be <code>NSString</code> objects and values must be
 <code>NSString</code>, <code>NSNumber</code>, <code>NSNull</code>,
 <code>NSArray</code>, <code>NSDictionary</code>, <code>NSDate</code> or
 <code>NSURL</code> objects.
 
 @param properties      properties dictionary
 @param defaultValue    overwrite existing properties that have this value
 */
- (void)registerSuperPropertiesOnce:(NSDictionary *)properties defaultValue:(nullable id)defaultValue;

/*!
 @method
 
 @abstract
 Removes a previously registered super property.
 
 @discussion
 As an alternative to clearing all properties, unregistering specific super
 properties prevents them from being recorded on future events. This operation
 does not affect the value of other super properties. Any property name that is
 not registered is ignored.
 
 Note that after removing a super property, events will show the attribute as
 having the value <code>undefined</code> in Sugo until a new value is
 registered.
 
 @param propertyName   array of property name strings to remove
 */
- (void)unregisterSuperProperty:(NSString *)propertyName;

/*!
 @method
 
 @abstract
 Clears all currently set super properties.
 */
- (void)clearSuperProperties;

/*!
 @method
 
 @abstract
 Returns the currently set super properties.
 */
- (NSDictionary *)currentSuperProperties;

/*!
 @method
 
 @abstract
 Starts a timer that will be stopped and added as a property when a
 corresponding event is tracked.
 
 @discussion
 This method is intended to be used in advance of events that have
 a duration. For example, if a developer were to track an "Image Upload" event
 she might want to also know how long the upload took. Calling this method
 before the upload code would implicitly cause the <code>track</code>
 call to record its duration.
 
 <pre>
 // begin timing the image upload
 [sugo timeEvent:@"Image Upload"];
 
 // upload the image
 [self uploadImageWithSuccessHandler:^{
 
 // track the event
 [sugo trackEvent:@"Image Upload"];
 }];
 </pre>
 
 @param event   a string, identical to the name of the event that will be tracked
 
 */
- (void)timeEvent:(NSString *)event;

/*!
 @method
 
 @abstract
 Clears all current event timers.
 */
- (void)clearTimedEvents;

/*!
 @method
 
 @abstract
 Clears all stored properties and distinct IDs. Useful if your app's user logs out.
 */
- (void)reset;

/*!
 @method
 
 @abstract
 fetch event binding data from the Sugo server.
 
 @discussion
 By default, event binding data is cache from the Sugo servers every hour (the
 default for <code>cacheInterval</code>). You only need to call this
 method manually if you want to force a cache at a particular moment.
 */
- (void)cache;

/*!
 @method
 
 @abstract
 Uploads queued data to the Sugo server.
 
 @discussion
 By default, queued data is flushed to the Sugo servers every minute (the
 default for <code>flushInterval</code>), and on background (since
 <code>flushOnBackground</code> is on by default). You only need to call this
 method manually if you want to force a flush at a particular moment.
 */
- (void)flush;

/*!
 @method
 
 @abstract
 Calls flush, then optionally archives and calls a handler when finished.
 
 @discussion
 When calling <code>flush</code> manually, it is sometimes important to verify
 that the flush has finished before further action is taken. This is
 especially important when the app is in the background and could be suspended
 at any time if protocol is not followed. Delegate methods like
 <code>application:didReceiveRemoteNotification:fetchCompletionHandler:</code>
 are called when an app is brought to the background and require a handler to
 be called when it finishes.
 */
- (void)flushWithCompletion:(nullable void (^)())handler;

- (void)trackFirstLoginWith:(nullable NSString *)identifer dimension:(nullable NSString *)dimension;

- (void)untrackFirstLogin;

- (void)updateSessionId:(NSString *)sessionId;

/*!
 @method
 
 @abstract
 Writes current project info, including distinct ID, super properties and pending event
 and People record queues to disk.
 
 @discussion
 This state will be recovered when the app is launched again if the Sugo
 library is initialized with the same project token. <b>You do not need to call
 this method</b>. The library listens for app state changes and handles
 persisting data as needed. It can be useful in some special circumstances,
 though, for example, if you'd like to track app crashes from main.m.
 */
- (void)archive;

/*!
 @method
 
 @abstract
 Creates a distinct_id alias from alias to original id.
 
 @discussion
 This method is used to map an identifier called an alias to the existing Sugo
 distinct id. This causes all events and people requests sent with the alias to be
 mapped back to the original distinct id. The recommended usage pattern is to call
 both createAlias: and identify: when the user signs up, and only identify: (with
 their new user ID) when they log in. This will keep your signup funnels working
 correctly.
 
 <pre>
 // This makes the current ID (an auto-generated GUID)
 // and 'Alias' interchangeable distinct ids.
 [sugo createAlias:@"Alias"
 forDistinctID:sugo.distinctId];
 
 // You must call identify if you haven't already
 // (e.g., when your app launches).
 [sugo identify:sugo.distinctId];
 </pre>
 
 @param alias 		the new distinct_id that should represent original
 @param distinctID 	the old distinct_id that alias will be mapped to
 */
- (void)createAlias:(NSString *)alias forDistinctID:(NSString *)distinctID;

- (NSString *)libVersion;
+ (NSString *)libVersion;

#pragma mark - Sugo Codeless and Heat Map

/*!
 @method
 
 @abstract
 Connect to web socket for codeless designer
 
 @discussion
 Default to No retry.
 */
- (void)connectToABTestDesigner;

/*!
 @method
 
 @abstract
 Handle the url delivered from UIApplicationDelegate.
 
 @param url             url scheme
 */
- (BOOL)handleURL:(NSURL *)url;

/*!
 @method
 
 @abstract
 Handle the url get from codeless qrcode
 
 @param url             url of codeless qrcode
 */
- (void)connectToCodelessViaURL:(NSURL *)url;

/*!
 @method
 
 @abstract
 Handle the url get from heat map qrcode
 
 @param url             url of heat map qrcode
 */
- (void)requestForHeatMapViaURL:(NSURL *)url;

#pragma mark - Deprecated
/*!
 @property
 
 @abstract
 Current user's name in Sugo Streams.
 */
@property (nullable, atomic, copy) NSString *nameTag __deprecated; // Deprecated in v3.0.1

@end

/*!
 @protocol
 
 @abstract
 Delegate protocol for controlling the Sugo API's network behavior.
 
 @discussion
 Creating a delegate for the Sugo object is entirely optional. It is only
 necessary when you want full control over when data is uploaded to the server,
 beyond simply calling stop: and start: before and after a particular block of
 your code.
 */

@protocol SugoDelegate <NSObject>

@optional
/*!
 @method
 
 @abstract
 Asks the delegate if data should be uploaded to the server.
 
 @discussion
 Return YES to upload now, NO to defer until later.
 
 @param sugo        Sugo API instance
 */
- (BOOL)sugoWillFlush:(Sugo *)sugo;

@end

NS_ASSUME_NONNULL_END
