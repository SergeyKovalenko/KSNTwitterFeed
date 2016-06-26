    #
    # Be sure to run `pod lib lint KSNTwitterFeed.podspec' to ensure this is a
    # valid spec before submitting.
    #
    # Any lines starting with a # are optional, but their use is encouraged
    # To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
    #

    Pod::Spec.new do |s|
    s.name             = 'KSNTwitterFeed'
    s.version          = '0.1.0'
    s.summary          = 'Twitter client with offline mode.'

    s.description      = <<-DESC
    Features list:
    As a user I can login to Twitter
    As a user I see my twitter name in the navigation bar
    As a user I can view my Twitter feed (fail plan: display error)
    As a user I can refresh my feed using pull-to-refresh (fail plan: display error)
    As a user I can view my Twitter feed without internet connection
    As a user I expect that feed will be automatically updated when network connection is available
    As a user I can tap on system compose button on the right of navigation bar and get to post new tweet screen
    As a user I can post new tweet (fail plan: display error)
    DESC

    s.homepage         = 'https://github.com/SergeyKovalenko/KSNTwitterFeed'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Sergey Kovalenko' => 'papuly@gmail.com' }
    s.source           = { :git => 'https://github.com/SergeyKovalenko/KSNTwitterFeed.git', :branch => 'master' }

    s.ios.deployment_target = '8.0'
    s.source_files = 'KSNTwitterFeed/Classes/**/*.{m,h}'
    s.resource_bundles = {
      'KSNTwitterFeedBundle' => ['KSNTwitterFeed/Assets/*.*']
    }
    # s.public_header_files = 'Pod/Classes/**/*.h'
    s.frameworks = 'UIKit', 'Foundation'

    # Private pods
    s.dependency 'KSNUtils'

    # Public pods
    s.dependency 'AFNetworking', '~> 3.0'
    s.dependency 'ReactiveCocoa', '2.5'
    s.dependency 'FastEasyMapping'

end
