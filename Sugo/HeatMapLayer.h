//
//  HeatMapLayer.h
//  Sugo
//
//  Created by Zack on 29/4/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

@interface HeatMapLayer : CALayer

- (instancetype)initWithFrame:(CGRect)frame heat:(NSDictionary *)heat;

@property (atomic, strong) NSDictionary *heat;

@end
