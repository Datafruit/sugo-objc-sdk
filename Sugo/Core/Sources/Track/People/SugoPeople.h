//
//  SugoPeople.h
//  Sugo
//
//  Created by Sam Green on 6/16/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/*!
 @class
 Sugo People API.

 @abstract
 Access to the Sugo People API, available as a property on the main
 Sugo API.

 @discussion
 <b>You should not instantiate this object yourself.</b> An instance of it will
 be available as a property of the main Sugo object. Calls to Sugo
 People methods will look like this:

 <pre>
 [sugo.people increment:@"App Opens" by:[NSNumber numberWithInt:1]];
 </pre>

 Please note that the core <code>Sugo</code> and
 <code>SugoPeople</code> classes share the <code>identify:</code> method.
 The <code>Sugo</code> <code>identify:</code> affects the
 <code>distinct_id</code> property of events sent by <code>track:</code> and
 <code>track:properties:</code> and determines which Sugo People user
 record will be updated by <code>set:</code>, <code>increment:</code> and other
 <code>SugoPeople</code> methods.

 <b>If you are going to set your own distinct IDs for core Sugo event
 tracking, make sure to use the same distinct IDs when using Sugo
 People</b>.
 */
@interface SugoPeople : NSObject

@end

NS_ASSUME_NONNULL_END
