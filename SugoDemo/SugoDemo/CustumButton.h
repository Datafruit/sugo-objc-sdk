//
//  CustumButton.h
//  SugoDemo
//
//  Created by 陈宇艺 on 2019/1/11.
//  Copyright © 2019 sugo. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CustumButton : UIButton
@property(nonatomic,copy)NSString *buttonTag;
@property(nonatomic,assign)NSInteger buttonNum;
@property(nonatomic,assign)BOOL isBoolText;



-(void)buildButtonPrivateAttr:(NSString *)text;
@end




NS_ASSUME_NONNULL_END
