//
//  WebViewBindings+WebView.h
//  Sugo
//
//  Created by Zack on 2/1/17.
//  Copyright © 2017年 sugo. All rights reserved.
//

#import "WebViewBindings.h"

@interface WebViewBindings (WebView)

- (void)excute;
- (void)stop;
- (NSString *)jsSourceOfFileName:(NSString *)fileName;

@end
