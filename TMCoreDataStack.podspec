#
# Be sure to run `pod lib lint TMCoreDataStack.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "TMCoreDataStack"
  s.version          = "0.1.0"
  s.summary          = "A short description of TMCoreDataStack."
  s.description      = <<-DESC
                       An optional longer description of TMCoreDataStack

                       * Markdown format.
                       * Don't worry about the indent, we strip it!
                       DESC
  s.homepage         = "https://github.com/tonymillion/TMCoreDataStack"
  s.license          = 'MIT'
  s.author           = { "Tony Million" => "tonymillion@gmail.com" }
  s.source           = { :git => "https://github.com/tonymillion/TMCoreDataStack.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/tonymillion'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'TMCoreDataStack' => ['Pod/Assets/*.png']
  }

  s.frameworks = 'CoreData'
end
