# sugo-objc-sdk


[![Build Status](https://travis-ci.org/Datafruit/sugo-objc-sdk.svg?branch=master)](https://travis-ci.org/Datafruit/sugo-objc-sdk)
[![CocoaPods Compatible](http://img.shields.io/cocoapods/v/sugo-objc-sdk.svg)](https://cocoapods.org/pods/sugo-objc-sdk)
[![Platform](https://img.shields.io/badge/Platform-iOS%208.0+-66CCFF.svg)](https://cocoapods.org/pods/sugo-objc-sdk)
[![GitHub license](https://img.shields.io/badge/license-Apache%202-blue.svg)](https://raw.githubusercontent.com/Datafruit/sugo-objc-sdk/master/LICENSE)
[![GitHub issues](https://img.shields.io/github/issues/Datafruit/sugo-objc-sdk.svg)](https://github.com/Datafruit/sugo-objc-sdk/issues)
[![GitHub stars](https://img.shields.io/github/stars/Datafruit/sugo-objc-sdk.svg)](https://github.com/Datafruit/sugo-objc-sdk/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/Datafruit/sugo-objc-sdk.svg)](https://github.com/Datafruit/sugo-objc-sdk/network)

## 介绍

欢迎集成使用由sugo.io提供的iOS端Objective-C版采集并分析用户行为。

`sugo-objc-sdk`是一个开源项目，我们很期待能收到各界的代码贡献。

## 1. 集成

### 1.1 CocoaPods

**现时我们的发布版本只能通过Cocoapods 1.1.0及以上的版本进行集成**

通过[CocoaPods](https://cocoapods.org)，可方便地在项目中集成此SDK。

#### 1.1.1 配置`Podfile`

请在项目根目录下的`Podfile`
（如无，请创建或从我们提供的SugoDemo目录中[获取](https://github.com/Datafruit/sugo-objc-sdk/blob/master/SugoDemo/Podfile)并作出相应修改）文件中添加以下字符串：

```
pod 'sugo-objc-sdk'
```

若需要支持**Weex**的可视化埋点功能，请**替代**使用

```
pod 'sugo-objc-sdk/weex'
```


#### 1.1.2 执行集成命令

关闭Xcode，并在`Podfile`目录下执行以下命令：

```
pod install
```

#### 1.1.3 完成

运行完毕后，打开集成后的`xcworkspace`文件即可。

### 1.2 手动安装

为了帮助开发者集成最新且稳定的SDK，我们建议通过Cocoapods来集成，这不仅简单而且易于管理。
然而，为了方便其他集成状况，我们也提供手动安装此SDK的方法。

#### 1.2.1 以子模块的形式添加
以子模块的形式把`sugo-objc-sdk`添加进本地仓库中:

```
git submodule add git@github.com:Datafruit/sugo-objc-sdk.git
```

现在在仓库中能看见Sugo项目文件`Sugo.xcodeproj`了。

#### 1.2.2 把`Sugo.xcodeproj`拖到你的项目（或工作空间）中

把`Sugo.xcodeproj`拖到需要被集成使用的项目文件中。

#### 1.2.3 嵌入框架（Embed the framework）

选择需要被集成此SDK的项目target，把`Sugo.framework`以embeded binary形式添加进去。

## 2. SDK的基础调用

### 2.1 获取SDK配置信息

登陆数果星盘后，可在平台界面中创建项目和数据接入方式，创建数据接入方式时，即可获得项目ID与Token。

### 2.2 配置并获取SDK对象

#### 2.2.1 添加头文件

在集成了SDK的项目中，打开`AppDelegate.m`，在文件头部添加：

```
@import Sugo;
```

若使用支持**Weex**可视化埋点功能的SDK时，出现问题，可替代使用：

```
#import "Sugo.h"
#import "Sugo+Weex.h"
```


#### 2.2.2 添加SDK对象初始化代码

把以下代码复制到`AppDelegate.m`中，并填入已获得的项目ID与Token：

```
- (void)initSugo {
	NSString *projectID = @"Add_Your_Project_ID_Here";
	NSString *appToken = @"Add_Your_App_Token_Here";
	[Sugo sharedInstanceWithID:projectID token:appToken launchOptions:nil];
	[[Sugo sharedInstance] setEnableLogging:YES];	// 如果需要查看SDK的Log，请设置为true
	[[Sugo sharedInstance] setFlushInterval:5]; 	// 被绑定的事件数据往服务端上传的时间间隔，单位是秒，如若不设置，默认时间是60秒
	[[Sugo sharedInstance] setCacheInterval:60]; 	// 从服务端拉取绑定事件配置的时间间隔，单位是秒，如若不设置，默认时间是1小时
    // [[Sugo sharedInstance] registerModule];		// 需要支持Weex可视化埋点时调用
}
```

#### 2.2.3 调用SDK对象初始化代码
添加`initSugo`后，在`AppDelegate`方法中调用，如下：

```
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
	// Override point for customization after application launch.
	[self initSugo];	//调用 `initSugo`
	return YES;
}
```

### 2.3 扫码进入可视化埋点模式

#### 2.3.1 通过扫码App进行扫码

##### 2.3.1.1 配置App的URL Types

在Xcode中，点击App的`xcodeproj`文件，进入`info`便签页，添加`URL Types`。

* Identifier: Sugo
* URL Schemes: sugo.*	(“*”位置替换成Token)
* Icon: (可随意)
* Role: Editor

##### 2.3.1.2 选择被调用的API

`UIApplicationDelegate`中有3个可通过URL打开应用的方法，如下：

* `- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options;`
* `- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation;`
* `- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url;`

请根据应用需适配的版本在`AppDelegate.m`中实现其中一个或多个方法。

##### 2.3.1.3 可视化埋点模式API

在选定的方法中调用如下：

```
[[Sugo sharedInstance] handleURL:url];	//返回值为BOOL类型，可作为方法的返回值。
```

##### 2.3.1.4 连接

登陆数果星盘，进入对应Token的可视化埋点界面，可看见二维码，保持埋点设备网络畅通，通过设备任意可扫二维码的应用扫一扫，然后用Safari打开链接，点击网页中的链接，即可进入可视化埋点模式。
此时设备上方将出现可视化埋点连接条，网页可视化埋点界面将显示设备当前页面及相应可绑定控件信息。

#### 2.3.2 通过自身应用进行扫码

若集成SDK的应用已把扫码功能开发完毕，也可通过自身的扫码功能进行可视化埋点模式的连接。即在扫码后，将已获取的URL作为参数，调用以下的方法：

* `- (void)connectToCodelessViaURL:(NSURL *)url;`

该方法会对应用Token进行检验，若Token与初始化的值匹配，且已打开可视化埋点网页，则设备上方将出现可视化埋点连接条，网页可视化埋点界面将显示设备当前页面及相应可绑定控件信息，示例如下：

```
[[Sugo sharedInstance] connectToCodelessViaURL:url];	// url参数为扫描二维码后获得的值
```

### 2.4 绑定事件

#### 2.4.1 原生控件

**对于所有`UIView`，都有一个`NSString`类型的`sugoViewId`属性，可以用于唯一指定容易混淆的可视化埋点视图，推荐初始化时设置使用**

可以通过如下方式设置：

```
// #import <objc/runtime.h>
objc_setAssociatedObject(self, @selector(sugoViewId), @"CustomNSStringValue", OBJC_ASSOCIATION_RETAIN_NONATOMIC);
```

##### UIView

满足以下条件的`UIView`及其子类可以被可视化埋点绑定事件：

* `userInteractionEnabled`属性为`YES`，且是`UIControl`或其子类
* `userInteractionEnabled`属性为`YES`，且`gestureRecognizers`数组属性中包含`UITapGestureRecognizer`或其子类的手势实例，且其`enabled`属性为`YES`

##### UITableView

所有`UITableView`类及其子类，需要指定其`delegate`属性，并实现以下方法，方可被埋点绑定事件。基于`UITableView`运行原理的特殊性，埋点绑定事件的时候只需要整个圈选，SDK会自动上报`UITableView`被选中的详细位置信息。

```
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath;
```

##### UICollectionView

所有`UICollectionView`类及其子类，需要指定其`delegate`属性，并实现以下方法，方可被埋点绑定事件。基于`UICollectionView`运行原理的特殊性，埋点绑定事件的时候只需要整个圈选，SDK会自动上报`UICollectionView`被选中的详细位置信息。

```
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
```

#### 2.4.2 UIWebView

所有`UIWebView`类及其子类下的网页元素，需要指定其`delegate`属性，且在`delegate`指定类中实现以下指定的方法:

* `- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType`
* `- (void)webViewDidStartLoad:(UIWebView *)webView;`
* `- (void)webViewDidFinishLoad:(UIWebView *)webView;`

#### 2.4.3 WKWebView

所有`WKWebView`类及其子类下的网页元素，皆可被埋点绑定事件。

## 3. SDK的进阶调用

### 3.1 获取全局对象

通过单例模式获取全局可用的对象，如下：

```
Sugo *sugo = [Sugo sharedInstance];
```

### 3.2 手动埋点

#### 3.2.1 代码埋点

当需要把自定义事件发送到服务器时，可在相应位置调用以下API

* `- (void)trackEvent:(NSString *)event;`
* `- (void)trackEvent:(NSString *)event properties:(nullable NSDictionary *)properties;`
* `- (void)trackEventID:(nullable NSString *)eventID eventName:(NSString *)eventName;`
* `- (void)trackEventID:(nullable NSString *)eventID eventName:(NSString *)eventName properties:(nullable NSDictionary *)properties;`

示例如下(根据使用需求调用)：

```
[[Sugo sharedInstance] trackEvent:@"EventName"];
[[Sugo sharedInstance] trackEvent:@"EventName" properties:@{ @"key1": @"value1", @"key2": @"value2"}];
[[Sugo sharedInstance] trackEventID:@"EventId" eventName:@"EventName"];	//eventId可为空
[[Sugo sharedInstance] trackEventID:@"EventId" eventName:@"EventName" properties:@{ @"key1": @"value2", @"key2": @"value2"}];	//eventId可为空
```

#### 3.2.2 时长统计

##### 3.2.2.1 创建

当需要对时间进行跟踪统计时，可在开始跟踪的位置调用

* `- (void)timeEvent:(NSString *)event`

示例如下：

```
[[Sugo sharedInstance] timeEvent:@"TimeEventName"];
```

##### 3.2.2.2 发送

然后，在完成跟踪的位置调用`3.2.1`中的方法即可，需要注意的是`eventName`需要与开始时的一样，示例如下：

```
[[Sugo sharedInstance] trackEvent:@"TimeEventName"];
```

##### 3.2.2.3 更新

如果在创建时间跟踪后，在发送前想要更新，再次以相同的时间事件名调用创建时的API即可，SDK会把相同事件名的记录时间进行刷新。

##### 3.2.2.4 删除

如果希望清除所有时间跟踪事件，可以通过调用

* `- (void)clearTimedEvents;`

示例如下：

```
[[Sugo sharedInstance] clearTimedEvents];
```

#### 3.2.3 全局属性

##### 3.2.3.1 注册

当每一个事件都需要记录相同的属性时，可以选择使用全局属性(全局属性仅允许`NSString`类型作为key值，value值则允许`NSString`、`NSNumber`、`NSArray`、`NSDictionary`、`NSDate`、`NSURL`这些类型)，
通过调用

* `- (void)registerSuperPropertiesOnce:(NSDictionary *)properties;`
* `- (void)registerSuperProperties:(NSDictionary *)properties;`

示例如下：

```
[[Sugo sharedInstance] registerSuperPropertiesOnce:@{ @"key1": @"value2", @"key2": @"value2"}]; // 此方法不会覆盖当前已有的全局属性
[[Sugo sharedInstance] registerSuperProperties:@{ @"key1": @"value2", @"key2": @"value2"}]; // 此方法会覆盖当前已有的全局属性
```

##### 3.2.3.2 获取

当需要获取已注册的全局属性时，可以调用

* `- (NSDictionary *)currentSuperProperties;`

示例如下：

```
[[Sugo sharedInstance] currentSuperProperties];
```

##### 3.2.3.3 注销

当需要注销某一全局属性时，可以调用

* `- (void)unregisterSuperProperty:(NSString *)propertyName;`

示例如下：

```
[[Sugo sharedInstance] unregisterSuperProperty:@"SuperPropertyName"];
```

##### 3.2.3.4 清除

当需要清除所有全局属性时，可以调用

* `- (void)clearSuperProperties;`

示例如下：

```
[[Sugo sharedInstance] clearSuperProperties];
```

#### 3.2.3.5 跟踪用户首次登录

当需要跟踪用户首次登录用户账户时，可调用

* `- (void)trackFirstLoginWith:(nullable NSString *)identifer dimension:(nullable NSString *)dimension;`

示例如下(其中`dimension`参数为用户已自定义的维度名)：

```
[[Sugo sharedInstance] trackFirstLoginWith:@"user_id" dimension: @"user_id_dimension"]; 
```

#### 3.2.4 WebView埋点

当需要在WebView(UIWebView或WKWebView)中进行代码埋点时，在页面加载完毕后，可调用以下API(是`3.2.1`与`3.2.2`同名方法在JavaScript中的接口，实现机制相同)进行JavaScript内容的代码埋点

```
sugo.track(event_id, event_name, props);	// 准备把自定义事件发送到服务器时
sugo.timeEvent(event_name);					// 在开始统计时长的时候调用
```

#### 3.2.5 Weex埋点

当需要在Weex(Vue)中进行代码埋点时，可调用以下API(是`3.2.1`与`3.2.2`同名方法在Weex中的接口，实现机制相同)进行JavaScript的代码埋点

```
let sugo = weex.requireModule('sugo');
sugo.track(event_name, props);				// 准备把自定义事件发送到服务器时
sugo.timeEvent(event_name);					// 在开始统计时长的时候调用
```

## 4. 反馈

已经成功集成了此SDK了，想了解SDK的最新动态, 请`Star` 或 `Watch` 我们的仓库： [Github](https://github.com/Datafruit/sugo-objc-sdk.git)。

有问题解决不了? 发送邮件到 [developer@sugo.io](developer@sugo.io) 或提出详细的issue，我们的进步，离不开各界的反馈。
