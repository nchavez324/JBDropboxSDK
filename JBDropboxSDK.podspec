#
# Be sure to run `pod lib lint JBDropboxSDK.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "JBDropboxSDK"
  s.version          = "0.2.0"
  s.summary          = "JBDropboxSDK provides a limited SDK to the Dropbox Core API"
  s.description      = <<-DESC
  		       
		       Put a dscription here hurdur!
		       Idc, idc, idc
		       	  hur dur hur dur hur dur
			  derp derp derp derp derp derp
                       
                       DESC
  s.homepage         = "https://bitbucket.org/nchavez/jbdropboxsdk"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "Nick Chavez" => "nchavez324@yahoo.com" }
  s.source           = { :git => "https://nchavez@bitbucket.org/nchavez/jbdropboxsdk.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'JBDropboxSDK' => ['Pod/Assets/*.png', 'Pod/Classes/Model/*.momd', 'Pod/Assets/*.xib']
  }
  s.preserve_paths = 'Pod/Classes/Model/*', 'Pod/Classes/Model/*.momd', 'Pod/Classes/Model/*.momd/*'

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'AFNetworking', '~> 2.3'
end
