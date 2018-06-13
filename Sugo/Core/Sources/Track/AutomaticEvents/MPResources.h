//
//  MPResources.h
//  Sugo
//
//  Created by Sam Green on 5/2/16.
//  Copyright © 2016 Sugo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface MPResources : NSObject

+ (UIStoryboard *)notificationStoryboard;
+ (UIStoryboard *)surveyStoryboard;
+ (UIImage *)imageNamed:(NSString *)name;

@end
