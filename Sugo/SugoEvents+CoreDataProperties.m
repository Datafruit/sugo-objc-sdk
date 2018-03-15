//
//  SugoEvents+CoreDataProperties.m
//  Sugo
//
//  Created by lzackx on 2018/3/15.
//  Copyright © 2018年 sugo. All rights reserved.
//
//

#import "SugoEvents+CoreDataProperties.h"

@implementation SugoEvents (CoreDataProperties)

+ (NSFetchRequest<SugoEvents *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"SugoEvents"];
}

@dynamic event;
@dynamic token;

@end
