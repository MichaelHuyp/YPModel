#
# Be sure to run `pod lib lint YPModel.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'YPModel'
  s.version          = '0.1.0'
  s.summary          = '一款平平淡淡的字典转模型框架'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
一款平平淡淡的字典转模型框架,以后慢慢提高性能 参考YYModel
                       DESC

  s.homepage         = 'https://github.com/MichaelHuyp/YPModel'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'MichaelHuyp' => '86812684@qq.com' }
  s.source           = { :git => 'https://github.com/MichaelHuyp/YPModel.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'YPModel/Classes/**/*'
  
  # s.resource_bundles = {
  #   'YPModel' => ['YPModel/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
