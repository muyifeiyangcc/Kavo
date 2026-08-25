platform :ios, '17.0'

target 'Kavo' do
  use_frameworks!

  pod 'SnapKit', '5.7.1'
  pod 'IQKeyboardManagerSwift', '8.0.0'
  pod 'Adjust', '~> 5.7', :modular_headers => true
  pod 'FBSDKCoreKit'
  pod 'ScreenShield', '~> 1.2.2'

  target 'KavoTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES' if config.name == 'Debug'
    end
  end
end
