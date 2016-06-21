#
# Be sure to run `pod lib lint KSNNetworkClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "KSNNetworkClient"
  s.version          = "1.3"
  s.summary          = "SergeyKovalenko."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = "Simple API Client infrastructure"

  s.homepage         = "https://bitbucket.org/atomicip/ksnnetworkclient"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Sergey Kovalenko" => "papuly@gmail.com" }
  s.source           = { :git => "https://bitbucket.org/atomicip/ksnnetworkclient.git", :branch => "master" }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
#  s.resource_bundles = {
#    'KSNNetworkClient' => ['Pod/Assets/*.png']
#  }

   s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
   s.dependency 'AFNetworking', '~> 3.0'
   s.dependency 'ReactiveCocoa', '~> 2.5'
end
