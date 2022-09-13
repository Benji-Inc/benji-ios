# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

def shared_pods
  pod 'ParseLiveQuery'
  pod 'ScrollCounter'
end

def ios_pods
  pod 'Lightbox'
end

target 'Jibber' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
  ios_pods
end

target 'AppClip' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
end

target 'Notification Content' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
end

target 'Notification Service' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
end

target 'Intents Extension' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
end

target 'Intents ExtensionUI' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '11.0'
    end
  end
end
