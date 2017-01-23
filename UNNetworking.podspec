Pod::Spec.new do |s|
  s.name      = "UNNetworking"
  s.version   = "0.7.2"
  s.summary   = "Networking utilities"
  s.authors   = { "Upnext Ltd." => "http://www.up-next.com", "Marcin Krzyzanowski" => "marcink@up-next.com" }
  s.homepage  = "http://www.up-next.com"
  s.source    = { :git => "https://github.com/upnext/UNNetworking.git", :tag => "v#{s.version}" }
  s.license   = 'LICENSE*.*'
  s.platform          = :ios, '5.0'
  
  s.source_files = "UNNetworking/**/*.{h,m}"

  s.frameworks = 'Foundation', 'CoreFoundation', 'SystemConfiguration', 'MobileCoreServices'

  s.requires_arc = true
end