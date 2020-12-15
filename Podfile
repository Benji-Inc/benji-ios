# Uncomment the next line to define a global platform for your project
platform :ios, '14.0'

def shared_pods
  pod 'Parse'
  pod 'GestureRecognizerClosures'
  pod 'ReactiveSwift'
  pod 'PhoneNumberKit'
  pod 'lottie-ios'

  pod 'TMROFutures'
  pod 'TMROCoordinator'
  pod 'TMROLocalization'

  pod 'Branch'
  pod 'SDWebImage'
end

target 'Benji' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
  pod 'TwilioChatClient'
end

target 'BenjiAppClip' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!
  shared_pods
end
