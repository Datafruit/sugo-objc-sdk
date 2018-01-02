
Pod::Spec.new do |s|
  s.name                  = 'sugo-objc-sdk'
  s.version               = '2.19.1'
  s.license               = 'Apache License, Version 2.0'
  s.summary               = 'Official Sugo SDK for iOS (Objective-C)'
  s.homepage              = 'https://github.com/Datafruit/sugo-objc-sdk'
  s.author                = { 'sugo.io' => 'developer@sugo.io' }
  s.source                = { :git => 'https://github.com/Datafruit/sugo-objc-sdk.git', :tag => s.version }
  s.ios.deployment_target = '8.0'
  s.module_name           = 'Sugo'
  s.default_subspec       = 'Core'

  spec.subspec 'Core' do |core|
    core.source_files           = 'Sugo/*.{m,h}'
    core.resources              = 'Sugo/*.js', 'Sugo/Sugo*.plist'
    core.private_header_files   = 'Sugo/SugoPrivate.h', 'Sugo/SugoPeoplePrivate.h', 'Sugo/MPNetworkPrivate.h', 'Sugo/MPLogger.h'
    core.libraries              = 'icucore'
    core.frameworks             = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'Accelerate', 'CoreGraphics', 'QuartzCore', 'WebKit'
  end

  spec.subspec 'Weex' do |weex|
    weex.source_files   = 'Sugo/Weex/*.{m,h}'
    weex.dependency 'WeexSDK'
  end
end
