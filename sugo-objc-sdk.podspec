
Pod::Spec.new do |spec|
  spec.name                  = 'sugo-objc-sdk'
  spec.module_name           = 'Sugo'
  spec.version               = '3.5.10.1'
  spec.license               = 'Apache License, Version 2.0'
  spec.summary               = 'Official Sugo SDK for iOS (Objective-C)'
  spec.homepage              = 'https://github.com/Datafruit/sugo-objc-sdk'
  spec.author                = { 'sugo.io' => 'developer@sugo.io' }
  spec.source                = { :git => 'https://github.com/Datafruit/sugo-objc-sdk.git', :tag => spec.version ,:branch => 'infinitus'}
  spec.ios.deployment_target = '8.0'
  spec.default_subspec       = 'core'

  spec.subspec 'core' do |core|
    core.source_files           = 'Sugo/Core/Sources/**/*.{m,h}'
    core.resources              = 'Sugo/Core/Resources/**/*.js', 'Sugo/Core/Resources/**/Sugo*.plist', 'Sugo/Core/Resources/**/*.xcdatamodeld'
    core.private_header_files   = 'Sugo/Core/Sources/Track/SugoPrivate.h', 'Sugo/Core/Sources/Track/People/SugoPeoplePrivate.h', 'Sugo/Core/Sources/Network/MPNetworkPrivate.h', 'Sugo/Core/Sources/MPLogger.h', 'Sugo/Core/Sources/Track/CoreData/SugoEvents+CoreDataProperties.h', 'Sugo/Core/Sources/Track/CoreData/SugoEvents+CoreDataClass.h'
    core.libraries              = 'icucore'
    core.frameworks             = 'UIKit', 'Foundation', 'SystemConfiguration', 'CoreTelephony', 'Accelerate', 'CoreGraphics', 'QuartzCore', 'WebKit', 'CoreData', 'CoreLocation'
  end

    spec.subspec 'weex' do |weex|
      weex.source_files   = 'Sugo/Weex/*.{m,h}'
      weex.dependency 'sugo-objc-sdk/core'
      weex.dependency 'WeexSDK'
    end

    spec.subspec 'heatmap' do |heatmap|
      heatmap.source_files   = 'Sugo/HeatMap/*.{m,h}'
      heatmap.dependency 'sugo-objc-sdk/core'
    end

end
