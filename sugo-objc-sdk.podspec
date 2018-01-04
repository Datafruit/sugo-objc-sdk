
Pod::Spec.new do |spec|
  spec.name                  = 'sugo-objc-sdk'
  spec.module_name           = 'Sugo'
  spec.version               = '2.19.1'
  spec.license               = 'Apache License, Version 2.0'
  spec.summary               = 'Official Sugo SDK for iOS (Objective-C)'
  spec.homepage              = 'https://github.com/Datafruit/sugo-objc-sdk'
  spec.author                = { 'sugo.io' => 'developer@sugo.io' }
  spec.source                = { :git => 'https://github.com/Datafruit/sugo-objc-sdk.git', :tag => spec.version }
  spec.ios.deployment_target = '8.0'
  spec.default_subspec       = 'core'

  spec.subspec 'core' do |core|
    core.source_files           = 'Sugo/*.{m,h}'
    core.resources              = 'Sugo/*.js', 'Sugo/Sugo*.plist'
    core.private_header_files   = 'Sugo/SugoPrivate.h', 'Sugo/SugoPeoplePrivate.h', 'Sugo/MPNetworkPrivate.h', 'Sugo/MPLogger.h'
    core.libraries              = 'icucore'
    core.frameworks             = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'Accelerate', 'CoreGraphics', 'QuartzCore', 'WebKit'
  end

  spec.subspec 'weex' do |weex|
    weex.source_files   = 'Sugo/Weex/*.{m,h}'
    weex.dependency 'sugo-objc-sdk/core'
    weex.dependency 'WeexSDK'
  end
end
