#
# Be sure to run `pod lib lint KSNErrorHandler.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "KSNErrorHandler"
  s.version          = "1.1"
  s.summary          = "Simple Error handler"

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = "KSNErrorHandler is a dispatcher for NSErrors. Please see Tests for more details."

  s.homepage         = "https://bitbucket.org/atomicip/ksnerrorhandler"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Sergey Kovalenko" => "papuly@gmail.com" }
  s.source           = { :git => "https://bitbucket.org/atomicip/ksnerrorhandler.git", :branch => "master"}
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
# s.resource_bundles = {
#    'KSNErrorHandler' => ['Pod/Assets/*.png']
#  }

  s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
