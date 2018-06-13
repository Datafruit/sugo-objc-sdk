//
//  Sugo+AutomaticEvents.h
//  HelloSugo
//
//  Created by Sam Green on 2/23/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import "Sugo.h"

@interface Sugo (AutomaticEvents)

+ (instancetype)sharedAutomatedInstance;
+ (void)setSharedAutomatedInstance:(Sugo *)instance;

@end
