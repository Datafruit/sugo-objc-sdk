
Pod::Spec.new do |s|
  s.name                  = 'sugo-objc-sdk'
  s.version               = '2.18.0'
  s.license               = 'Apache License, Version 2.0'
  s.summary               = 'Official Sugo SDK for iOS (Objective-C)'
  s.homepage              = 'https://github.com/Datafruit/sugo-objc-sdk'
  s.author                = { 'sugo.io' => 'developer@sugo.io' }
  s.source                = { :git => 'https://github.com/Datafruit/sugo-objc-sdk.git', :tag => s.version }
  s.ios.deployment_target = '8.0'
  s.ios.source_files      = 'Sugo/*.{m,h}'
  s.ios.resources         = 'Sugo/*.js', 'Sugo/Sugo*.plist'
  s.private_header_files  = 'Sugo/SugoPrivate.h', 'Sugo/SugoPeoplePrivate.h', 'Sugo/MPNetworkPrivate.h', 'Sugo/MPLogger.h'
  s.frameworks            = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'Accelerate', 'CoreGraphics', 'QuartzCore', 'WebKit'
  s.libraries             = 'icucore'
  s.module_name           = 'Sugo'
end
