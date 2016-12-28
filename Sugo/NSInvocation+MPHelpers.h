//
// Copyright (c) 2014 Sugo. All rights reserved.

#import <Foundation/Foundation.h>

@interface NSInvocation (MPHelpers)

- (void)mp_setArgumentsFromArray:(NSArray *)argumentArray;
- (id)mp_returnValue;

@end
