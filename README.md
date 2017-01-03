# sugo-objc-sdk


把Sugo目录下的所有源码放到项目中,在`AppDelegate.m`中把获得的项目ID和AppToken填上，并初始化，事例如下：

```
	NSString *projectID = @"Add_Your_Project_ID_Here";
    NSString *appToken = @"Add_Your_App_Token_Here";
    [Sugo sharedInstanceWithID:projectID token:appToken launchOptions:nil];
```

当使用代码埋点时，调用方法如下：

```
- (void)track:(NSString *)eventID eventName:(NSString *)eventName properties:(NSDictionary *)properties;
```

