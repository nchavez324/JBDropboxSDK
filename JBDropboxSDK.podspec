Pod::Spec.new do |s|
  s.name             = "JBDropboxSDK"
  s.version          = "0.2.0"
  s.summary          = "JBDropboxSDK provides a limited SDK to the Dropbox Core API"
  s.homepage         = "https://github.com/nchavez324/JBDropboxSDK"
  s.license          = 'MIT'
  s.author           = { "Nick Chavez" => "chavez.a.nicolas@gmail.com" }
  s.source           = { :git => "https://github.com/nchavez324/JBDropboxSDK.git", :tag => s.version.to_s }
  
  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resource_bundles = {
    'JBDropboxSDK' => ['Pod/Assets/*.png', 'Pod/Classes/Model/*.momd', 'Pod/Assets/*.xib']
  }
  s.preserve_paths = 'Pod/Classes/Model/*', 'Pod/Classes/Model/*.momd', 'Pod/Classes/Model/*.momd/*'

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.dependency 'AFNetworking', '~> 2.7'
end
