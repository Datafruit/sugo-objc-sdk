//
//  ExceptionUtils.h
//  Sugo
//
//  Created by 陈宇艺 on 2019/6/9.
//  Copyright © 2019 sugo. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface ExceptionUtils : NSObject
+(void)exceptionToNetWork:(NSException *)exception;
+(void)buildTokenId:(NSString *)tId projectId:(NSString *)pId;
@end

NS_ASSUME_NONNULL_END
