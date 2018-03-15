//
//  SugoEvents+CoreDataProperties.h
//  Sugo
//
//  Created by lzackx on 2018/3/15.
//  Copyright © 2018年 sugo. All rights reserved.
//
//

#import "SugoEvents+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface SugoEvents (CoreDataProperties)

+ (NSFetchRequest<SugoEvents *> *)fetchRequest;

@property (nullable, nonatomic, retain) NSData *event;
@property (nullable, nonatomic, copy) NSString *token;

@end

NS_ASSUME_NONNULL_END
