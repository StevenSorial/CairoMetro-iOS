deploymentTarget = '11.0'

platform :ios, deploymentTarget
use_frameworks!
inhibit_all_warnings!

target 'CairoMetro' do
  pod 'SwiftLint'
  pod 'Alamofire'
  pod 'SwiftyBeaver'
  pod 'SwiftyUserDefaults'
  pod 'DifferenceKit'
  pod 'Fuse', :git => 'https://github.com/StevenMagdy/fuse-swift.git', :branch => 'fix-naming'
  pod 'R.swift'
  pod 'Firebase/Crashlytics'
  pod 'Google-Mobile-Ads-SDK'
  pod 'Firebase/Analytics'
  pod 'RxSwift'
  pod 'GRDB.swift'
  pod 'RxGRDB'
  pod 'AlamofireNetworkActivityIndicator'
  pod 'RxCoreLocation'
  pod 'FLEX', :configurations => ['Debug']
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings.delete 'IPHONEOS_DEPLOYMENT_TARGET'
    end
  end
end