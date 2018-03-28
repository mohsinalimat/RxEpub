#
# Be sure to run `pod lib lint RxEpub.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'RxEpub'
  s.version          = '0.0.1'
  s.summary          = 'A short description of RxEpub.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/izhoubin/RxEpub'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'izhoubin' => '121160492@qq.com' }
  s.source           = { :git => 'https://github.com/izhoubin/RxEpub.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  # s.ios.deployment_target = '9.0'
  #
  # s.source_files = 'RxEpub/Classes/**/*'

  s.swift_version = '4.0'
  s.ios.deployment_target = '9.0'
  # s.requires_arc  = true

  s.source_files = [
    'RxEpub/Source/*.{h,swift}',
    'RxEpub/Source/**/*.swift',
  ]

  # s.public_header_files = 'Pod/Source/**/*.h'

  # s.subspec 'RxEpubPaser' do |rxEpubPaser|
  #     rxEpubPaser.source_files = 'RxEpub/Source/RxEpubPaser/**/*'
      # rxEpubPaser.public_header_files = 'RxEpub/Source/RxEpubPaser/**/*.h'
      # rxEpubPaser.dependency 'Alamofire'
  # end

  # s.subspec 'RxEpubReader' do |rxEpubReader|
      # rxEpubReader.source_files = 'RxEpub/Source/RxEpubReader/**/*'
      # rxEpubReader.public_header_files = 'RxEpub/Source/RxEpubReader/**/*.h'
  # end

  s.libraries  = "z"
  s.dependency 'SSZipArchive', '2.1.1'
  s.dependency 'Alamofire'
  s.dependency 'RxSwift'
  s.dependency 'RxCocoa'
  # s.dependency 'MenuItemKit', '3.0.0'
  # s.dependency 'ZFDragableModalTransition', '0.6'
  s.dependency 'AEXML', '4.2.2'
  # s.dependency 'FontBlaster', '4.0.1'
  # s.dependency 'JSQWebViewController', '6.0.0'
  # s.dependency 'RealmSwift', '3.1.1'
  s.frameworks = 'UIKit'
end
