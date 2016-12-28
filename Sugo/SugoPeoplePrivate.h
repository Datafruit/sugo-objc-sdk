//
//  SugoPeoplePrivate.h
//  Sugo
//
//  Created by Sam Green on 6/16/16.
//  Copyright © 2016 Sugo. All rights reserved.
//
#import <Foundation/Foundation.h>

@class Sugo;

@interface SugoPeople ()

@property (nonatomic, weak) Sugo *sugo;
@property (nonatomic, strong) NSMutableArray *unidentifiedQueue;
@property (nonatomic, copy) NSString *distinctId;
@property (nonatomic, strong) NSDictionary *automaticPeopleProperties;

- (instancetype)initWithSugo:(Sugo *)sugo;
- (void)merge:(NSDictionary *)properties;

@end
