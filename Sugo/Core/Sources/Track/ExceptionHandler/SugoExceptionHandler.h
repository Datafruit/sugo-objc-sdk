//
//  SugoExceptionHandler.h
//  HelloSugo
//
//  Created by Sam Green on 7/28/15.
//  Copyright (c) 2015 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

@class Sugo;

@interface SugoExceptionHandler : NSObject

+ (instancetype)sharedHandler;
- (void)addSugoInstance:(Sugo *)instance;

@end
